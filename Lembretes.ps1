Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataFile = Join-Path $appDir 'lembretes.json'
$script:lembretes = @()
$script:avisados = [System.Collections.Generic.HashSet[string]]::new()

function Carregar-Lembretes {
    if (Test-Path -LiteralPath $dataFile) {
        try {
            $dados = Get-Content -LiteralPath $dataFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $dados) { $script:lembretes = @($dados) }
        } catch {
            [System.Windows.Forms.MessageBox]::Show('Não foi possível ler os lembretes salvos.', 'Lembretes', 'OK', 'Warning') | Out-Null
        }
    }
}

function Salvar-Lembretes {
    $script:lembretes | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $dataFile -Encoding UTF8
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Meus Lembretes'
$form.Size = New-Object System.Drawing.Size(860, 590)
$form.MinimumSize = New-Object System.Drawing.Size(760, 500)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$titulo = New-Object System.Windows.Forms.Label
$titulo.Text = 'Meus Lembretes'
$titulo.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 22)
$titulo.ForeColor = [System.Drawing.Color]::FromArgb(31, 41, 55)
$titulo.Location = New-Object System.Drawing.Point(24, 18)
$titulo.AutoSize = $true
$form.Controls.Add($titulo)

$subtitulo = New-Object System.Windows.Forms.Label
$subtitulo.Text = 'Crie seus lembretes e receba o aviso na data e hora escolhidas.'
$subtitulo.ForeColor = [System.Drawing.Color]::FromArgb(90, 101, 117)
$subtitulo.Location = New-Object System.Drawing.Point(28, 62)
$subtitulo.AutoSize = $true
$form.Controls.Add($subtitulo)

$btnCriar = New-Object System.Windows.Forms.Button
$btnCriar.Text = '+ Criar lembrete'
$btnCriar.Size = New-Object System.Drawing.Size(165, 42)
$btnCriar.Location = New-Object System.Drawing.Point(650, 24)
$btnCriar.Anchor = 'Top,Right'
$btnCriar.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnCriar.ForeColor = [System.Drawing.Color]::White
$btnCriar.FlatStyle = 'Flat'
$btnCriar.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnCriar)

$lista = New-Object System.Windows.Forms.ListView
$lista.Location = New-Object System.Drawing.Point(28, 105)
$lista.Size = New-Object System.Drawing.Size(787, 370)
$lista.Anchor = 'Top,Bottom,Left,Right'
$lista.View = 'Details'
$lista.FullRowSelect = $true
$lista.GridLines = $false
$lista.HideSelection = $false
$lista.Columns.Add('Lembrete', 355) | Out-Null
$lista.Columns.Add('Prioridade', 110) | Out-Null
$lista.Columns.Add('Data e hora', 190) | Out-Null
$lista.Columns.Add('Status', 95) | Out-Null
$form.Controls.Add($lista)

$btnConcluir = New-Object System.Windows.Forms.Button
$btnConcluir.Text = 'Marcar como concluído'
$btnConcluir.Size = New-Object System.Drawing.Size(195, 38)
$btnConcluir.Location = New-Object System.Drawing.Point(28, 492)
$btnConcluir.Anchor = 'Bottom,Left'
$form.Controls.Add($btnConcluir)

$btnExcluir = New-Object System.Windows.Forms.Button
$btnExcluir.Text = 'Excluir selecionado'
$btnExcluir.Size = New-Object System.Drawing.Size(170, 38)
$btnExcluir.Location = New-Object System.Drawing.Point(235, 492)
$btnExcluir.Anchor = 'Bottom,Left'
$form.Controls.Add($btnExcluir)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'O programa verifica os lembretes enquanto estiver aberto.'
$status.ForeColor = [System.Drawing.Color]::FromArgb(90, 101, 117)
$status.Location = New-Object System.Drawing.Point(425, 502)
$status.Size = New-Object System.Drawing.Size(390, 30)
$status.Anchor = 'Bottom,Left,Right'
$status.TextAlign = 'MiddleRight'
$form.Controls.Add($status)

function Atualizar-Lista {
    $lista.Items.Clear()
    $ordem = @{ 'Alta' = 0; 'Média' = 1; 'Baixa' = 2 }
    $itens = $script:lembretes | Sort-Object @{ Expression = { if ($_.Concluido) { 1 } else { 0 } } }, @{ Expression = { [datetime]$_.DataHora } }, @{ Expression = { $ordem[$_.Prioridade] } }
    foreach ($lem in $itens) {
        $quando = [datetime]$lem.DataHora
        $item = New-Object System.Windows.Forms.ListViewItem([string]$lem.Texto)
        $item.SubItems.Add([string]$lem.Prioridade) | Out-Null
        $item.SubItems.Add($quando.ToString('dd/MM/yyyy HH:mm')) | Out-Null
        $item.SubItems.Add($(if ($lem.Concluido) { 'Concluído' } else { 'Pendente' })) | Out-Null
        $item.Tag = $lem.Id
        if ($lem.Concluido) {
            $item.ForeColor = [System.Drawing.Color]::Gray
        } elseif ($lem.Prioridade -eq 'Alta') {
            $item.BackColor = [System.Drawing.Color]::FromArgb(254, 226, 226)
        } elseif ($lem.Prioridade -eq 'Média') {
            $item.BackColor = [System.Drawing.Color]::FromArgb(254, 249, 195)
        } else {
            $item.BackColor = [System.Drawing.Color]::FromArgb(220, 252, 231)
        }
        $lista.Items.Add($item) | Out-Null
    }
    $status.Text = "$(@($script:lembretes | Where-Object { -not $_.Concluido }).Count) lembrete(s) pendente(s)"
}

function Abrir-Criacao {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Criar lembrete'
    $dialog.Size = New-Object System.Drawing.Size(500, 370)
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.StartPosition = 'CenterParent'
    $dialog.Font = New-Object System.Drawing.Font('Segoe UI', 10)

    $lblTexto = New-Object System.Windows.Forms.Label
    $lblTexto.Text = 'O que você quer lembrar?'
    $lblTexto.Location = New-Object System.Drawing.Point(25, 22)
    $lblTexto.AutoSize = $true
    $dialog.Controls.Add($lblTexto)

    $txtTexto = New-Object System.Windows.Forms.TextBox
    $txtTexto.Location = New-Object System.Drawing.Point(28, 49)
    $txtTexto.Size = New-Object System.Drawing.Size(425, 70)
    $txtTexto.Multiline = $true
    $dialog.Controls.Add($txtTexto)

    $lblPrioridade = New-Object System.Windows.Forms.Label
    $lblPrioridade.Text = 'Prioridade'
    $lblPrioridade.Location = New-Object System.Drawing.Point(25, 137)
    $lblPrioridade.AutoSize = $true
    $dialog.Controls.Add($lblPrioridade)

    $cmbPrioridade = New-Object System.Windows.Forms.ComboBox
    $cmbPrioridade.Location = New-Object System.Drawing.Point(28, 164)
    $cmbPrioridade.Size = New-Object System.Drawing.Size(180, 30)
    $cmbPrioridade.DropDownStyle = 'DropDownList'
    [void]$cmbPrioridade.Items.AddRange(@('Alta', 'Média', 'Baixa'))
    $cmbPrioridade.SelectedIndex = 1
    $dialog.Controls.Add($cmbPrioridade)

    $lblData = New-Object System.Windows.Forms.Label
    $lblData.Text = 'Dia e horário'
    $lblData.Location = New-Object System.Drawing.Point(230, 137)
    $lblData.AutoSize = $true
    $dialog.Controls.Add($lblData)

    $dataHora = New-Object System.Windows.Forms.DateTimePicker
    $dataHora.Location = New-Object System.Drawing.Point(233, 164)
    $dataHora.Size = New-Object System.Drawing.Size(220, 30)
    $dataHora.Format = 'Custom'
    $dataHora.CustomFormat = 'dd/MM/yyyy  HH:mm'
    $dataHora.Value = (Get-Date).AddHours(1)
    $dialog.Controls.Add($dataHora)

    $btnSalvar = New-Object System.Windows.Forms.Button
    $btnSalvar.Text = 'Salvar lembrete'
    $btnSalvar.Location = New-Object System.Drawing.Point(276, 250)
    $btnSalvar.Size = New-Object System.Drawing.Size(177, 42)
    $btnSalvar.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
    $btnSalvar.ForeColor = [System.Drawing.Color]::White
    $btnSalvar.FlatStyle = 'Flat'
    $dialog.Controls.Add($btnSalvar)

    $btnCancelar = New-Object System.Windows.Forms.Button
    $btnCancelar.Text = 'Cancelar'
    $btnCancelar.Location = New-Object System.Drawing.Point(155, 250)
    $btnCancelar.Size = New-Object System.Drawing.Size(110, 42)
    $btnCancelar.DialogResult = 'Cancel'
    $dialog.Controls.Add($btnCancelar)

    $btnSalvar.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtTexto.Text)) {
            [System.Windows.Forms.MessageBox]::Show('Digite o texto do lembrete.', 'Campo obrigatório', 'OK', 'Information') | Out-Null
            return
        }
        if ($dataHora.Value -lt (Get-Date).AddMinutes(-1)) {
            [System.Windows.Forms.MessageBox]::Show('Escolha uma data e hora futuras.', 'Data inválida', 'OK', 'Information') | Out-Null
            return
        }
        $script:lembretes += [pscustomobject]@{
            Id = [guid]::NewGuid().ToString()
            Texto = $txtTexto.Text.Trim()
            Prioridade = [string]$cmbPrioridade.SelectedItem
            DataHora = $dataHora.Value.ToString('o')
            Concluido = $false
        }
        Salvar-Lembretes
        Atualizar-Lista
        $dialog.DialogResult = 'OK'
        $dialog.Close()
    })
    $dialog.AcceptButton = $btnSalvar
    $dialog.CancelButton = $btnCancelar
    $txtTexto.Focus()
    $dialog.ShowDialog($form) | Out-Null
}

$btnCriar.Add_Click({ Abrir-Criacao })

$btnConcluir.Add_Click({
    if ($lista.SelectedItems.Count -eq 0) { return }
    $id = [string]$lista.SelectedItems[0].Tag
    foreach ($lem in $script:lembretes) { if ($lem.Id -eq $id) { $lem.Concluido = $true } }
    Salvar-Lembretes
    Atualizar-Lista
})

$btnExcluir.Add_Click({
    if ($lista.SelectedItems.Count -eq 0) { return }
    $id = [string]$lista.SelectedItems[0].Tag
    $resp = [System.Windows.Forms.MessageBox]::Show('Excluir o lembrete selecionado?', 'Confirmar exclusão', 'YesNo', 'Question')
    if ($resp -eq 'Yes') {
        $script:lembretes = @($script:lembretes | Where-Object { $_.Id -ne $id })
        Salvar-Lembretes
        Atualizar-Lista
    }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 15000
$timer.Add_Tick({
    $agora = Get-Date
    foreach ($lem in @($script:lembretes | Where-Object { -not $_.Concluido })) {
        if ([datetime]$lem.DataHora -le $agora -and -not $script:avisados.Contains([string]$lem.Id)) {
            [void]$script:avisados.Add([string]$lem.Id)
            $form.WindowState = 'Normal'
            $form.Show()
            $form.Activate()
            $form.TopMost = $true
            [System.Windows.Forms.MessageBox]::Show($form, "$($lem.Texto)`n`nPrioridade: $($lem.Prioridade)", 'Hora do lembrete!', 'OK', 'Information') | Out-Null
            $form.TopMost = $false
        }
    }
})

Carregar-Lembretes
Atualizar-Lista
$timer.Start()
[System.Windows.Forms.Application]::Run($form)

