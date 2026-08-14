$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $appDir 'Abrir-Lembretes.cmd'
$taskName = 'Meus Lembretes - abrir as 8h'

$action = New-ScheduledTaskAction -Execute $launcher
$trigger = New-ScheduledTaskTrigger -Daily -At '08:00'
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Abre o programa Meus Lembretes todos os dias às 8h.' -Force | Out-Null
Write-Host 'Instalação concluída: o programa abrirá diariamente às 08:00.'

