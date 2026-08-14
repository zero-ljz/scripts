# scripts

个人日常使用的脚本与代码片段集合，主要用于 Windows 自动化、Linux/WSL 运维、数据处理以及 Web 开发实验。

这些脚本大多针对特定设备和使用习惯编写，并非开箱即用的通用工具。运行前请阅读源码，确认路径、端口、账号、软件版本和操作对象符合你的环境。

> [!WARNING]
> 仓库中包含修改注册表、安装或卸载软件、调整系统配置、操作数据库、执行远程命令等高权限脚本。请先备份重要数据，并优先在虚拟机或测试环境中验证。不要直接执行来源不明或未经审查的脚本。

## 目录

| 目录 | 语言 | 简介 |
| --- | --- | --- |
| [`autohotkey/`](autohotkey/) | AutoHotkey | 面向 Windows 的自动化脚本语言，适合编写快捷键、键鼠操作和桌面工具。 |
| [`autojs/`](autojs/) | JavaScript（Auto.js） | 在 Android 上运行的 JavaScript 自动化脚本，可用于界面操作和设备任务。 |
| [`batchfile/`](batchfile/) | Batch、Registry | Batch 是 Windows 命令行批处理语言；Registry 文件用于导入和修改注册表配置。 |
| [`cfworkers/`](cfworkers/) | JavaScript | 运行在 Cloudflare Workers 边缘环境中的 JavaScript 脚本。 |
| [`jscript/`](jscript/) | JScript、VBScript、HTA | Windows Script Host 脚本及基于 HTML 的 Windows 桌面应用。 |
| [`nodejs/`](nodejs/) | JavaScript（Node.js） | 运行在 Node.js 服务端环境中的 JavaScript，适合网络服务和命令行工具。 |
| [`php/`](php/) | PHP | 常用于服务端 Web 开发的脚本语言，可处理请求、文件和动态页面。 |
| [`powershell/`](powershell/) | PowerShell | 基于对象管道的 Windows 命令行与自动化脚本语言。 |
| [`python/`](python/) | Python | 通用脚本语言，适合自动化、数据处理、Web 开发和工具编写。 |
| [`shell/`](shell/) | Bash | Linux 和 Unix 环境常用的 Shell 脚本语言，适合系统管理与任务自动化。 |
| [`tampermonkey/`](tampermonkey/) | JavaScript | 运行在浏览器用户脚本管理器中的 JavaScript，用于修改网页行为。 |

## 说明

本仓库以个人使用和学习记录为主，可能包含基于公开资料整理或修改的代码片段。第三方项目、接口和代码的权利归其各自所有者；使用时请遵守相应许可、服务条款和当地法律法规。
