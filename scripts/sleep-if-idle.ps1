$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$logPath = "$root\logs\sleep.log"
$sunLog = "$root\Sunshine\config\sunshine.log"
function Log($m) { "[$(Get-Date -Format s)] $m" | Out-File $logPath -Append -Encoding utf8 }

function Test-ActiveStream {
    $ad = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'Tailscale' } | Select-Object -First 1
    if (-not $ad) { return $false }
    $s1 = Get-NetAdapterStatistics -Name $ad.Name -ErrorAction SilentlyContinue
    if (-not $s1) { return $false }
    Start-Sleep -Seconds 5
    $s2 = Get-NetAdapterStatistics -Name $ad.Name -ErrorAction SilentlyContinue
    if (-not $s2) { return $false }
    $delta = ($s2.ReceivedBytes - $s1.ReceivedBytes) + ($s2.SentBytes - $s1.SentBytes)
    if ($delta -gt 300000) {
        Log "tail traffic ${delta}B/5s -> stream active"
        return $true
    }
    return $false
}

Log "sleep-if-idle: start"
$deadline = (Get-Date).AddHours(4)
while ((Get-Date) -lt $deadline) {
    $active = $false
    if (Test-Path $sunLog) {
        $age = (Get-Date) - (Get-Item $sunLog).LastWriteTime
        if ($age.TotalSeconds -lt 30) { $active = $true }
    }
    $tcp = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Where-Object { $_.RemoteAddress -like '100.*' -and $_.RemotePort -in 47984, 47989, 48010 }
    if ($tcp) { $active = $true }
    if (-not $active) { $active = Test-ActiveStream }
    if (-not $active) { break }
    Start-Sleep -Seconds 60
}
Log "no active stream, going to sleep"
rundll32.exe powrprof.dll,SetSuspendState 0,1,0
Log "sleep command issued"
