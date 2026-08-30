Set-StrictMode -Version Latest

function Get-DataPath {
    param([Parameter(Mandatory)][string]$AppDirectory)
    Join-Path $AppDirectory 'lembretes.json'
}

function Read-Lembretes {
    param([Parameter(Mandatory)][string]$DataPath)
    if (-not (Test-Path -LiteralPath $DataPath)) { return @() }
    try {
        $dados = Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $lembretes = @($dados)
        foreach ($lembrete in $lembretes) {
            if ($null -eq $lembrete.PSObject.Properties['Recorrencia']) {
                $lembrete | Add-Member -NotePropertyName Recorrencia -NotePropertyValue 'Nenhuma'
            }
        }
        return $lembretes
    } catch { throw "Nao foi possivel ler os lembretes salvos: $($_.Exception.Message)" }
}

function Save-Lembretes {
    param([Parameter(Mandatory)][object[]]$Lembretes,[Parameter(Mandatory)][string]$DataPath)
    $directory = Split-Path -Parent $DataPath
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporaryPath = "$DataPath.tmp"; $backupPath = "$DataPath.bak"
    $json = $Lembretes | ConvertTo-Json -Depth 5
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $json, [System.Text.UTF8Encoding]::new($false))
        if (Test-Path -LiteralPath $DataPath) { [System.IO.File]::Replace($temporaryPath, $DataPath, $backupPath, $true) }
        else { [System.IO.File]::Move($temporaryPath, $DataPath) }
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}

function Get-NextOccurrence {
    param([Parameter(Mandatory)][datetime]$CurrentDate,[Parameter(Mandatory)][string]$Recurrence,[datetime]$Now = (Get-Date))
    $next = $CurrentDate
    do {
        $next = switch ($Recurrence) {
            'Semanal' { $next.AddDays(7) }; 'Quinzenal' { $next.AddDays(15) }
            'Mensal' { $next.AddMonths(1) }; 'Anual' { $next.AddYears(1) }
            default { return $next }
        }
    } while ($next -le $Now)
    return $next
}

Export-ModuleMember -Function Get-DataPath, Read-Lembretes, Save-Lembretes, Get-NextOccurrence
