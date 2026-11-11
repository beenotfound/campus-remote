$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$log = "$root\logs\setup.log"
function Log($m) { $s = "[$(Get-Date -Format s)] $m"; $s | Out-File $log -Append -Encoding utf8; Write-Host $s }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PSCommandPath"
    exit
}

New-Item -ItemType Directory -Path $root, "$root\Downloads", "$root\scripts", "$root\config", "$root\logs", "$root\docs" -Force | Out-Null
if (-not (Test-Path "$root\config\config.json")) { Copy-Item "$root\config.example.json" "$root\config\config.json" }
Log "=== SETUP START ==="

# ---------------------------------------------------------------
# Sunshine
# ---------------------------------------------------------------
if (-not (Test-Path "$root\Sunshine\sunshine.exe")) {
    $msi = "$root\Downloads\Sunshine-Windows-AMD64-installer.msi"
    if (-not (Test-Path $msi) -or (Get-Item $msi).Length -lt 30000000) {
        $u = 'https://gh-proxy.com/https://github.com/LizardByte/Sunshine/releases/download/v2026.914.233613/Sunshine-Windows-AMD64-installer.msi'
        Log "downloading Sunshine MSI"
        curl.exe -4 -L --retry 5 --retry-delay 2 -C - -o $msi $u 2>&1 | Out-Null
    }
    Log "installing Sunshine to D:"
    $p = Start-Process msiexec.exe -ArgumentList '/i', $msi, '/qn', '/norestart', "INSTALL_ROOT=$root\Sunshine\", '/l*v', "$root\logs\sunshine-install.log" -Wait -PassThru
    Log "Sunshine msi exit=$($p.ExitCode)"
} else {
    Log "Sunshine already installed"
}

# first-run config (only if missing/empty)
$confPath = "$root\Sunshine\config\sunshine.conf"
if (-not (Test-Path $confPath) -or (Get-Item $confPath).Length -eq 0) {
    @(
        'address_family = both',
        'origin_web_ui_allowed = pc',
        'upnp = false',
        'stream_audio = true',
        'min_log_level = info'
    ) | Set-Content $confPath -Encoding utf8
    Log "wrote default sunshine.conf"
}

# ---------------------------------------------------------------
# Tailscale
# ---------------------------------------------------------------
$tsD = "$root\Tailscale\tailscale.exe"
$tsC = 'C:\Program Files\Tailscale\tailscale.exe'
if (-not (Test-Path $tsD) -and -not (Test-Path $tsC)) {
    $tsmsi = "$root\Downloads\tailscale-setup-1.104.6-amd64.msi"
    if (-not (Test-Path $tsmsi) -or (Get-Item $tsmsi).Length -lt 38000000) {
        Log "downloading Tailscale MSI over IPv4"
        curl.exe -4 -L --retry 5 --retry-delay 2 -C - -o $tsmsi 'https://pkgs.tailscale.com/stable/tailscale-setup-1.104.6-amd64.msi' 2>&1 | Out-Null
    }
    Log "installing Tailscale"
    $p = Start-Process msiexec.exe -ArgumentList '/i', $tsmsi, '/qn', '/norestart', "INSTALLDIR=$root\Tailscale\", '/l*v', "$root\logs\tailscale-install.log" -Wait -PassThru
    Log "Tailscale msi exit=$($p.ExitCode)"
} else {
    Log "Tailscale already installed"
}

# ---------------------------------------------------------------
# Firewall / power / tasks (shared with elev-setup2)
# ---------------------------------------------------------------
& "$root\scripts\elev-setup2.ps1" 2>&1 | Out-Null

Log "=== SETUP DONE ==="
""
"安装完成。下一步："
"1. 运行 登录Tailscale.cmd 完成 Tailscale 登录（会打印验证链接）"
"2. 在 iPad 上安装 Tailscale（非国区 App Store）和 Moonlight，登录同一个 Tailscale 账号"
"3. 运行 诊断.cmd 查看电脑的 100.x 地址，在 Moonlight 里添加它"
"4. 运行 配对.cmd，把 iPad 上的 4 位 PIN 输入 Sunshine Web UI"

