# 安装 winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    curl -LkOJ https://p.520999.xyz/https://github.com/microsoft/winget-cli/releases/download/v1.5.1881/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    powershell -Command "Add-AppPackage -Path Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
}

# winget install -e --id SomePythonThings.WingetUIStore
# winget install -e --id Microsoft.Teams.Free
# winget install -e --id Microsoft.WindowsPCHealthCheck
# winget install -e --id Microsoft.MouseandKeyboardCenter
winget install -e --id 9NBLGGH5R558 # To Do
winget install -e --id 9MSPC6MP8FM4 # Whiteboard

# 安装 Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

winget install -e --id OpenJS.NodeJS.LTS  --version 18.20.2
# 配置国内源
npm config set registry https://registry.npmmirror.com
# 安装pnpm
npm install -g pnpm

winget install -e --id Python.Python.3.10 --version 3.10.11
# 配置国内源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# 安装pipx
pip install --user pipx
# 自动添加到用户环境变量Path
python -m pipx ensurepath
# 在隔离环境中安装poetry
python -m pipx install poetry==1.8.3


winget install -e --id Git.Git
# 配置用户信息
git config --global user.name 'zero-ljz'
git config --global user.email '2267719005@qq.com'

winget install -e --id GitHub.GitHubDesktop
# winget install -e --id Microsoft.WindowsTerminal
winget install -e --id Microsoft.PowerToys
# winget install -e --id Microsoft.BingWallpaper
# winget install -e --id CosmoX.Lepton
winget install -e --id AutoHotkey.AutoHotkey --version 1.1.37.01

# winget install -e --id Sandboxie.Plus
# winget install -e --id Telegram.TelegramDesktop

winget install -e --id Postman.Postman
winget install -e --id Telerik.Fiddler.Classic
# winget install -e --id JavadMotallebi.NeatDownloadManager # 提示找不到包
# winget install -e --id WinSCP.WinSCP
# winget install -e --id c0re100.qBittorrent-Enhanced-Edition
winget install -e --id voidtools.Everything
winget install -e --id SublimeHQ.SublimeText.4

winget install -e --id PremiumSoft.NavicatPremium
winget install -e --id AdrienAllard.FileConverter
# winget install -e --id DeepL.DeepL # 提示安装程序哈希不匹配: 以管理员身份运行时不能覆盖此内容
winget install -e --id Anki.Anki
winget install -e --id Xmind.Xmind

# winget install -e --id MariaDB.Server --version 10.4.30

winget install -e --id VideoLAN.VLC
# winget install -e --id TeamViewer.TeamViewer
# winget install -e --id Youqu.ToDesk
# winget install -e --id VMware.WorkstationPro
winget install -e --id Notion.Notion
winget install -e --id Obsidian.Obsidian
# winget install -e --id HTTPie.HTTPie
winget install -e --id Insomnia.Insomnia
# winget install -e --id ElectronCommunity.ElectronFiddle # 刚安装完就提示有更新
# winget install -e --id Cloudflare.Warp
# winget install -e --id Mubu.Mubu # 幕布, 安装时提示执行InternetOpenUrl命令失败
# winget install -e --id shimo.shimo
winget install -e --id Automattic.Simplenote
# winget install -e --id Joplin.Joplin
# winget install -e --id Dropbox.Dropbox


# winget install -e --id MariaDB.Server --version 10.6.17
# winget install -e --id Oracle.MySQLShell
# winget install -e --id Oracle.MySQLWorkbench
winget install -e --id 7zip.7zip
winget install -e --id Bandisoft.Bandizip --version 6.29
winget install -e --id Bandisoft.Honeyview
# winget install -e --id BlueStack.BlueStacks --version 5.20.0.1037

# winget install -e --id ByteDance.StreamingTool # 直播伴侣
# winget install -e --id ByteDance.Douyin
# winget install -e --id ByteDance.JianyingPro
# winget install -e --id Bilibili.Bilibili
# winget install -e --id CCTV.CBox

winget install -e --id NetEase.CloudMusic # 网易云音乐
winget install -e --id Youdao.YoudaoTranslate # 网易有道翻译
winget install -e --id 360.360Chrome.X

# winget install -e --id Baidu.BaiduNetdisk # 百度网盘, 包370m, 装完还添加了广告的开机自启
winget install -e --id Baidu.BaiduTranslate # 百度翻译

# winget install -e --id Alibaba.DingTalk # 钉钉, 会设置开机自启, 并且卸载之后会留下无效的开机启动项
winget install -e --id Alibaba.aDrive # 阿里云盘

winget install -e --id Tencent.TencentMeeting # 腾讯会议
# winget install -e --id Tencent.TencentVideo # 腾讯视频
winget install -e --id Tencent.QQPlayer # QQ影音
# winget install -e --id Tencent.YingYongBao # 应用宝
winget install -e --id Tencent.QQMusic
winget install -e --id Tencent.QQ
winget install -e --id Tencent.WeChat
winget install -e --id Tencent.WeType # 微信输入法
# winget install -e --id Tencent.WeCom # 企业微信
# winget install -e --id Tencent.WeixinDevTools # 微信开发者工具

winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Docker.DockerDesktop --version 4.1.1 --quiet


# 安装 Docker 插件
# $dockerExtensions = @(
#     "ms-azuretools.vscode-docker"
# )

# foreach ($dockerExtension in $dockerExtensions) {
#     Start-Process -Wait -FilePath code -ArgumentList "--install-extension $dockerExtension"
# }


winget install -e --id Microsoft.WSL --version 1.0.0.20210422 --quiet # 安装 WSL2
winget install -e --id Ubuntu --quiet # 使用 winget 安装 WSL2 发行版
# wsl --install --distribution Debian