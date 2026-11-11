param([switch]$InstallTask, [switch]$RemoveTask)
$root = Split-Path $PSScriptRoot -Parent
$log = "$root\logs\ddns.log"
$cfg = Get-Content "$root\config\config.json" -Raw -Encoding utf8 | ConvertFrom-Json
$sub = $cfg.direct.duckdnsSubdomain
$tok = $cfg.direct.duckdnsToken

if ($RemoveTask) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath",'-RemoveTask'; exit }
    Unregister-ScheduledTask -TaskName 'Campus-Remote-DDNS' -Confirm:$false -ErrorAction SilentlyContinue
    "已删除 DDNS 计划任务"
    exit
}

if (-not $sub -or -not $tok) {
    "config.json 里的 direct.duckdnsSubdomain / direct.duckdnsToken 为空。"
    "去 https://www.duckdns.org 注册一个随机子域名，把子域名和 token 填进配置后重试。"
    exit 1
}

$routeIf = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Sort-Object RouteMetric | Select-Object -First 1).ifIndex
$v6 = (Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue |
    Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike 'fe80::*' -and $_.IPAddress -ne '::1' -and $_.PrefixOrigin -ne 'WellKnown' -and ($null -eq $routeIf -or $_.InterfaceIndex -eq $routeIf) } |
    Select-Object -First 1).IPAddress
if (-not $v6) {
    $v6 = (Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue |
        Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike 'fe80::*' -and $_.IPAddress -ne '::1' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1).IPAddress
}
$v4 = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and ($null -eq $routeIf -or $_.InterfaceIndex -eq $routeIf) } |
    Select-Object -First 1).IPAddress
if (-not $v6) { "没有找到全局 IPv6 地址（直连兜底需要 IPv6）"; exit 1 }

$uri = "https://www.duckdns.org/update?domains=$sub&token=$tok&ipv6=$v6&ip=$v4"
try {
    $r = Invoke-RestMethod -Uri $uri -TimeoutSec 20
    $line = "[$(Get-Date -Format s)] sub=$sub v6=$v6 v4=$v4 result=$r"
    $line | Out-File $log -Append -Encoding utf8
    $line
} catch {
    "[$(Get-Date -Format s)] update failed: $($_.Exception.Message)" | Out-File $log -Append -Encoding utf8
    "更新失败：$($_.Exception.Message)"
}

if ($InstallTask) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath",'-InstallTask'
        exit
    }
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\ddns.ps1`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
    Register-ScheduledTask -TaskName 'Campus-Remote-DDNS' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
    "已注册 DDNS 计划任务（每 5 分钟）"
}
