$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath"
    exit
}
Stop-Service SunshineService -Force -ErrorAction SilentlyContinue
Stop-Service Tailscale -Force -ErrorAction SilentlyContinue
"已暂停远程访问："
"  Sunshine 服务: $((Get-Service SunshineService -ErrorAction SilentlyContinue).Status)"
"  Tailscale 服务: $((Get-Service Tailscale -ErrorAction SilentlyContinue).Status)"
"现在这台电脑只能在本机操作，远程（包括 iPad）连不进来。"
"恢复请运行 恢复远程访问.cmd"
