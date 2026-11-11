$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$log = "$root\logs\elev-setup2.log"
function Log($m) { $s = "[$(Get-Date -Format s)] $m"; $s | Out-File $log -Append -Encoding utf8; Write-Host $s }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PSCommandPath"
    exit
}

Log "=== START ==="

# 1. Kill stuck online installer
Get-Process 'tailscale-setup-1.104.6' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Log "killed tailscale-setup processes"

# 2. Install Tailscale from MSI
$msi = "$root\Downloads\tailscale-setup-1.104.6-amd64.msi"
$tsD = "$root\Tailscale\tailscale.exe"
$tsC = 'C:\Program Files\Tailscale\tailscale.exe'
if ((Test-Path $msi) -and -not (Test-Path $tsD) -and -not (Test-Path $tsC)) {
    $size = (Get-Item $msi).Length
    Log "MSI size=$size"
    if ($size -ge 38000000) {
        try {
            $p = Start-Process msiexec.exe -ArgumentList '/i', $msi, '/qn', '/norestart', "INSTALLDIR=$root\Tailscale\", '/l*v', "$root\logs\tailscale-install.log" -Wait -PassThru
            Log "msiexec exit=$($p.ExitCode)"
        } catch { Log "msiexec failed: $($_.Exception.Message)" }
    } else {
        Log "MSI not fully downloaded yet"
    }
} else {
    Log "Tailscale already installed or MSI missing (D=$(Test-Path $tsD), C=$(Test-Path $tsC), msi=$(Test-Path $msi))"
}
Log "Tailscale: D=$(Test-Path $tsD) C=$(Test-Path $tsC)"
$tsSvc = Get-Service Tailscale -ErrorAction SilentlyContinue
if ($tsSvc) { Log "Tailscale service: $($tsSvc.Status)/$($tsSvc.StartType)" } else { Log "Tailscale service: missing" }

# 3. Restart Sunshine
try { Restart-Service SunshineService -Force -ErrorAction Stop; Log "Sunshine restarted" } catch { Log "Sunshine restart failed: $($_.Exception.Message)" }

# 4. Firewall
try {
    Get-NetFirewallRule -DisplayName 'Sunshine' -ErrorAction SilentlyContinue | Disable-NetFirewallRule -ErrorAction SilentlyContinue
    Get-NetFirewallRule -DisplayName 'Campus-Remote *' -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    $remote = @('100.64.0.0/10')
    New-NetFirewallRule -DisplayName 'Campus-Remote TCP' -Direction Inbound -Protocol TCP -LocalPort 47984, 47989, 48010 -RemoteAddress $remote -Action Allow -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName 'Campus-Remote UDP' -Direction Inbound -Protocol UDP -LocalPort '47998-48002' -RemoteAddress $remote -Action Allow -Profile Any | Out-Null
    Log "firewall scoped rules added"
} catch { Log "firewall failed: $($_.Exception.Message)" }

# 5. Power
try {
    powercfg /change monitor-timeout-ac 10 2>&1 | Out-Null
    powercfg /change standby-timeout-ac 0 2>&1 | Out-Null
    powercfg /hibernate off 2>&1 | Out-Null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0 2>&1 | Out-Null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1 2>&1 | Out-Null
    powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
    Log "power applied"
} catch { Log "power failed: $($_.Exception.Message)" }

Log "=== DONE ==="

