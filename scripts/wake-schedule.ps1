$root = Split-Path $PSScriptRoot -Parent
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$PSCommandPath"
    exit
}
$cfg = Get-Content "$root\config\config.json" -Raw -Encoding utf8 | ConvertFrom-Json
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Campus-Remote-Wake-*' -or $_.TaskName -like 'Campus-Remote-Sleep-*' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

foreach ($t in $cfg.power.wake) {
    $name = 'Campus-Remote-Wake-' + ($t -replace ':', '')
    $action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c exit'
    $trigger = New-ScheduledTaskTrigger -Daily -At $t
    $settings = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
    "已注册唤醒任务 $name @ $t"
}
foreach ($t in $cfg.power.sleep) {
    $name = 'Campus-Remote-Sleep-' + ($t -replace ':', '')
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\sleep-if-idle.ps1`""
    $trigger = New-ScheduledTaskTrigger -Daily -At $t
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
    "已注册睡眠任务 $name @ $t"
}
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1 2>&1 | Out-Null
powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
""
"当前计划任务："
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Campus-Remote-*' } |
    Select-Object TaskName, State | Format-Table -AutoSize | Out-String
