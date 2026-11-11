$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath"
    exit
}
Start-Service Tailscale -ErrorAction SilentlyContinue
Start-Service SunshineService -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
"已恢复远程访问："
"  Sunshine 服务: $((Get-Service SunshineService -ErrorAction SilentlyContinue).Status)"
"  Tailscale 服务: $((Get-Service Tailscale -ErrorAction SilentlyContinue).Status)"
& "$root\Tailscale\tailscale.exe" status 2>&1 | Select-Object -First 5
