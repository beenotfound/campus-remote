$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath"
    exit
}
$cfg = Get-Content "$root\config\config.json" -Raw -Encoding utf8 | ConvertFrom-Json
$remote = @('100.64.0.0/10') + @($cfg.direct.allowedPrefixes)
Get-NetFirewallRule -DisplayName 'Campus-Remote *' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Campus-Remote TCP' -Direction Inbound -Protocol TCP -LocalPort 47984, 47989, 48010 -RemoteAddress $remote -Action Allow -Profile Any | Out-Null
New-NetFirewallRule -DisplayName 'Campus-Remote UDP' -Direction Inbound -Protocol UDP -LocalPort '47998-48002' -RemoteAddress $remote -Action Allow -Profile Any | Out-Null
"已放开校园直连白名单："
$remote | ForEach-Object { "  $_" }
"[$(Get-Date -Format s)] campus direct enabled: $($remote -join ', ')" | Out-File "$root\logs\firewall.log" -Append -Encoding utf8
