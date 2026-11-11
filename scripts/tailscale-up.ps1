$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PSCommandPath"
    exit
}
$ts = @("$root\Tailscale\tailscale.exe", 'C:\Program Files\Tailscale\tailscale.exe') |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ts) {
    "未找到 Tailscale，请先运行 安装.cmd"
    exit 1
}
"$ts" | Out-File "$root\logs\tailscale-path.txt" -Encoding utf8
"=== 启动 Tailscale 登录（会打印一个验证链接）==="
& $ts up --unattended 2>&1 | Tee-Object "$root\logs\tailscale-up.log"
""
"=== 状态 ==="
& $ts status 2>&1
""
$ip = (& $ts ip -4 2>$null) -join ''
if ($ip) {
    "电脑 Tailscale IP: $ip"
    $cfgPath = "$root\config\config.json"
    $cfg = Get-Content $cfgPath -Raw -Encoding utf8 | ConvertFrom-Json
    $cfg.tailscale.ip = $ip.Trim()
    $cfg.tailscale.installed = $true
    $cfg | ConvertTo-Json -Depth 6 | Set-Content $cfgPath -Encoding utf8
    "已写入 config.json"
}
""
"=== 允许当前用户使用 tailscale 命令 ==="
& $ts set --operator=$env:USERNAME 2>&1
