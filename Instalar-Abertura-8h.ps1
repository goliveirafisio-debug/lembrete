$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $appDir 'Abrir-Lembretes.cmd'
$taskName = 'Meus Lembretes - primeiro login do dia'

$action = New-ScheduledTaskAction -Execute $launcher -Argument '-Automatico'
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Get-ScheduledTask -TaskName 'Meus Lembretes - abrir as 8h' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Abre o Mural de Lembretes apenas no primeiro login de cada dia.' -Force | Out-Null
Write-Host 'Instalação concluída: o Mural abrirá no primeiro login de cada dia.'
