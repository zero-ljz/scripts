#!/usr/bin/env python3

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from email.parser import BytesParser
from email.policy import default as email_policy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import argparse
import base64
import binascii
import codecs
import datetime
import hmac
import html
import json
import locale
import logging
import os
import shlex
import signal
import subprocess
import sys
import threading
import time
import uuid
from urllib.parse import parse_qs, quote, unquote, urlsplit


APP_NAME = os.path.splitext(os.path.basename(sys.argv[0]))[0]
APP_VERSION = "1.0.0"
SYNC_IMPLEMENTATION = "TaskManager"
USER_HOME_DIRECTORY = os.path.expanduser("~")

logging.basicConfig(
    filename=APP_NAME + ".log",
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

AUTH_USERNAME = os.environ.get("AUTH_USERNAME", "")
AUTH_PASSWORD = os.environ.get("AUTH_PASSWORD", "123123")
REQUIRE_AUTH = os.environ.get("REQUIRE_AUTH", "false").lower() in {
    "1", "true", "on", "yes"
}

# 旧同步模式超时，默认保持原来的 30 分钟。
COMMAND_TIMEOUT = int(os.environ.get("COMMAND_TIMEOUT", "1800"))

# 后台任务默认不超时。可以通过环境变量 TASK_TIMEOUT 设置默认秒数，
# 也可以在 API 请求或 URL 中通过 timeout 单独指定。
TASK_TIMEOUT = int(os.environ.get("TASK_TIMEOUT", "0"))
TASK_OUTPUT_LIMIT = int(os.environ.get("TASK_OUTPUT_LIMIT", str(4 * 1024 * 1024)))
TASK_RETENTION_SECONDS = int(os.environ.get("TASK_RETENTION_SECONDS", "3600"))
MAX_TASK_HISTORY = int(os.environ.get("MAX_TASK_HISTORY", "100"))
TASK_TERMINATE_GRACE = float(os.environ.get("TASK_TERMINATE_GRACE", "3"))
COMMAND_ENCODING = (
    os.environ.get("COMMAND_ENCODING", "").strip()
    or locale.getpreferredencoding(False)
    or "utf-8"
)


INDEX_HTML = r'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Web Shell</title>
<style>
body { margin: 8px; }
main { display: flex; flex-wrap: wrap; gap: 8px; align-items: flex-start; }
section { min-width: 300px; }
fieldset { margin: 0 0 6px; }
table { border-collapse: collapse; }
td { padding: 2px 4px 2px 0; vertical-align: middle; }
.args td:first-child { text-align: right; }
</style>
</head>
<body>
<h3>Web Shell <small>v1.0.0</small></h3>
<p><a href="/tasks">任务列表</a></p>

<main>
  <section>
    <fieldset>
      <legend>环境</legend>
      <table>
        <tr>
          <td><label for="cwd">工作目录</label></td>
          <td><input id="cwd" type="text" placeholder="默认用户目录"></td>
        </tr>
        <tr>
          <td colspan="2">
            <label><input id="shell" type="checkbox"> Shell Mode</label>
            <label><input id="capture" type="checkbox" checked> Capture Output</label>
            <label><input id="encode" type="checkbox"> URI Component Encoding</label>
          </td>
        </tr>
      </table>
    </fieldset>

    <fieldset>
      <legend>命令</legend>
      <table>
        <tr>
          <td><label for="command">主命令</label></td>
          <td>
            <input id="command" type="text" list="commands" placeholder="例如 python3、node、ls" autocomplete="off">
            <button id="clearCommand" type="button">清空</button>
          </td>
        </tr>
        <tr>
          <td>参数</td>
          <td>
            <button id="addArg" type="button">添加参数</button>
            <button id="removeArg" type="button">移除末项</button>
          </td>
        </tr>
      </table>

      <datalist id="commands">
        <option value="python">
        <option value="python3">
        <option value="node">
        <option value="curl">
        <option value="whoami">
        <option value="ls">
        <option value="cat">
        <option value="ping">
      </datalist>

      <table id="args" class="args"></table>
    </fieldset>
  </section>

  <section>
    <fieldset>
      <legend>执行</legend>
      <table>
        <tr>
          <td><label for="runMode">执行模式</label></td>
          <td>
            <select id="runMode">
              <option value="sync">同步执行</option>
              <option value="task">后台任务</option>
              <option value="interactive">交互任务（管道模式）</option>
            </select>
          </td>
        </tr>
        <tr>
          <td><label for="mode">URL 模式</label></td>
          <td>
            <select id="mode">
              <option value="1">Query (?cmd=...)</option>
              <option value="2">Path (/cmd/...)</option>
            </select>
          </td>
        </tr>
        <tr>
          <td><label for="preview">URL 预览</label></td>
          <td><textarea id="preview" rows="8" cols="60" readonly></textarea></td>
        </tr>
        <tr>
          <td></td>
          <td>
            <button id="copy" type="button">复制</button>
            <button id="run" type="button">执行</button>
            <button id="reset" type="button">重置</button>
            <span id="status"></span>
          </td>
        </tr>
      </table>
      <div id="modeNote"></div>
    </fieldset>
  </section>
</main>

<script>
'use strict';

const $ = id => document.getElementById(id);
const BASE_URL_PATH = `${location.protocol}//${location.host}/`;
const storageKey = 'webShellState';
let args = [];

function readState() {
  return {
    cwd: $('cwd').value,
    command: $('command').value,
    args: [...args],
    useShell: $('shell').checked,
    captureOutput: $('capture').checked,
    encoding: $('encode').checked,
    urlMode: Number($('mode').value) || 1,
    runMode: $('runMode').value || 'sync'
  };
}

function writeState(state = {}) {
  $('cwd').value = state.cwd || '';
  $('command').value = state.command || '';
  $('shell').checked = Boolean(state.useShell);
  $('capture').checked = state.captureOutput !== false;
  $('encode').checked = Boolean(state.encoding);
  $('mode').value = String(state.urlMode || 1);
  $('runMode').value = state.runMode || 'sync';
  args = Array.isArray(state.args) ? state.args : [];
  renderArgs();
  updatePreview();
}

function saveState() {
  sessionStorage.setItem(storageKey, JSON.stringify(readState()));
}

function loadState() {
  try {
    return JSON.parse(sessionStorage.getItem(storageKey) || '{}');
  } catch {
    return {};
  }
}

function showStatus(text) {
  $('status').textContent = text;
  setTimeout(() => {
    if ($('status').textContent === text) $('status').textContent = '';
  }, 1500);
}

function renderArgs() {
  const container = $('args');
  container.replaceChildren();

  args.forEach((value, index) => {
    const row = document.createElement('tr');
    const numberCell = document.createElement('td');
    const inputCell = document.createElement('td');
    const input = document.createElement('input');
    const remove = document.createElement('button');

    numberCell.textContent = `${index + 1}.`;
    input.type = 'text';
    input.value = value;
    input.placeholder = `参数 ${index + 1}`;
    remove.type = 'button';
    remove.textContent = '删除';

    input.addEventListener('input', () => {
      args[index] = input.value;
      updatePreview();
    });

    input.addEventListener('keydown', event => {
      if (event.key === 'Enter') event.preventDefault();
    });

    remove.addEventListener('click', () => {
      args.splice(index, 1);
      renderArgs();
      updatePreview();
    });

    inputCell.append(input, document.createTextNode(' '), remove);
    row.append(numberCell, inputCell);
    container.append(row);
  });
}

function genURL(method, isEncode) {
  const state = readState();
  const cwd = state.cwd;
  const shell = state.useShell ? 'on' : 'off';
  const captureOutput = state.captureOutput ? 'on' : 'off';
  const runMode = state.runMode;

  const optionStr =
    (cwd ? '&cwd=' + (isEncode ? encodeURIComponent(cwd) : cwd) : '') +
    (shell === 'on' ? '&shell=' + shell : '') +
    (captureOutput === 'on' ? '&capture_output=' + captureOutput : '') +
    (runMode !== 'sync' ? '&run_mode=' + runMode : '');

  let param0Str = state.command || '';
  let paramStr = '';

  if (method === 1) {
    args.forEach((value, index) => {
      if (index === args.length - 1 && !value) return;

      const paramValue = value.replace(/&/g, '%26');
      paramStr += paramValue.includes(' ')
        ? ' "' + paramValue + '"'
        : ' ' + paramValue;
    });

    param0Str = param0Str.replace(/&/g, '%26');

    const hasArgs = args.length > 1 || (args.length === 1 && args[0]);
    if (param0Str.includes(' ') && hasArgs) {
      param0Str = '"' + param0Str + '"';
    }

    const fullCommand = param0Str + paramStr;
    return BASE_URL_PATH + '?cmd=' +
      (isEncode ? encodeURIComponent(fullCommand) : fullCommand) +
      optionStr;
  }

  args.forEach((value, index) => {
    if (index === args.length - 1 && !value) return;

    if (value.includes('/') || value.includes('\\')) {
      paramStr += '/"' + (isEncode ? encodeURIComponent(value) : value) + '"';
    } else {
      paramStr += '/' + (isEncode ? encodeURIComponent(value) : value);
    }
  });

  const hasArgs = args.length > 1 || (args.length === 1 && args[0]);
  if ((param0Str.includes('/') || param0Str.includes('\\')) && hasArgs) {
    param0Str = '"' + param0Str + '"';
  }

  return BASE_URL_PATH +
    (isEncode ? encodeURIComponent(param0Str) : param0Str) +
    paramStr + '?' + optionStr;
}

function updatePreview() {
  const state = readState();
  const isSync = state.runMode === 'sync';

  $('capture').disabled = !isSync;
  if (!isSync) $('capture').checked = true;

  if (state.runMode === 'interactive') {
    $('modeNote').textContent = '交互任务支持向 stdin 发送文本，但不是 PTY/ConPTY，vim、top、完整 Shell 等程序可能无法正常工作。';
  } else if (state.runMode === 'task') {
    $('modeNote').textContent = '后台任务会立即返回任务页面，输出可持续查看，刷新页面不会重复启动任务。';
  } else {
    $('modeNote').textContent = '同步执行会等待任务完成后，在当前页面一次性返回完整输出。';
  }

  $('preview').value = genURL(state.urlMode, state.encoding);
}

['cwd', 'command', 'shell', 'capture', 'encode', 'mode', 'runMode'].forEach(id => {
  $(id).addEventListener('input', updatePreview);
  $(id).addEventListener('change', updatePreview);
});

$('clearCommand').addEventListener('click', () => {
  $('command').value = '';
  $('command').focus();
  updatePreview();
});

$('addArg').addEventListener('click', () => {
  args.push('');
  renderArgs();
  updatePreview();
  $('args').lastElementChild?.querySelector('input')?.focus();
});

$('removeArg').addEventListener('click', () => {
  if (args.length > 0) {
    args.pop();
    renderArgs();
    updatePreview();
  }
});

$('copy').addEventListener('click', async () => {
  const text = $('preview').value;

  try {
    await navigator.clipboard.writeText(text);
  } catch {
    $('preview').select();
    document.execCommand('copy');
  }

  showStatus('已复制');
});

$('run').addEventListener('click', () => {
  saveState();
  location.href = $('preview').value;
});

$('reset').addEventListener('click', () => {
  sessionStorage.removeItem(storageKey);
  $('cwd').value = '';
  $('command').value = '';
  $('shell').checked = false;
  $('capture').checked = true;
  $('encode').checked = false;
  $('mode').value = '1';
  $('runMode').value = 'sync';
  args = [];
  renderArgs();
  updatePreview();
  showStatus('已重置');
});

addEventListener('pagehide', saveState);
writeState(loadState());
</script>
</body>
</html>
'''


TASK_PAGE_HTML = r'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>任务控制台</title>
<style>
body { margin: 8px; }
pre { white-space: pre-wrap; overflow-wrap: anywhere; min-height: 240px; max-height: 65vh; overflow: auto; }
textarea { width: min(900px, 95vw); }
</style>
</head>
<body>
<h3>任务控制台</h3>
<p><a href="/">返回首页</a> | <a href="/tasks">任务列表</a></p>
<table>
<tr><td>任务 ID</td><td><code id="taskId"></code></td></tr>
<tr><td>状态</td><td id="taskStatus">正在连接</td></tr>
<tr><td>PID</td><td id="taskPid"></td></tr>
<tr><td>退出码</td><td id="taskReturncode"></td></tr>
<tr><td>命令</td><td><code id="taskCommand"></code></td></tr>
<tr><td>工作目录</td><td><code id="taskCwd"></code></td></tr>
</table>

<fieldset>
<legend>输出</legend>
<pre id="output"></pre>
<button id="clearOutput" type="button">清空页面输出</button>
<label><input id="autoScroll" type="checkbox" checked> 自动滚动</label>
</fieldset>

<fieldset id="inputBox">
<legend>标准输入（管道交互）</legend>
<textarea id="input" rows="4" placeholder="输入发送给进程 stdin 的内容"></textarea><br>
<label><input id="appendNewline" type="checkbox" checked> 末尾添加换行</label>
<button id="sendInput" type="button">发送</button>
<span id="inputStatus"></span>
</fieldset>

<p>
<button id="interrupt" type="button">中断 Ctrl+C</button>
<button id="terminate" type="button">终止任务</button>
<button id="refresh" type="button">刷新状态</button>
</p>

<script>
'use strict';
const TASK_ID = __TASK_ID_JSON__;
const INTERACTIVE = __INTERACTIVE_JSON__;
const $ = id => document.getElementById(id);
let nextSequence = 0;
let stopped = false;

$('taskId').textContent = TASK_ID;
$('inputBox').hidden = !INTERACTIVE;

function setInputStatus(text) {
  $('inputStatus').textContent = text;
  setTimeout(() => {
    if ($('inputStatus').textContent === text) $('inputStatus').textContent = '';
  }, 1500);
}

function appendOutput(text, truncated) {
  const output = $('output');
  if (truncated) output.textContent += '\n[较早的输出已从服务器缓冲区清理]\n';
  if (text) output.textContent += text;

  const maxLength = 4 * 1024 * 1024;
  if (output.textContent.length > maxLength) {
    output.textContent = '[页面中过早的输出已清理]\n' + output.textContent.slice(-maxLength);
  }

  if ($('autoScroll').checked) output.scrollTop = output.scrollHeight;
}

function renderTask(data) {
  $('taskStatus').textContent = data.status;
  $('taskPid').textContent = data.pid ?? '';
  $('taskReturncode').textContent = data.returncode ?? '';
  $('taskCommand').textContent = data.command_display || '';
  $('taskCwd').textContent = data.cwd || '';

  const writable = data.status === 'running' || data.status === 'stopping';
  $('sendInput').disabled = !writable;
  $('interrupt').disabled = !writable;
  $('terminate').disabled = !writable;
}

async function readJson(response) {
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`);
  return data;
}

async function refreshStatus() {
  const response = await fetch(`/api/tasks/${encodeURIComponent(TASK_ID)}`, {cache: 'no-store'});
  const data = await readJson(response);
  renderTask(data);
  return data;
}

async function pollOutput() {
  while (!stopped) {
    try {
      const url = `/api/tasks/${encodeURIComponent(TASK_ID)}/output?after=${nextSequence}&wait=20`;
      const response = await fetch(url, {cache: 'no-store'});
      const data = await readJson(response);
      appendOutput(data.output || '', Boolean(data.truncated));
      nextSequence = data.next;
      renderTask(data);

      if (data.output_closed && data.status !== 'running' && data.status !== 'stopping') {
        stopped = true;
        break;
      }
    } catch (error) {
      $('taskStatus').textContent = `连接失败：${error.message}`;
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
}

async function postAction(action, body = {}) {
  const response = await fetch(`/api/tasks/${encodeURIComponent(TASK_ID)}/${action}`, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(body)
  });
  return readJson(response);
}

$('sendInput').addEventListener('click', async () => {
  let data = $('input').value;
  if ($('appendNewline').checked) data += '\n';

  try {
    await postAction('input', {data});
    $('input').value = '';
    $('input').focus();
    setInputStatus('已发送');
  } catch (error) {
    setInputStatus(error.message);
  }
});

$('input').addEventListener('keydown', event => {
  if (event.ctrlKey && event.key === 'Enter') {
    event.preventDefault();
    $('sendInput').click();
  }
});

$('interrupt').addEventListener('click', async () => {
  try {
    const data = await postAction('interrupt');
    renderTask(data);
  } catch (error) {
    alert(error.message);
  }
});

$('terminate').addEventListener('click', async () => {
  try {
    const data = await postAction('terminate');
    renderTask(data);
  } catch (error) {
    alert(error.message);
  }
});

$('refresh').addEventListener('click', () => {
  refreshStatus().catch(error => alert(error.message));
});

$('clearOutput').addEventListener('click', () => {
  $('output').textContent = '';
});

refreshStatus().catch(error => {
  $('taskStatus').textContent = error.message;
});
pollOutput();
</script>
</body>
</html>
'''


@dataclass
class CommandTask:
    task_id: str
    process: subprocess.Popen[bytes]
    command_display: str
    cwd: str
    shell: bool
    interactive: bool
    encoding: str
    timeout: int
    output_limit: int | None
    mirror_output: bool = False
    created_at: float = field(default_factory=time.time)
    finished_at: float | None = None
    returncode: int | None = None
    status: str = "running"
    output_closed: bool = False
    termination_requested: bool = False
    timed_out: bool = False
    next_sequence: int = 1
    output_size: int = 0
    output: deque[tuple[int, str, int]] = field(default_factory=deque)
    lock: threading.RLock = field(default_factory=threading.RLock)
    output_changed: threading.Condition = field(init=False)

    def __post_init__(self) -> None:
        self.output_changed = threading.Condition(self.lock)

    @property
    def pid(self) -> int:
        return self.process.pid

    def append_output(self, text: str) -> None:
        if not text:
            return

        if self.mirror_output:
            try:
                sys.stdout.write(text)
                sys.stdout.flush()
            except (OSError, UnicodeError):
                pass

        text_size = len(text.encode("utf-8", errors="replace"))

        with self.output_changed:
            sequence = self.next_sequence
            self.next_sequence += 1
            self.output.append((sequence, text, text_size))
            self.output_size += text_size

            if self.output_limit is not None:
                while self.output and self.output_size > self.output_limit:
                    _, _, removed_size = self.output.popleft()
                    self.output_size -= removed_size

            self.output_changed.notify_all()

    def mark_output_closed(self) -> None:
        with self.output_changed:
            self.output_closed = True
            self.output_changed.notify_all()

    def snapshot(self) -> dict[str, object]:
        with self.lock:
            return {
                "task_id": self.task_id,
                "pid": self.pid,
                "status": self.status,
                "returncode": self.returncode,
                "command_display": self.command_display,
                "cwd": self.cwd,
                "shell": self.shell,
                "interactive": self.interactive,
                "encoding": self.encoding,
                "timeout": self.timeout,
                "output_limit": self.output_limit,
                "created_at": self.created_at,
                "finished_at": self.finished_at,
                "output_closed": self.output_closed,
                "termination_requested": self.termination_requested,
                "timed_out": self.timed_out,
            }

    def read_output(self, after: int, wait_seconds: float) -> dict[str, object]:
        wait_seconds = max(0.0, min(wait_seconds, 30.0))
        deadline = time.monotonic() + wait_seconds

        with self.output_changed:
            while True:
                has_new_output = self.next_sequence - 1 > after
                task_finished = self.output_closed and self.status not in {
                    "running", "stopping"
                }

                if has_new_output or task_finished or wait_seconds <= 0:
                    break

                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break

                self.output_changed.wait(remaining)

            oldest_sequence = self.output[0][0] if self.output else self.next_sequence
            truncated = after < oldest_sequence - 1
            chunks = [text for sequence, text, _ in self.output if sequence > after]
            next_value = self.output[-1][0] if self.output else self.next_sequence - 1
            snapshot = self.snapshot()

        snapshot.update(
            {
                "output": "".join(chunks),
                "next": next_value,
                "truncated": truncated,
            }
        )
        return snapshot

    def wait_finished(self, timeout: float | None = None) -> dict[str, object]:
        deadline = None if timeout is None else time.monotonic() + timeout

        with self.output_changed:
            while True:
                finished = (
                    self.status not in {"running", "stopping"}
                    and self.output_closed
                )
                if finished:
                    return self.snapshot()

                if deadline is None:
                    self.output_changed.wait()
                    continue

                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError("Task wait timed out")

                self.output_changed.wait(remaining)

    def get_buffered_output(self) -> str:
        with self.lock:
            return "".join(text for _, text, _ in self.output)


class TaskManager:
    def __init__(self) -> None:
        self._tasks: dict[str, CommandTask] = {}
        self._lock = threading.RLock()

    def start(
        self,
        process_command: str | list[str],
        command_display: str,
        cwd: str,
        shell: bool,
        interactive: bool,
        timeout: int = 0,
        encoding: str = COMMAND_ENCODING,
        output_limit: int | None = TASK_OUTPUT_LIMIT,
        mirror_output: bool = False,
    ) -> CommandTask:
        self.cleanup()
        task_id = uuid.uuid4().hex
        environment = os.environ.copy()
        environment.setdefault("PYTHONUNBUFFERED", "1")

        popen_options: dict[str, object] = {}
        if os.name == "nt":
            popen_options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
        else:
            popen_options["start_new_session"] = True

        process = subprocess.Popen(
            process_command,
            cwd=cwd,
            shell=shell,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=0,
            env=environment,
            **popen_options,
        )

        task = CommandTask(
            task_id=task_id,
            process=process,
            command_display=command_display,
            cwd=cwd,
            shell=shell,
            interactive=interactive,
            encoding=encoding,
            timeout=max(0, timeout),
            output_limit=(
                None if output_limit is None else max(0, output_limit)
            ),
            mirror_output=mirror_output,
        )

        with self._lock:
            self._tasks[task_id] = task

        threading.Thread(
            target=self._read_output,
            args=(task,),
            daemon=True,
            name=f"task-output-{task_id[:8]}",
        ).start()
        threading.Thread(
            target=self._wait_process,
            args=(task,),
            daemon=True,
            name=f"task-wait-{task_id[:8]}",
        ).start()

        logging.info(
            "Task started id=%s pid=%s cwd=%r shell=%s command=%r",
            task.task_id,
            task.pid,
            task.cwd,
            task.shell,
            task.command_display,
        )
        return task

    def get(self, task_id: str) -> CommandTask | None:
        with self._lock:
            return self._tasks.get(task_id)

    def list(self) -> list[CommandTask]:
        self.cleanup()
        with self._lock:
            return sorted(
                self._tasks.values(),
                key=lambda task: task.created_at,
                reverse=True,
            )

    def write_input(self, task_id: str, data: str) -> CommandTask:
        task = self.require(task_id)

        with task.lock:
            if task.process.poll() is not None:
                raise RuntimeError("Task already finished")
            if task.process.stdin is None:
                raise RuntimeError("Task stdin is unavailable")
            encoded = data.encode(task.encoding, errors="replace")
            task.process.stdin.write(encoded)
            task.process.stdin.flush()

        return task

    def interrupt(self, task_id: str) -> CommandTask:
        task = self.require(task_id)

        if task.process.poll() is not None:
            return task

        if os.name == "nt":
            try:
                task.process.send_signal(signal.CTRL_BREAK_EVENT)
            except (OSError, ValueError):
                task.process.send_signal(signal.SIGTERM)
        else:
            try:
                os.killpg(task.process.pid, signal.SIGINT)
            except ProcessLookupError:
                pass

        return task

    def terminate(self, task_id: str) -> CommandTask:
        task = self.require(task_id)

        with task.output_changed:
            if task.process.poll() is not None:
                return task
            task.termination_requested = True
            task.status = "stopping"
            task.output_changed.notify_all()

        self._send_terminate(task)
        threading.Thread(
            target=self._force_kill_later,
            args=(task,),
            daemon=True,
            name=f"task-kill-{task_id[:8]}",
        ).start()
        return task

    def require(self, task_id: str) -> CommandTask:
        task = self.get(task_id)
        if task is None:
            raise KeyError("Task not found")
        return task

    def cleanup(self) -> None:
        now = time.time()

        with self._lock:
            removable = [
                task_id
                for task_id, task in self._tasks.items()
                if task.finished_at is not None
                and now - task.finished_at > TASK_RETENTION_SECONDS
            ]

            for task_id in removable:
                self._tasks.pop(task_id, None)

            if len(self._tasks) <= MAX_TASK_HISTORY:
                return

            finished_tasks = sorted(
                (
                    task
                    for task in self._tasks.values()
                    if task.finished_at is not None
                ),
                key=lambda task: task.finished_at or 0,
            )

            while len(self._tasks) > MAX_TASK_HISTORY and finished_tasks:
                task = finished_tasks.pop(0)
                self._tasks.pop(task.task_id, None)

    @staticmethod
    def _read_output(task: CommandTask) -> None:
        stream = task.process.stdout
        if stream is None:
            task.mark_output_closed()
            return

        try:
            try:
                decoder_factory = codecs.getincrementaldecoder(task.encoding)
            except LookupError:
                decoder_factory = codecs.getincrementaldecoder("utf-8")

            decoder = decoder_factory(errors="replace")

            while True:
                chunk = os.read(stream.fileno(), 4096)
                if not chunk:
                    break
                text = decoder.decode(chunk)
                task.append_output(text)

            final_text = decoder.decode(b"", final=True)
            task.append_output(final_text)
        except Exception:
            logging.exception("Failed reading task output id=%s", task.task_id)
        finally:
            try:
                stream.close()
            except OSError:
                pass
            task.mark_output_closed()

    def _wait_process(self, task: CommandTask) -> None:
        try:
            if task.timeout > 0:
                try:
                    returncode = task.process.wait(timeout=task.timeout)
                except subprocess.TimeoutExpired:
                    with task.output_changed:
                        task.timed_out = True
                        task.termination_requested = True
                        task.status = "stopping"
                        task.append_output(
                            f"\n[任务超过 {task.timeout} 秒，正在终止]\n"
                        )
                    self._send_terminate(task)
                    try:
                        returncode = task.process.wait(timeout=TASK_TERMINATE_GRACE)
                    except subprocess.TimeoutExpired:
                        self._send_kill(task)
                        returncode = task.process.wait()
            else:
                returncode = task.process.wait()
        except Exception:
            logging.exception("Failed waiting for task id=%s", task.task_id)
            returncode = task.process.poll()

        with task.output_changed:
            task.returncode = returncode
            task.finished_at = time.time()

            if task.timed_out:
                task.status = "timed_out"
            elif task.termination_requested:
                task.status = "terminated"
            elif returncode == 0:
                task.status = "completed"
            else:
                task.status = "failed"

            task.output_changed.notify_all()

        logging.info(
            "Task finished id=%s pid=%s status=%s returncode=%s",
            task.task_id,
            task.pid,
            task.status,
            task.returncode,
        )

    @staticmethod
    def _send_terminate(task: CommandTask) -> None:
        if task.process.poll() is not None:
            return

        if os.name == "nt":
            try:
                task.process.terminate()
            except OSError:
                pass
        else:
            try:
                os.killpg(task.process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass

    @staticmethod
    def _send_kill(task: CommandTask) -> None:
        if task.process.poll() is not None:
            return

        if os.name == "nt":
            try:
                subprocess.run(
                    ["taskkill", "/PID", str(task.process.pid), "/T", "/F"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
            except OSError:
                try:
                    task.process.kill()
                except OSError:
                    pass
        else:
            try:
                os.killpg(task.process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def _force_kill_later(self, task: CommandTask) -> None:
        try:
            task.process.wait(timeout=TASK_TERMINATE_GRACE)
        except subprocess.TimeoutExpired:
            self._send_kill(task)


TASK_MANAGER = TaskManager()


def check_auth(username: str, password: str) -> bool:
    return (
        hmac.compare_digest(username, AUTH_USERNAME)
        and hmac.compare_digest(password, AUTH_PASSWORD)
    )


def split_with_quotes(
    value: str,
    sep: str = "/",
    keep_quotes: bool = False,
    trim: bool = True,
    allow_empty: bool = True,
) -> list[str]:
    if sep == "":
        raise ValueError("sep must be a non-empty string")

    parts: list[str] = []
    current: list[str] = []
    in_quote = False
    quote_char: str | None = None
    index = 0
    separator_length = len(sep)

    while index < len(value):
        char = value[index]

        if not in_quote and char in ('"', "'"):
            in_quote = True
            quote_char = char
            current.append(char)
            index += 1
            continue

        if in_quote:
            current.append(char)
            if char == quote_char:
                in_quote = False
                quote_char = None
            index += 1
            continue

        if value.startswith(sep, index):
            token = "".join(current)
            if trim:
                token = token.strip()
            if token != "" or allow_empty:
                parts.append(token)
            current = []
            index += separator_length
            continue

        current.append(char)
        index += 1

    token = "".join(current)
    if trim:
        token = token.strip()
    if token != "" or allow_empty:
        parts.append(token)

    if not keep_quotes:
        def strip_outer_quotes(token_value: str) -> str:
            if (
                len(token_value) >= 2
                and token_value[0] == token_value[-1]
                and token_value[0] in ('"', "'")
            ):
                return token_value[1:-1]
            return token_value

        parts = [strip_outer_quotes(part) for part in parts]

    return parts


def get_last_value(values: dict[str, list[str]], key: str) -> str:
    candidates = values.get(key)
    return candidates[-1] if candidates else ""


def first_nonempty(*values: str) -> str:
    for value in values:
        if value:
            return value
    return ""


def parse_bool(value: object, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    return str(value).lower() in {"1", "true", "on", "yes"}


def parse_int(value: object, default: int = 0) -> int:
    try:
        return int(str(value))
    except (TypeError, ValueError):
        return default


def parse_form_data(
    content_type_header: str,
    body: bytes,
) -> dict[str, list[str]]:
    if not body:
        return {}

    media_type = content_type_header.split(";", 1)[0].strip().lower()

    if media_type == "application/x-www-form-urlencoded":
        charset = "utf-8"

        for item in content_type_header.split(";")[1:]:
            name, separator, value = item.strip().partition("=")
            if separator and name.lower() == "charset":
                charset = value.strip().strip('"') or "utf-8"
                break

        try:
            text = body.decode(charset)
        except (LookupError, UnicodeDecodeError):
            text = body.decode("utf-8", errors="replace")

        return parse_qs(text, keep_blank_values=True)

    if media_type == "multipart/form-data":
        raw_message = (
            f"Content-Type: {content_type_header}\r\n"
            "MIME-Version: 1.0\r\n"
            "\r\n"
        ).encode("latin-1") + body

        message = BytesParser(policy=email_policy).parsebytes(raw_message)
        result: dict[str, list[str]] = {}

        if not message.is_multipart():
            return result

        for part in message.iter_parts():
            if part.get_content_disposition() != "form-data":
                continue

            field_name = part.get_param(
                "name",
                header="content-disposition",
                unquote=True,
            )

            if not field_name or part.get_filename() is not None:
                continue

            payload = part.get_payload(decode=True) or b""
            charset = part.get_content_charset() or "utf-8"

            try:
                value = payload.decode(charset)
            except (LookupError, UnicodeDecodeError):
                value = payload.decode("utf-8", errors="replace")

            result.setdefault(field_name, []).append(value)

        return result

    return {}


def command_to_display(params: list[str]) -> str:
    if os.name == "nt":
        return subprocess.list2cmdline(params)
    return shlex.join(params)


def prepare_process_command(
    params: list[str],
    shell: bool,
    shell_command: str | None = None,
) -> str | list[str]:
    if not shell:
        return params

    if shell_command is not None and shell_command.strip():
        return shell_command

    return command_to_display(params)


def task_page_html(task: CommandTask) -> str:
    return TASK_PAGE_HTML.replace(
        "__TASK_ID_JSON__",
        json.dumps(task.task_id),
    ).replace(
        "__INTERACTIVE_JSON__",
        "true" if task.interactive else "false",
    )


def tasks_list_html(tasks: list[CommandTask]) -> str:
    rows: list[str] = []

    for task in tasks:
        created = datetime.datetime.fromtimestamp(task.created_at).strftime(
            "%Y-%m-%d %H:%M:%S"
        )
        task_url = "/tasks/" + quote(task.task_id)
        rows.append(
            "<tr>"
            f"<td><a href=\"{task_url}\">{html.escape(task.task_id[:12])}</a></td>"
            f"<td>{html.escape(task.status)}</td>"
            f"<td>{task.pid}</td>"
            f"<td>{html.escape(created)}</td>"
            f"<td><code>{html.escape(task.command_display)}</code></td>"
            "</tr>"
        )

    if not rows:
        rows.append('<tr><td colspan="5">暂无任务</td></tr>')

    return f'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>任务列表</title>
<style>
body {{ margin: 8px; }}
table {{ border-collapse: collapse; }}
th, td {{ border: 1px solid; padding: 4px; text-align: left; }}
</style>
</head>
<body>
<h3>任务列表</h3>
<p><a href="/">返回首页</a> | <a href="/tasks">刷新</a></p>
<table>
<thead><tr><th>任务 ID</th><th>状态</th><th>PID</th><th>创建时间</th><th>命令</th></tr></thead>
<tbody>{''.join(rows)}</tbody>
</table>
</body>
</html>'''


class CommandRequestHandler(BaseHTTPRequestHandler):
    server_version = "WebShellHTTP/1.0"

    def do_GET(self) -> None:
        self.route_request(send_body=True)

    def do_HEAD(self) -> None:
        self.route_request(send_body=False)

    def do_POST(self) -> None:
        self.route_request(send_body=True)

    def do_PUT(self) -> None:
        self.send_text("Method Not Allowed", status=405)

    def do_PATCH(self) -> None:
        self.send_text("Method Not Allowed", status=405)

    def do_DELETE(self) -> None:
        self.send_text("Method Not Allowed", status=405)

    def route_request(self, send_body: bool) -> None:
        parsed_url = urlsplit(self.path)
        path = parsed_url.path

        if path == "/favicon.ico":
            self.send_text("Not Found", status=404, send_body=send_body)
            return

        if not self.require_authentication():
            return

        if path == "/tasks":
            if self.command not in {"GET", "HEAD"}:
                self.send_text("Method Not Allowed", status=405)
                return
            self.send_html(tasks_list_html(TASK_MANAGER.list()), send_body=send_body)
            return

        if path.startswith("/tasks/"):
            if self.command not in {"GET", "HEAD"}:
                self.send_text("Method Not Allowed", status=405)
                return
            task_id = unquote(path[len("/tasks/"):])
            task = TASK_MANAGER.get(task_id)
            if task is None:
                self.send_text("Task not found", status=404, send_body=send_body)
                return
            self.send_html(task_page_html(task), send_body=send_body)
            return

        if path == "/api/tasks" or path.startswith("/api/tasks/"):
            self.handle_task_api(parsed_url, send_body=send_body)
            return

        query_values = parse_qs(parsed_url.query, keep_blank_values=True)

        if (
            path in {"/", "/index.html"}
            and "cmd" not in query_values
            and self.command in {"GET", "HEAD"}
        ):
            self.send_html(INDEX_HTML, send_body=send_body)
            return

        # 保持旧用法：/?cmd=... 和 /command/arg1/arg2 仍然可直接同步执行。
        self.handle_command_request(parsed_url, send_body=send_body)

    def is_authenticated(self) -> bool:
        auth_header = self.headers.get("Authorization", "")
        auth_type, separator, credentials = auth_header.partition(" ")

        if not separator or auth_type.lower() != "basic":
            return False

        try:
            decoded = base64.b64decode(credentials, validate=True).decode("utf-8")
            username, password = decoded.split(":", 1)
        except (binascii.Error, UnicodeDecodeError, ValueError):
            return False

        return check_auth(username, password)

    def require_authentication(self) -> bool:
        if not REQUIRE_AUTH or self.is_authenticated():
            return True

        self.send_text(
            "Unauthorized",
            status=401,
            extra_headers={
                "WWW-Authenticate": 'Basic realm="Restricted Area"',
            },
        )
        return False

    def read_request_body(self) -> bytes:
        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            content_length = 0

        return self.rfile.read(content_length) if content_length > 0 else b""

    def read_json_body(self) -> dict[str, object]:
        body = self.read_request_body()
        if not body:
            return {}

        try:
            value = json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exception:
            raise ValueError("Invalid JSON body") from exception

        if not isinstance(value, dict):
            raise ValueError("JSON body must be an object")

        return value

    def handle_task_api(self, parsed_url, send_body: bool) -> None:
        path = parsed_url.path
        parts = [unquote(part) for part in path.strip("/").split("/")]

        # /api/tasks
        if len(parts) == 2:
            if self.command == "GET":
                self.send_json(
                    {"tasks": [task.snapshot() for task in TASK_MANAGER.list()]},
                    send_body=send_body,
                )
                return

            if self.command == "POST":
                try:
                    payload = self.read_json_body()
                    task = self.start_task_from_json(payload)
                except (ValueError, OSError, KeyError) as exception:
                    logging.exception("Failed to start task from API")
                    self.send_json(
                        {"error": str(exception)},
                        status=400,
                        send_body=send_body,
                    )
                    return

                self.send_json(task.snapshot(), status=202, send_body=send_body)
                return

            self.send_text("Method Not Allowed", status=405, send_body=send_body)
            return

        if len(parts) not in {3, 4}:
            self.send_json({"error": "Not Found"}, status=404, send_body=send_body)
            return

        task_id = parts[2]
        task = TASK_MANAGER.get(task_id)
        if task is None:
            self.send_json(
                {"error": "Task not found"},
                status=404,
                send_body=send_body,
            )
            return

        if len(parts) == 3:
            if self.command not in {"GET", "HEAD"}:
                self.send_text("Method Not Allowed", status=405, send_body=send_body)
                return
            self.send_json(task.snapshot(), send_body=send_body)
            return

        action = parts[3]

        if action == "output":
            if self.command not in {"GET", "HEAD"}:
                self.send_text("Method Not Allowed", status=405, send_body=send_body)
                return

            query = parse_qs(parsed_url.query, keep_blank_values=True)
            after = max(0, parse_int(get_last_value(query, "after"), 0))
            wait_seconds = float(parse_int(get_last_value(query, "wait"), 0))
            self.send_json(
                task.read_output(after, wait_seconds),
                send_body=send_body,
            )
            return

        if self.command != "POST":
            self.send_text("Method Not Allowed", status=405, send_body=send_body)
            return

        try:
            if action == "input":
                payload = self.read_json_body()
                data = payload.get("data", "")
                if not isinstance(data, str):
                    raise ValueError("data must be a string")
                task = TASK_MANAGER.write_input(task_id, data)
            elif action == "interrupt":
                task = TASK_MANAGER.interrupt(task_id)
            elif action == "terminate":
                task = TASK_MANAGER.terminate(task_id)
            else:
                self.send_json(
                    {"error": "Not Found"},
                    status=404,
                    send_body=send_body,
                )
                return
        except (KeyError, RuntimeError, ValueError, OSError) as exception:
            self.send_json(
                {"error": str(exception)},
                status=409,
                send_body=send_body,
            )
            return

        self.send_json(task.snapshot(), send_body=send_body)

    def start_task_from_json(self, payload: dict[str, object]) -> CommandTask:
        command = payload.get("command", "")
        arguments = payload.get("args", [])

        if not isinstance(command, str) or not command.strip():
            raise ValueError("command must be a non-empty string")
        if not isinstance(arguments, list) or not all(
            isinstance(argument, str) for argument in arguments
        ):
            raise ValueError("args must be an array of strings")

        cwd_value = payload.get("cwd")
        cwd = (
            cwd_value
            if isinstance(cwd_value, str) and cwd_value
            else USER_HOME_DIRECTORY
        )
        shell = parse_bool(payload.get("shell"), False)
        mode = str(payload.get("mode", "task"))
        interactive = mode == "interactive" or parse_bool(
            payload.get("interactive"), False
        )
        timeout = parse_int(payload.get("timeout"), TASK_TIMEOUT)
        encoding_value = payload.get("encoding")
        encoding = (
            encoding_value
            if isinstance(encoding_value, str) and encoding_value
            else COMMAND_ENCODING
        )
        try:
            codecs.lookup(encoding)
        except LookupError as exception:
            raise ValueError(f"Unknown encoding: {encoding}") from exception

        params = [command, *arguments]
        shell_command_value = payload.get("shell_command")
        shell_command = (
            shell_command_value
            if isinstance(shell_command_value, str)
            else None
        )
        if shell and shell_command is None and not arguments:
            # API 中 shell=true 且没有 args 时，command 就是一整段 Shell 命令。
            shell_command = command
        process_command = prepare_process_command(
            params,
            shell,
            shell_command=shell_command,
        )
        command_display = (
            process_command if isinstance(process_command, str)
            else command_to_display(process_command)
        )

        return TASK_MANAGER.start(
            process_command=process_command,
            command_display=command_display,
            cwd=cwd,
            shell=shell,
            interactive=interactive,
            timeout=timeout,
            encoding=encoding,
        )

    def handle_command_request(self, parsed_url, send_body: bool) -> None:
        query_values = parse_qs(parsed_url.query, keep_blank_values=True)
        request_body = self.read_request_body() if self.command == "POST" else b""
        form_values = parse_form_data(
            self.headers.get("Content-Type", ""),
            request_body,
        )

        cwd = first_nonempty(
            get_last_value(query_values, "cwd"),
            get_last_value(form_values, "cwd"),
            USER_HOME_DIRECTORY,
        )

        shell_value = first_nonempty(
            get_last_value(query_values, "shell"),
            get_last_value(form_values, "shell"),
        )
        shell = parse_bool(shell_value)

        capture_value = first_nonempty(
            get_last_value(query_values, "capture_output"),
            get_last_value(form_values, "capture_output"),
            "true",
        )
        capture_output = parse_bool(capture_value, True)

        run_mode = first_nonempty(
            get_last_value(query_values, "run_mode"),
            get_last_value(form_values, "run_mode"),
            "sync",
        ).lower()

        timeout_value = first_nonempty(
            get_last_value(query_values, "timeout"),
            get_last_value(form_values, "timeout"),
        )
        task_timeout = parse_int(timeout_value, TASK_TIMEOUT)

        encoding = first_nonempty(
            get_last_value(query_values, "encoding"),
            get_last_value(form_values, "encoding"),
            COMMAND_ENCODING,
        )

        command = first_nonempty(
            get_last_value(query_values, "cmd"),
            get_last_value(form_values, "cmd"),
        )
        shell_command: str | None = None

        if command:
            command = command.replace("%26", "&")
            params = split_with_quotes(command, sep=" ", allow_empty=False)
            shell_command = command
        else:
            route_path = parsed_url.path
            relative_path = route_path.lstrip("/")

            if not relative_path or relative_path == "index.html":
                self.send_text("No command specified", send_body=send_body)
                return

            decoded_path = unquote(
                relative_path,
                encoding="utf-8",
                errors="replace",
            )
            params = split_with_quotes(
                decoded_path,
                sep="/",
                allow_empty=False,
            )

            if len(params) == 1:
                params = split_with_quotes(
                    params[0],
                    sep=" ",
                    allow_empty=False,
                )

        if not params or not params[0]:
            self.send_text("No command specified", send_body=send_body)
            return

        process_command = prepare_process_command(
            params,
            shell,
            shell_command=shell_command,
        )
        command_display = (
            process_command if isinstance(process_command, str)
            else command_to_display(process_command)
        )

        print()
        print(
            datetime.datetime.now(),
            "Starting",
            "\n",
            "cmd:",
            command_display,
            "\n",
            "cwd:",
            cwd,
            "\n",
            "run_mode:",
            run_mode,
        )

        if run_mode in {"task", "interactive"}:
            if self.command == "HEAD":
                self.send_text(
                    "HEAD cannot start a background task",
                    status=405,
                    send_body=False,
                )
                return

            try:
                task = TASK_MANAGER.start(
                    process_command=process_command,
                    command_display=command_display,
                    cwd=cwd,
                    shell=shell,
                    interactive=run_mode == "interactive",
                    timeout=task_timeout,
                    encoding=encoding,
                )
            except Exception as exception:
                print("Exception:", exception)
                logging.exception("Task start failed")
                self.send_text(
                    "Exception: " + str(exception),
                    status=500,
                    send_body=send_body,
                )
                return

            response_value = first_nonempty(
                get_last_value(query_values, "response"),
                get_last_value(form_values, "response"),
            )
            wants_json = (
                response_value.lower() == "json"
                or "application/json" in self.headers.get("Accept", "")
            )

            if wants_json:
                self.send_json(task.snapshot(), status=202, send_body=send_body)
            else:
                self.send_redirect("/tasks/" + quote(task.task_id), status=303)
            return

        try:
            task = TASK_MANAGER.start(
                process_command=process_command,
                command_display=command_display,
                cwd=cwd,
                shell=shell,
                interactive=False,
                timeout=COMMAND_TIMEOUT,
                encoding=encoding,
                output_limit=None if capture_output else 0,
                mirror_output=not capture_output,
            )
            task.wait_finished()
        except Exception as exception:
            print("Exception:", exception)
            logging.exception("Command execution failed")
            self.send_text(
                "Exception: " + str(exception),
                status=500,
                send_body=send_body,
            )
            return

        output = task.get_buffered_output() if capture_output else ""
        status = 200

        if task.returncode != 0:
            status = 500
            if capture_output:
                error_value = (
                    "timed_out"
                    if task.timed_out
                    else task.returncode
                )
                output = f"Error: {error_value}\n\n{output}"

        print(
            datetime.datetime.now(),
            "finished",
            "\n",
            "cmd:",
            command_display,
            "\n",
            "cwd:",
            cwd,
            "\n",
            "task_id:",
            task.task_id,
        )

        if capture_output:
            logging.info("\n%s", output)

        self.send_text(
            output,
            status=status,
            content_type="text/plain; charset=UTF-8",
            extra_headers={"X-Task-ID": task.task_id},
            send_body=send_body,
        )

    def send_redirect(self, location: str, status: int = 303) -> None:
        self.send_response(status)
        self.send_header("Location", location)
        self.send_header("Content-Length", "0")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

    def send_html(self, html_text: str, send_body: bool = True) -> None:
        body = html_text.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=UTF-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

        if send_body:
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

    def send_json(
        self,
        value: object,
        status: int = 200,
        send_body: bool = True,
    ) -> None:
        body = json.dumps(
            value,
            ensure_ascii=False,
            separators=(",", ":"),
        ).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=UTF-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

        if send_body:
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

    def send_text(
        self,
        text: str,
        status: int = 200,
        content_type: str = "text/plain; charset=UTF-8",
        extra_headers: dict[str, str] | None = None,
        send_body: bool = True,
    ) -> None:
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")

        if extra_headers:
            for name, value in extra_headers.items():
                self.send_header(name, value)

        self.end_headers()

        if send_body:
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass


class CommandHTTPServer(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the Web Shell HTTP server.")
    parser.add_argument(
        "--host",
        "-H",
        default="0.0.0.0",
        help="Host to listen on (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port",
        "-p",
        type=int,
        default=8000,
        help="Port to listen on (default: 8000)",
    )
    args = parser.parse_args()

    server = CommandHTTPServer(
        (args.host, args.port),
        CommandRequestHandler,
    )

    try:
        print(f"Starting Web Shell server v{APP_VERSION} on http://{args.host}:{args.port}")
        print(f"Synchronous execution backend: {SYNC_IMPLEMENTATION}")
        print(f"Basic authentication: {'enabled' if REQUIRE_AUTH else 'disabled'}")
        print(f"Command encoding: {COMMAND_ENCODING}")
        print(f"Task timeout: {TASK_TIMEOUT or 'unlimited'}")
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopping Web Shell server...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
