$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
"Campus-Remote 诊断  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
"host: $env:COMPUTERNAME   user: $env:USERNAME"

$cfg = Get-Content "$root\config\config.json" -Raw -Encoding utf8 | ConvertFrom-Json
"transport: $($cfg.transport)"

"--- Sunshine ---"
$svc = Get-Service SunshineService
"service: $($svc.Status) / $($svc.StartType)"
"binary : $(Test-Path "$root\Sunshine\sunshine.exe")"
$cred = Get-Content "$root\config\admin.txt" | Select-Object -First 1
if ($cred) {
    $u, $p = $cred -split "`t"
    "admin  : $u （密码见 config\admin.txt）"
    $apiCode = curl.exe -sk -u "$u`:$p" -o NUL -w "%{http_code}" https://127.0.0.1:47990/api/config 2>$null
    "webui  : /api/config -> $apiCode"
    $conf = curl.exe -sk -u "$u`:$p" https://127.0.0.1:47990/api/config 2>$null
    if ($conf) { "config : $conf" }
}

"--- encoders ---"
Select-String -Path "$root\Sunshine\config\sunshine.log" -Pattern 'Found (H\.264|HEVC|AV1) encoder' |
    Select-Object -Last 3 | ForEach-Object { "  $($_.Line.Trim())" }

"--- network ---"
Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue |
    Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike 'fe80::*' -and $_.IPAddress -ne '::1' -and $_.PrefixOrigin -ne 'WellKnown' } |
    ForEach-Object { "  v6: $($_.IPAddress)/$($_.PrefixLength)  [$($_.InterfaceAlias)]" }
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match '^(172\.|10\.)' } |
    ForEach-Object { "  v4: $($_.IPAddress)/$($_.PrefixLength)  [$($_.InterfaceAlias)]" }

"--- tailscale ---"
$ts = @("$root\Tailscale\tailscale.exe", 'C:\Program Files\Tailscale\tailscale.exe') |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if ($ts) {
    & $ts version 2>&1 | ForEach-Object { "  $_" }
    & $ts status 2>&1 | Select-Object -First 20 | ForEach-Object { "  $_" }
} else {
    "  not installed"
}

"--- firewall ---"
Get-NetFirewallRule -DisplayName 'Campus-Remote *', 'Sunshine' |
    Select-Object DisplayName, Enabled, Direction, Action |
    Format-Table -AutoSize | Out-String

"--- scheduled tasks ---"
Get-ScheduledTask -TaskName 'Campus-Remote-*' |
    Select-Object TaskName, State |
    Format-Table -AutoSize | Out-String

"--- power ---"
powercfg /q SCHEME_CURRENT SUB_BUTTONS 2>&1 | Select-String 'LIDACTION' | Select-Object -First 2
powercfg /q SCHEME_CURRENT SUB_SLEEP 2>&1 | Select-String 'RTCWAKE|STANDBYIDLE' | Select-Object -First 4

"--- ddns ---"
$dd = Get-Content "$root\logs\ddns.log" -ErrorAction SilentlyContinue | Select-Object -Last 3
if ($dd) { $dd } else { "  (not configured)" }
