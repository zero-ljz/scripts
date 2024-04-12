if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    curl -LkOJ https://p.ljz.one/https://github.com/microsoft/winget-cli/releases/download/v1.5.1881/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    powershell -Command "Add-AppPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

winget install -e --id OpenJS.NodeJS.LTS  --version 18.20.2
winget install -e --id Python.Python.3.10 --version 3.10.11
winget install -e --id Git.Git
winget install -e --id GitHub.GitHubDesktop
# winget install -e --id Microsoft.WindowsTerminal
winget install -e --id Microsoft.PowerToys
winget install -e --id CosmoX.Lepton
winget install -e --id AutoHotkey.AutoHotkey --version 1.1.37.00

winget install -e --id Sandboxie.Plus
winget install -e --id Bandisoft.Bandizip --version 6.29

winget install -e --id Postman.Postman
winget install -e --id Telerik.Fiddler.Classic
winget install -e --id JavadMotallebi.NeatDownloadManager
winget install -e --id WinSCP.WinSCP
winget install -e --id c0re100.qBittorrent-Enhanced-Edition
winget install -e --id voidtools.Everything
winget install -e --id SublimeHQ.SublimeText.4

winget install -e --id PremiumSoft.NavicatPremium
winget install -e --id AdrienAllard.FileConverter
winget install -e --id DeepL.DeepL
winget install -e --id Anki.Anki
winget install -e --id Xmind.Xmind

winget install -e --id MariaDB.Server --version 10.4.30

winget install -e --id VideoLAN.VLC
winget install -e --id TeamViewer.TeamViewer
winget install -e --id VMware.WorkstationPro
winget install -e --id Notion.Notion
winget install -e --id Obsidian.Obsidian
winget install -e --id HTTPie.HTTPie
winget install -e --id ElectronCommunity.ElectronFiddle
winget install -e --id Cloudflare.Warp
winget install -e --id Mubu.Mubu # 幕布
winget install -e --id Automattic.Simplenote
winget install -e --id Oracle.MySQLShell
winget install -e --id Oracle.MySQLWorkbench
winget install -e --id 7zip.7zip
winget install -e --id Bandisoft.Bandizip --version 6.29
winget install -e --id BlueStack.BlueStacks --version 5.20.0.1037

winget install -e --id ByteDance.StreamingTool # 直播伴侣
winget install -e --id ByteDance.Douyin
winget install -e --id ByteDance.JianyingPro
winget install -e --id Bilibili.Bilibili
winget install -e --id CCTV.CBox

winget install -e --id NetEase.CloudMusic # 网易云音乐
winget install -e --id Youdao.YoudaoTranslate # 网易有道翻译

winget install -e --id Baidu.BaiduNetdisk # 百度网盘
winget install -e --id Baidu.BaiduTranslate # 百度翻译

winget install -e --id Alibaba.DingTalk # 钉钉
winget install -e --id Alibaba.aDrive # 阿里云盘

winget install -e --id Tencent.TencentMeeting # 腾讯会议
winget install -e --id Tencent.TencentVideo # 腾讯视频
winget install -e --id Tencent.QQPlayer # QQ影音
winget install -e --id Tencent.YingYongBao # 应用宝
winget install -e --id Tencent.QQMusic
winget install -e --id Tencent.QQ
winget install -e --id Tencent.WeChat
winget install -e --id Tencent.WeType # 微信输入法
winget install -e --id Tencent.WeCom # 企业微信
winget install -e --id Tencent.WeixinDevTools # 微信开发者工具





# 使用 winget 安装 VSCode
Start-Process -Wait -FilePath winget -ArgumentList "install -e --id Microsoft.VisualStudioCode"

# 安装 VSCode 插件
$vscodeExtensions = @(
    "dbaeumer.vscode-eslint"
    "eamodio.gitlens"
    "esbenp.prettier-vscode"
    "ms-azuretools.vscode-docker"
    "ms-python.python"
    "ms-toolsai.jupyter"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode-remote.remote-wsl"
    "ms-vscode-remote.vscode-remote-extensionpack"
    "ms-vscode.cpptools"
    "ms-vscode.node-debug2"
    "ms-vscode.vscode-typescript-tslint-plugin"
    "msjsdiag.debugger-for-chrome"
    "redhat.vscode-yaml"
    "yzhang.markdown-all-in-one"
)

foreach ($vscodeExtension in $vscodeExtensions) {
    Start-Process -Wait -FilePath code -ArgumentList "--install-extension $vscodeExtension"
}


# 使用 winget 安装 Docker Desktop
Start-Process -Wait -FilePath winget -ArgumentList "install -e --id Docker.DockerDesktop --version 4.1.1 --quiet"

# 安装 Docker 插件
$dockerExtensions = @(
    "ms-azuretools.vscode-docker"
)

foreach ($dockerExtension in $dockerExtensions) {
    Start-Process -Wait -FilePath code -ArgumentList "--install-extension $dockerExtension"
}


# 使用 winget 安装 WSL2
Start-Process -Wait -FilePath winget -ArgumentList "install -e --id Microsoft.WSL --version 1.0.0.20210422 --quiet"

# 使用 winget 安装 WSL2 发行版
Start-Process -Wait -FilePath winget -ArgumentList "install -e --id Ubuntu --quiet"


