$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath"
    exit
}
Get-NetFirewallRule -DisplayName 'Campus-Remote *' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Campus-Remote TCP' -Direction Inbound -Protocol TCP -LocalPort 47984, 47989, 48010 -RemoteAddress '100.64.0.0/10' -Action Allow -Profile Any | Out-Null
New-NetFirewallRule -DisplayName 'Campus-Remote UDP' -Direction Inbound -Protocol UDP -LocalPort '47998-48002' -RemoteAddress '100.64.0.0/10' -Action Allow -Profile Any | Out-Null
"[$(Get-Date -Format s)] firewall hardened to Tailscale-only" | Out-File "$root\logs\firewall.log" -Append -Encoding utf8
Get-NetFirewallRule -DisplayName 'Campus-Remote *' | ForEach-Object {
    $af = $_ | Get-NetFirewallAddressFilter
    "$($_.DisplayName) remote=$($af.RemoteAddress -join ', ')"
}
