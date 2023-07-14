if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    curl -LkOJ http://us.iapp.run:777/proxy/https://github.com/microsoft/winget-cli/releases/download/v1.5.1881/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    powershell -Command "Add-AppPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
}


winget install -e --id OpenJS.NodeJS.LTS
winget install -e --id Python.Python.3.9 --version 3.9.13
winget install -e --id Git.Git
winget install -e --id GitHub.GitHubDesktop
winget install -e --id Microsoft.WindowsTerminal
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


