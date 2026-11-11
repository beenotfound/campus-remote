$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath"
    exit
}
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -like 'Campus-Remote-Wake-*' -or $_.TaskName -like 'Campus-Remote-Sleep-*' }
foreach ($t in $tasks) {
    Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false -ErrorAction SilentlyContinue
    "已删除 $($t.TaskName)"
}
"[$(Get-Date -Format s)] disabled auto wake/sleep" | Out-File "$root\logs\schedule.log" -Append -Encoding utf8
""
"自动唤醒/自动睡眠已关闭。"
"电脑不会自己醒、也不会自己睡；需要定时功能时运行 恢复自动唤醒.cmd。"
