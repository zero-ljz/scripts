import subprocess

import fire

def run_cmd(command, wait=True):
    """
    执行命令行命令
    :param command: 要执行的命令字符串
    :param wait: 是否等待命令完成，默认为 True
    :return: 如果等待，返回命令的输出，否则返回 None
    """
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    if wait:
        process.wait()
        return process.stdout.read()
    else:
        return None

def run_python(script, wait=True):
    """
    执行 Python 脚本
    :param script: Python 脚本字符串
    :param wait: 是否等待脚本执行完成，则为 True
    :return: 如果等待，返回脚本的输出；否则返回 None
    """
    command = f"python {script}"
    return run_cmd(command, wait)

def run_powershell(script, wait=True):
    """
    执行 PowerShell 脚本
    :param script: PowerShell 脚本字符串
    :param wait: 是否等待脚本执行完成，默认为 True
    :return: 如果等待，返回脚本的输出；否则返回 None
    """
    command = f"powershell -ExecutionPolicy ByPass -Command \"{script}\""
    return run_cmd(command, wait)

def run_nodejs(script, wait=True):
    """
    执行 Node.js 脚本
    :param script: Node.js 脚本字符串
    :param wait: 是否等待脚本执行完成，默认为 True
    :return: 如果等待，返回脚本的输出；否则返回 None
    """
    command = f"node -e \"{script}\""
    return run_cmd(command, wait)

def run_autohotkey(script, wait=True):
    """
    执行 AutoHotkey 脚本
    :param script: AutoHotkey 脚本字符串
    :param wait: 是否等待脚本执行完成，默认为 True
    :return: 如果等待，返回脚本的退出码；否则返回 None
    """
    ahk_exe = r"C:\Program Files\AutoHotkey\AutoHotkey.exe"  # AutoHotkey 执行文件的路径，请根据实际情况修改
    command = f'"{ahk_exe}" /ErrorStdOut *'
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True)
    
    if wait:
        stdout, stderr = process.communicate(input=script)
        process.wait()
        return process.returncode
    else:
        return None

def ahk_ExecScript(script, wait=True):
    """
    执行 AutoHotkey 脚本
    :param script: AutoHotkey 脚本字符串
    :param wait: 是否等待脚本执行完成，则为 True
    :return: 如果等待，返回脚本的输出；否则返回 None
    """
    autohotkey_exe = r'C:\Program Files\AutoHotkey\AutoHotkey.exe'

    # 使用subprocess执行脚本
    process = subprocess.Popen([autohotkey_exe, '/ErrorStdOut', '*'], 
                               stdin=subprocess.PIPE, 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.PIPE,
                               text=True)
    
    # 将脚本写入标准输入
    process.stdin.write(script)
    process.stdin.close()

    if wait:
        # 等待脚本执行完成
        process.wait()
        # 读取标准输出和标准错误
        stdout = process.stdout.read()
        stderr = process.stderr.read()
        return stdout, stderr
    else:
        return None

def run_git_bash(script, wait=True):
    """
    执行 Git Bash 脚本
    :param script: Git Bash 脚本字符串
    :param wait: 是否等待脚本执行完成，默认为 True
    :return: 如果等待，返回脚本的输出；否则返回 None
    """
    git_bash_exe = r'C:\Program Files\Git\bin\bash.exe'  # Git Bash 执行文件的路径，请根据实际情况修改
    command = f'"{git_bash_exe}" -c "{script}"'
    
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True)
    
    if wait:
        stdout, stderr = process.communicate()
        process.wait()
        return stdout
    else:
        return None


if __name__ == '__main__':
    fire.Fire()

# print(run_powershell("Write-Host 'Hello, PowerShell!'"))

# print(run_nodejs("console.log('Hello, Node.js!');"))

# print(run_autohotkey("""
# MsgBox Hello, AutoHotkey!
# Exit
# """))

# stdout, stderr = ahk_ExecScript("""
# MsgBox Hello, World!
# """)
# print("标准输出：")
# print(stdout)
# print("标准错误：")
# print(stderr)


# print(run_git_bash(""" echo 'Hello, Git Bash!'; echo 'This is a multiline command.'; pwd; """))
