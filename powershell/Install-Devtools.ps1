# 文件编码 UTF-8 with BOM
# powershell -ExecutionPolicy Bypass -File ".\install_devtools.ps1"


if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "自动检测安装 WinGet" -ForegroundColor Cyan
    curl.exe -LkOJ https://github.com/microsoft/winget-cli/releases/download/v1.12.440/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    powershell -Command "Add-AppxPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
}

# winget install -e --id SomePythonThings.WingetUIStore
# winget install -e --id Microsoft.Teams.Free
# winget install -e --id Microsoft.WindowsPCHealthCheck
# winget install -e --id Microsoft.MouseandKeyboardCenter
# winget install -e --id 9NBLGGH5R558 # To Do
# winget install -e --id 9MSPC6MP8FM4 # Whiteboard

Write-Host "`n`n`n 安装 Chocolatey" -ForegroundColor Cyan
choice /T 5 /D y /M "是否继续？"
if ($LASTEXITCODE -eq 1) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Write-Host "`n`n`n 安装 Python" -ForegroundColor Cyan
choice /T 5 /D y /M "是否继续？"
if ($LASTEXITCODE -eq 1) {
    winget install -e --accept-source-agreements --id Python.Python.3.10 --version 3.10.11
    winget install -e --accept-source-agreements --id Python.Python.3.12 --version 3.12.10
    # 配置国内源
    pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
    # Python UTF-8 Mode (PEP 540) 强制python使用utf-8
    [Environment]::SetEnvironmentVariable("PYTHONUTF8", "1", "User")
    # 安装pipx
    # pip install --user pipx
    # 自动添加到用户环境变量Path
    # python -m pipx ensurepath
    # 在隔离环境中安装poetry
    # python -m pipx install poetry==1.8.3
    # 安装uv
    winget install --id astral-sh.uv
}

Write-Host "`n`n`n 安装 NodeJS" -ForegroundColor Cyan
choice /T 5 /D y /M "是否继续？"
if ($LASTEXITCODE -eq 1) {
    winget install -e --id OpenJS.NodeJS.LTS
    # 配置国内源
    npm config set registry https://registry.npmmirror.com
    # 安装pnpm
    npm install -g pnpm
}

# NSSM (Non-Sucking Service Manager)。
# 用法：nssm install MyPanel "C:\Python\python.exe" "C:\Panel\main.py"
# 它非常稳定，专门用来把普通 exe/脚本变成 Windows 服务。
# winget install -e --id NSSM.NSSM


Write-Host "`n`n`n 安装 常用软件" -ForegroundColor Cyan
choice /T 5 /D y /M "是否继续？"
if ($LASTEXITCODE -eq 1) {
# Write-Host "安装 AutoHotkey (v1.1)" -ForegroundColor Cyan
# winget install -e --id AutoHotkey.AutoHotkey --version 1.1.37.02

Write-Host "安装 Everything 文件搜索" -ForegroundColor Cyan
winget install -e --id voidtools.Everything

Write-Host "安装 Windows终端" -ForegroundColor Cyan
winget install -e --id Microsoft.WindowsTerminal

Write-Host "安装 Git" -ForegroundColor Cyan
winget install -e --id Git.Git
# 配置用户信息
# git config --global user.name 'zero-ljz'
# git config --global user.email '2267719005@qq.com'

# winget install -e --id MSYS2.MSYS2

# winget install -e --id Microsoft.PowerToys
# winget install -e --id DeepL.DeepL
winget install -e --id Notepad++.Notepad++

# winget install -e --id kangfenmao.CherryStudio
# winget install -e --id farion1231.CC-Switch

Write-Host "安装 VS Code" -ForegroundColor Cyan
winget install -e --id Microsoft.VisualStudioCode

Write-Host "安装 GitHub Desktop" -ForegroundColor Cyan
winget install -e --id GitHub.GitHubDesktop

Write-Host "安装 Navicat Premium Lite" -ForegroundColor Cyan
winget install -e --id PremiumSoft.NavicatPremiumLite

Write-Host "安装 Revo Uninstaller" -ForegroundColor Cyan
winget install -e --id RevoUninstaller.RevoUninstaller

Write-Host "安装 micro 终端文本编辑器" -ForegroundColor Cyan
winget install -e --id zyedidia.micro

Write-Host "安装 btop4win 性能监视器" -ForegroundColor Cyan
winget install -e --id aristocratos.btop4win

Write-Host "安装 7-Zip" -ForegroundColor Cyan
winget install -e --id 7zip.7zip

Write-Host "安装 Sublime Text 4" -ForegroundColor Cyan
winget install -e --id SublimeHQ.SublimeText.4

Write-Host "安装 Notepad3" -ForegroundColor Cyan
winget install -e --id Rizonesoft.Notepad3

Write-Host "安装 Bandizip (v6.29)" -ForegroundColor Cyan
winget install -e --id Bandisoft.Bandizip --version 6.29

Write-Host "安装 Honeyview 看图软件" -ForegroundColor Cyan
winget install -e --id Bandisoft.Honeyview

Write-Host "安装 Snipaste 截图工具" -ForegroundColor Cyan
winget install -e --id liule.Snipaste

Write-Host "安装 Fiddler Classic" -ForegroundColor Cyan
winget install -e --id Telerik.Fiddler.Classic

Write-Host "安装 SumatraPDF" -ForegroundColor Cyan
winget install -e --id SumatraPDF.SumatraPDF

Write-Host "安装 VLC 媒体播放器" -ForegroundColor Cyan
winget install -e --id VideoLAN.VLC

Write-Host "安装 WizTree 磁盘空间分析" -ForegroundColor Cyan
winget install -e --id AntibodySoftware.WizTree

Write-Host "安装 Geek Uninstaller" -ForegroundColor Cyan
winget install -e --id GeekUninstaller.GeekUninstaller

Write-Host "安装 pot 聚合翻译工具" -ForegroundColor Cyan
winget install -e --id Pylogmon.pot

# Write-Host "安装 Crow Translate" -ForegroundColor Cyan
# winget install -e --id KDE.CrowTranslate

# winget install -e --id Postman.Postman
# winget install -e --id hoppscotch.Hoppscotch
# winget install -e --id Anki.Anki
# winget install Termius.Termius
# winget install -e --id Automattic.Simplenote
# winget install -e --id Obsidian.Obsidian
# winget install -e --id Logseq.Logseq
# winget install -e --id Notion.Notion
# winget install -e --id Joplin.Joplin
# winget install -e --id Youdao.YoudaoTranslate
# winget install -e --id ByteDance.Feishu
# winget install -e --id Adobe.Acrobat.Reader.64-bit
# winget install -e --id ShareX.ShareX
# winget install -e --id DuongDieuPhap.ImageGlass
# winget install -e --id Daum.PotPlayer
# winget install -e --id AdrienAllard.FileConverter
# winget install -e --id Tencent.WeChat
# winget install -e --id Tencent.QQ
# winget install -e --id Tencent.QQMusic
# winget install -e --id Tencent.TencentMeeting

# wget https://mirrors.aliyun.com/mariadb///mariadb-10.6.27/winx64-packages/mariadb-10.6.27-winx64.msi -O mariadb-10.6.27-winx64.msi
# winget install -e --id Xmind.Xmind

# winget install -e --id Microsoft.WSL --version 1.0.0.20210422 --quiet Write-Host "安装 WSL2"
# winget install -e --id Ubuntu --quiet # 使用 winget 安装 WSL2 发行版
# wsl --install --distribution Debian


# winget install -e --id Docker.DockerDesktop --version 4.1.1 --quiet

# winget install -e --id Microsoft.BingWallpaper
# winget install -e --id CosmoX.Lepton

# winget install -e --id Sandboxie.Plus
# winget install -e --id Telegram.TelegramDesktop

# winget install -e --id JavadMotallebi.NeatDownloadManager # 提示找不到包
# winget install -e --id WinSCP.WinSCP
winget install -e --id c0re100.qBittorrent-Enhanced-Edition
# winget install -e --id PremiumSoft.NavicatPremium

# winget install -e --id TeamViewer.TeamViewer
# winget install -e --id Youqu.ToDesk
# winget install -e --id VMware.WorkstationPro


# winget install -e --id HTTPie.HTTPie
# winget install -e --id Insomnia.Insomnia
# winget install -e --id ElectronCommunity.ElectronFiddle # 刚安装完就提示有更新
# winget install -e --id Cloudflare.Warp
# winget install -e --id Shilihu.Mubu # 幕布, 安装时提示执行InternetOpenUrl命令失败
# winget install -e --id shimo.shimo

# winget install -e --id Dropbox.Dropbox

# 10.4.30和10.6.27已经被删
# winget install -e --id MariaDB.Server
# winget install -e --id Oracle.MySQLShell
# winget install -e --id Oracle.MySQLWorkbench
# winget install -e --id BlueStack.BlueStacks --version 5.20.0.1037

# winget install -e --id ByteDance.StreamingTool # 直播伴侣
# winget install -e --id ByteDance.Douyin
# winget install -e --id ByteDance.JianyingPro
# winget install -e --id Bilibili.Bilibili
# winget install -e --id CCTV.CBox

# winget install -e --id NetEase.CloudMusic # 网易云音乐
# winget install -e --id 360.360Chrome.X

# winget install -e --id Baidu.BaiduNetdisk # 百度网盘, 包370m, 装完还添加了广告的开机自启
# winget install -e --id Baidu.BaiduTranslate # 百度翻译

# winget install -e --id Alibaba.DingTalk # 钉钉, 会设置开机自启, 并且卸载之后会留下无效的开机启动项
# winget install -e --id Alibaba.aDrive # 阿里云盘


# winget install -e --id Tencent.TencentVideo # 腾讯视频
# winget install -e --id Tencent.QQPlayer # QQ影音
# winget install -e --id Tencent.YingYongBao # 应用宝
# winget install -e --id Tencent.WeType # 微信输入法
# winget install -e --id Tencent.WeCom # 企业微信
# winget install -e --id Tencent.WeixinDevTools # 微信开发者工具



}

Write-Host "`n`n`n 安装 VSCode 扩展" -ForegroundColor Cyan
choice /T 5 /D y /M "是否继续？"
if ($LASTEXITCODE -eq 1) {

Write-Host "安装 中文语言包" -ForegroundColor Cyan
code --install-extension MS-CEINTL.vscode-language-pack-zh-hans
Write-Host "安装 vscode-icons 经典图标包" -ForegroundColor Cyan
code --install-extension vscode-icons-team.vscode-icons
Write-Host "安装 GitHub 官方主题包" -ForegroundColor Cyan
code --install-extension GitHub.github-vscode-theme

# === Python 开发基础 ===
Write-Host "安装 Python 语言核心支持扩展" -ForegroundColor Cyan
code --install-extension ms-python.python
Write-Host "安装 Pylance 静态类型检查与代码提示工具" -ForegroundColor Cyan
code --install-extension ms-python.vscode-pylance
Write-Host "安装 Python 调试器支持" -ForegroundColor Cyan
code --install-extension ms-python.debugpy
Write-Host "安装 Python 环境切换与管理工具" -ForegroundColor Cyan
code --install-extension ms-python.vscode-python-envs
Write-Host "安装 Python 自动缩进优化工具" -ForegroundColor Cyan
code --install-extension KevinRose.vsc-python-indent
Write-Host "安装 Ruff 超快 Python 代码快速检查与格式化工具" -ForegroundColor Cyan
code --install-extension charliermarsh.ruff
# Write-Host "安装 Python 文档字符串自动生成工具" -ForegroundColor Cyan
# code --install-extension njpwerner.autodocstring
# Write-Host "安装 Qt for Python (PySide/PyQt) 界面开发支持" -ForegroundColor Cyan
# code --install-extension seanwu.vscode-qt-for-python

# Write-Host "AHK v2 最强语法提示" -ForegroundColor Cyan
# code --install-extension thqby.vscode-autohotkey2-lsp
# Write-Host "Rust 语言支持" -ForegroundColor Cyan
# code --install-extension rust-lang.rust-analyzer

# === AI 编程助手 ===
Write-Host "安装 Continue 开源 AI 编程助手" -ForegroundColor Cyan
code --install-extension Continue.continue
# Write-Host "安装 Roo Cline 基于 Agent 的 AI 自动化编码助手" -ForegroundColor Cyan
# code --install-extension RooVeterinaryInc.roo-cline
# Write-Host "安装 Claude Dev 强大的 AI 编码与自主 Agent 助手" -ForegroundColor Cyan
# code --install-extension saoudrizwan.claude-dev

# === 前端与 Web 开发 ===
Write-Host "安装 网页本地开发热重载服务 Live Server" -ForegroundColor Cyan
code --install-extension ritwickdey.LiveServer
Write-Host "安装 ESLint 语法规则检查工具" -ForegroundColor Cyan
code --install-extension dbaeumer.vscode-eslint
Write-Host "安装 HTML 中智能补全 CSS 类名工具" -ForegroundColor Cyan
code --install-extension Zignd.html-css-class-completion
Write-Host "安装 快捷在浏览器中打开 HTML 页面工具" -ForegroundColor Cyan
code --install-extension techer.open-in-browser

# === 容器与远程开发 ===
# Write-Host "安装 Docker 容器管理与支持扩展" -ForegroundColor Cyan
# code --install-extension ms-azuretools.vscode-docker
# Write-Host "安装 VS Code 远程开发容器核心支持" -ForegroundColor Cyan
# code --install-extension ms-azuretools.vscode-containers
# Write-Host "安装 远程连接与开发容器支持扩展" -ForegroundColor Cyan
# code --install-extension ms-vscode-remote.remote-containers

# === 配置文件与通用语言支持 ===
Write-Host "安装 PowerShell 脚本语言支持" -ForegroundColor Cyan
code --install-extension ms-vscode.PowerShell
Write-Host "安装 YAML 文件语法校验与提示扩展" -ForegroundColor Cyan
code --install-extension redhat.vscode-yaml
Write-Host "安装 XML 文件语法校验与提示扩展" -ForegroundColor Cyan
code --install-extension redhat.vscode-xml
Write-Host "安装 TOML 配置文件高级语法支持" -ForegroundColor Cyan
code --install-extension tamasfe.even-better-toml
Write-Host "安装 Markdown 专属全能辅助工具包" -ForegroundColor Cyan
code --install-extension yzhang.markdown-all-in-one

# === 网络请求与接口测试 ===
# Write-Host "安装 Thunder Client 轻量级接口测试工具" -ForegroundColor Cyan
# code --install-extension rangav.vscode-thunder-client
Write-Host "安装 REST Client 文本化接口测试工具" -ForegroundColor Cyan
code --install-extension humao.rest-client

# === 代码美化与视觉增强 ===
Write-Host "安装 Prettier 通用代码格式化工具" -ForegroundColor Cyan
code --install-extension esbenp.prettier-vscode
Write-Host "安装 Peacock 工作区窗口色彩区分工具" -ForegroundColor Cyan
code --install-extension johnpapa.vscode-peacock
Write-Host "安装 Rainbow CSV 彩色高亮分隔符表格工具" -ForegroundColor Cyan
code --install-extension mechatroner.rainbow-csv
Write-Host "安装 indent-rainbow 彩虹色缩进层级高亮工具" -ForegroundColor Cyan
code --install-extension oderwat.indent-rainbow
Write-Host "安装 Error Lens 错误与警告信息行内直接显示工具" -ForegroundColor Cyan
code --install-extension usernamehw.errorlens

# === 团队协作、版本控制与通用效率 ===
Write-Host "安装 Code Runner 多语言代码一键运行工具" -ForegroundColor Cyan
code --install-extension formulahendry.code-runner
# Write-Host "安装 GitLens 超级强大的 Git 代码追溯与历史洞察工具" -ForegroundColor Cyan
# code --install-extension eamodio.gitlens
Write-Host "安装 Git 提交历史可视化分支图查看器" -ForegroundColor Cyan
code --install-extension mhutchie.git-graph
Write-Host "安装 Console Ninja 编辑器内直接显示日志调试工具" -ForegroundColor Cyan
code --install-extension WallabyJs.console-ninja
# Write-Host "安装 Live Share 团队实时协同编程与调试工具" -ForegroundColor Cyan
# code --install-extension MS-vsliveshare.vsliveshare


# 其他
Write-Host "安装 GistPad 使用GitHub gist和存储库管理您的代码片段和开发人员笔记。" -ForegroundColor Cyan
code --install-extension vsls-contrib.gistfs
}