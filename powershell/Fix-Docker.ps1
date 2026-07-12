<#
.SYNOPSIS
    一键强制修复并重启 Docker Desktop 与 WSL2 服务
#>

# 1. 自动提升为管理员权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "     Docker & WSL2 一键强制重启修复脚本      " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 2. 强行结束所有 Docker 和相关变态进程
Write-Host "`n[1/4] 正在清理 Docker 及 WSL 残留进程..." -ForegroundColor Cyan
$Processes = @("Docker Desktop", "com.docker.backend", "com.docker.proxy", "vpnkit", "wslhost", "vmmem")
foreach ($proc in $Processes) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
        Write-Host "  已强制结束进程: $proc" -ForegroundColor Green
    }
}

# 3. 强制关闭 WSL
Write-Host "`n[2/4] 正在强制关闭 WSL 实例..." -ForegroundColor Cyan
wsl --shutdown
Write-Host "  WSL 关闭指令已发送。" -ForegroundColor Green

# 4. 修复并重启 LxssManager 服务
Write-Host "`n[3/4] 正在配置并重启 LxssManager 服务..." -ForegroundColor Cyan
# 修改为自动启动
sc.config LxssManager start= auto | Out-Null
# 停止服务（如果还在运行）
net stop LxssManager 2>$null
# 启动服务
$startResult = net start LxssManager 2>&1
if ($LASTEXITCODE -eq 0 -or $startResult -match "已经启动") {
    Write-Host "  LxssManager 服务已成功启动！" -ForegroundColor Green
} else {
    Write-Warning "  LxssManager 启动失败，尝试强行启用虚拟机平台组件..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart | Out-Null
}

# 5. 重新拉起 Docker Desktop
Write-Host "`n[4/4] 正在尝试重新启动 Docker Desktop..." -ForegroundColor Cyan
$DockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $DockerPath) {
    Start-Process $DockerPath
    Write-Host "  Docker Desktop 已在后台拉起，请观察小鲸鱼是否变绿。" -ForegroundColor Green
} else {
    Write-Warning "  未在默认路径找到 Docker Desktop，请手动双击打开。"
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " 修复完成！如果依然卡死，请重启电脑再试。" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Read-Host "按回车键退出..."