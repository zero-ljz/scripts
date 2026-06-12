# 1. 定义需要卸载的应用名称关键字（包含了你提到的所有应用以及其他常见冗余应用）
$AppsToRemove = @(
    "OneDrive",              # OneDrive (需要单独额外处理，见下方)
    "Skype",                 # Skype
    "MicrosoftStub",         # 各种游戏占位符（如糖果传奇等手机游戏）
    "SolitaireCollection",   # 微软纸牌集合
    "BingWeather",           # 天气
    "GetHelp",               # 提示 / 获取帮助
    "Getstarted",            # 提示 / 登录欢迎
    "OfficeHub",             # 我的 Office
    "OneNote",               # OneNote for Windows 10
    "People",                # 人脉
    "SkypeApp",              # Skype 现代版
    "YourPhone",             # 手机连接
    "ZuneMusic",             # Groove 音乐
    "ZuneVideo",             # 电影和电视
    "StickyNotes",           # 便签（如果不用可以删，想保留请删掉这一行）
    "FeedbackHub",           # 反馈中心
    "MixedReality.Portal",   # 混合现实门户
    "Xbox",                  # 所有 Xbox 相关组件（不玩游戏可全删）
	"3DViewer",       # 3D查看器 (Microsoft.3DViewer)
    "WindowsMaps",    # 地图 (Microsoft.WindowsMaps)
    "549981C3F5F10"   # Cortana 小娜的官方新型内部 ID
)

# 2. 开始批量卸载当前用户的应用
Write-Host "正在清理当前用户的自带应用..." -ForegroundColor Cyan
foreach ($AppName in $AppsToRemove) {
    Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "*$AppName*"} | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# 3. 阻止这些应用在未来新创建的用户中自动安装
Write-Host "正在阻止新用户自动安装这些应用..." -ForegroundColor Cyan
foreach ($AppName in $AppsToRemove) {
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*$AppName*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# 4. 彻底卸载 OneDrive（因为 OneDrive 不属于 Appx 架构，需要特殊处理）
Write-Host "正在专门卸载 OneDrive..." -ForegroundColor Cyan
# 关闭 OneDrive 进程
taskkill /f /im OneDrive.exe 2>$null
# 针对 64位 或 32位 系统执行自带的卸载程序
if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
    Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" "/uninstall" -NoNewWindow -Wait
} elseif (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
    Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -NoNewWindow -Wait
}

Write-Host "清理完成！建议重启电脑以使完毕生效。" -ForegroundColor Green