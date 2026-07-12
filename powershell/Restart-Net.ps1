<#
.SYNOPSIS
    一键自动识别并重启当前正在联网的网络适配器
#>

# 1. 自动提升为管理员权限
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "          当前活动网卡一键快速重启           " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 2. 自动寻找当前有 IPv4 连接的活动网卡
Write-Host "`n[1/3] 正在分析当前活动的网络适配器..." -ForegroundColor Cyan
$ActiveAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (-not $ActiveAdapter) {
    Write-Error "未找到处于联网状态的网卡！"
    Read-Host "按回车键退出..."
    Exit
}

$AdapterName = $ActiveAdapter.Name
$AdapterInterface = $ActiveAdapter.InterfaceDescription
Write-Host "  锁定目标网卡: $AdapterName ($AdapterInterface)" -ForegroundColor Green

# 3. 禁用网卡
Write-Host "`n[2/3] 正在禁用网卡..." -ForegroundColor Cyan
Disable-NetAdapter -Name $AdapterName -Confirm:$false
Write-Host "  网卡已关闭，断开网络连接。" -ForegroundColor Yellow

# 延迟 2 秒确保硬件状态切换完成
Start-Sleep -Seconds 2

# 4. 重新启用网卡
Write-Host "`n[3/3] 正在重新启用网卡..." -ForegroundColor Cyan
Enable-NetAdapter -Name $AdapterName -Confirm:$false
Write-Host "  网卡已重新启用！正在获取 IP 地址..." -ForegroundColor Green

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host " 网络适配器重启完成！网络将在几秒内恢复。" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Start-Sleep -Seconds 3