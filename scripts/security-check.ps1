$root = Split-Path $PSScriptRoot -Parent
"=== Campus-Remote 安全检查 ==="
""
"1) 防火墙规则（Sunshine 应为 Disabled；Campus-Remote 应只允许 Tailscale 100.64.0.0/10）"
Get-NetFirewallRule -DisplayName 'Campus-Remote *', 'Sunshine' -ErrorAction SilentlyContinue |
    Select-Object DisplayName, Enabled, Direction, Action, Profile |
    Format-Table -AutoSize | Out-String
""
"2) Web UI 来源限制（应为 pc，即仅本机）"
$cred = Get-Content "$root\config\admin.txt" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($cred) {
    $u, $p = $cred -split "`t"
    $conf = curl.exe -sk -u "$u`:$p" https://127.0.0.1:47990/api/config 2>$null
    if ($conf) { "  $conf" }
} else { "  admin.txt 不存在" }
""
"3) Tailscale"
$ts = @("$root\Tailscale\tailscale.exe", 'C:\Program Files\Tailscale\tailscale.exe') |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if ($ts) { & $ts status 2>&1 | Select-Object -First 12 } else { "  未安装" }
""
"4) 本机全局 IPv6（iPad 侧验证用）"
Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue |
    Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike 'fe80::*' -and $_.IPAddress -ne '::1' -and $_.PrefixOrigin -ne 'WellKnown' } |
    ForEach-Object { "  $($_.IPAddress)" }
""
"5) 手动验收（在 iPad 上做）："
"   a. 关掉 iPad 的 Tailscale，用 Safari 访问 http://[上面的全局 IPv6]:47989  → 应该超时/拒绝"
"   b. 关掉 Tailscale，访问 https://[上面的全局 IPv6]:47990 → 应该超时/拒绝"
"   c. 打开 iPad 的 Tailscale，Moonlight 连 100.x 主机 → 应该正常"
"   如果 a/b 能打开，说明防火墙还没收紧，请重新运行 安装.cmd。"
