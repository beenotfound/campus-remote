$root = Split-Path $PSScriptRoot -Parent
$cred = Get-Content "$root\config\admin.txt" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $cred) {
    "找不到 $root\config\admin.txt，请先运行安装脚本。"
    exit 1
}
$u, $p = $cred -split "`t"
"=== Sunshine 配对 ==="
"Web UI : https://127.0.0.1:47990"
"账号   : $u"
"密码   : 见 config\admin.txt"
""
"步骤："
"1. iPad 打开 Moonlight，添加电脑（Tailscale 的 100.x 地址，或直连模式的 DuckDNS 域名）"
"2. iPad 会显示 4 位 PIN"
"3. 在电脑浏览器打开 https://127.0.0.1:47990，输入账号密码（密码见 config\admin.txt）登录"
"4. 点导航栏 PIN，输入 4 位 PIN，点发送"
"5. 回到 Moonlight，选 Desktop 开始串流"
""
Start-Process 'https://127.0.0.1:47990'
Start-Sleep -Seconds 1
Start-Process 'https://127.0.0.1:47990/pin'

