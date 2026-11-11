$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$log = "$root\logs\update-sleep-tasks.log"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath"
    exit
}
function Log($m) { "[$(Get-Date -Format s)] $m" | Out-File $log -Append -Encoding utf8 }

$cfg = Get-Content "$root\config\config.json" -Raw -Encoding utf8 | ConvertFrom-Json
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Campus-Remote-Sleep-*' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

foreach ($t in $cfg.power.sleep) {
    $name = 'Campus-Remote-Sleep-' + ($t -replace ':', '')
    try {
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$root\scripts\sleep-if-idle.ps1`""
        $trigger = New-ScheduledTaskTrigger -Daily -At $t
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 8)
        Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest -Force -ErrorAction Stop | Out-Null
        Log "OK sleep-if-idle $name @ $t"
    } catch { Log "FAIL $name : $($_.Exception.Message)" }
}
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Campus-Remote-Sleep-*' } |
    ForEach-Object { Log "  $($_.TaskName) [$($_.State)]" }
Log "done"
