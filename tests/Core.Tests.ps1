$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\Lembretes.Core.psm1') -Force
function Assert-Equal { param($Actual,$Expected,[string]$Message) if ($Actual -ne $Expected) { throw "Falhou: $Message. Esperado '$Expected', recebido '$Actual'." } }
function Assert-True { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw "Falhou: $Message." } }
$reference = [datetime]'2026-08-30T12:00:00'
Assert-Equal (Get-NextOccurrence -CurrentDate ([datetime]'2026-08-28T08:00:00') -Recurrence 'Semanal' -Now $reference) ([datetime]'2026-09-04T08:00:00') 'recorrencia semanal'
Assert-Equal (Get-NextOccurrence -CurrentDate ([datetime]'2026-08-01T08:00:00') -Recurrence 'Mensal' -Now $reference) ([datetime]'2026-09-01T08:00:00') 'recorrencia mensal'
Assert-Equal (Get-NextOccurrence -CurrentDate ([datetime]'2026-08-30T08:00:00') -Recurrence 'Nenhuma' -Now $reference) ([datetime]'2026-08-30T08:00:00') 'sem recorrencia preserva a data'
$tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('mural-lembretes-tests-' + [guid]::NewGuid())
[System.IO.Directory]::CreateDirectory($tempDirectory) | Out-Null
try {
    $dataPath = Get-DataPath -AppDirectory $tempDirectory
    $item = [pscustomobject]@{ Id='1'; Texto='Teste'; Prioridade='Alta'; DataHora='2026-08-31T08:00:00.0000000'; Recorrencia='Nenhuma'; Concluido=$false }
    Save-Lembretes -Lembretes @($item) -DataPath $dataPath
    $loaded = @(Read-Lembretes -DataPath $dataPath)
    Assert-Equal $loaded.Count 1 'salva um lembrete'; Assert-Equal $loaded[0].Texto 'Teste' 'preserva o texto'; Assert-True (Test-Path -LiteralPath $dataPath) 'cria o arquivo de dados'
} finally { Remove-Item -LiteralPath $tempDirectory -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host 'Core tests: approved.'
