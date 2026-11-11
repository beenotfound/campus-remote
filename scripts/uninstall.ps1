param([switch]$RemoveData)
$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PSCommandPath"
    exit
}
"=== 卸载 Campus-Remote ==="
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Campus-Remote-*' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
"已删除计划任务"
Get-NetFirewallRule -DisplayName 'Campus-Remote *' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
"已删除防火墙规则"

$sun = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq 'Sunshine' } | Select-Object -First 1
if ($sun) {
    "卸载 Sunshine ..."
    Start-Process msiexec.exe -ArgumentList '/x', $sun.PSChildName, '/qn', '/norestart' -Wait
}
$tsPkg = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like 'Tailscale*' } | Select-Object -First 1
if ($tsPkg) {
    "卸载 Tailscale ..."
    Start-Process msiexec.exe -ArgumentList '/x', $tsPkg.PSChildName, '/qn', '/norestart' -Wait
}
if ($RemoveData) {
    Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue
    "已删除 $root"
}
"完成。向日葵未受影响。"
