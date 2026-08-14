Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class IdentidadeLembretes {
    [DllImport("shell32.dll", SetLastError = true)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appID);
}
"@
[void][IdentidadeLembretes]::SetCurrentProcessExplicitAppUserModelID('Gustavo.MuralDeLembretes')
[System.Windows.Media.RenderOptions]::ProcessRenderMode = [System.Windows.Interop.RenderMode]::SoftwareOnly

$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataFile = Join-Path $appDir 'lembretes.json'
$script:lembretes = @()
$script:avisados = [System.Collections.Generic.HashSet[string]]::new()

function Carregar-Lembretes {
    if (Test-Path -LiteralPath $dataFile) {
        try {
            $dados = Get-Content -LiteralPath $dataFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $dados) {
                $script:lembretes = @($dados)
                foreach ($lem in $script:lembretes) {
                    if ($null -eq $lem.PSObject.Properties['Recorrencia']) {
                        $lem | Add-Member -NotePropertyName Recorrencia -NotePropertyValue 'Nenhuma'
                    }
                }
            }
        } catch {
            [System.Windows.MessageBox]::Show('Não foi possível ler os lembretes salvos.', 'Mural') | Out-Null
        }
    }
}

function Salvar-Lembretes {
    $script:lembretes | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $dataFile -Encoding UTF8
}

function Obter-ProximaData([datetime]$dataAtual, [string]$recorrencia) {
    $proxima = $dataAtual
    do {
        $proxima = switch ($recorrencia) {
            'Semanal' { $proxima.AddDays(7) }
            'Quinzenal' { $proxima.AddDays(15) }
            'Mensal' { $proxima.AddMonths(1) }
            'Anual' { $proxima.AddYears(1) }
            default { return $proxima }
        }
    } while ($proxima -le (Get-Date))
    return $proxima
}

function Ler-Xaml([string]$xaml) {
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    return [Windows.Markup.XamlReader]::Load($reader)
}

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Mural de Lembretes" Width="1080" Height="720" MinWidth="850" MinHeight="570"
        WindowStartupLocation="CenterScreen" Background="#F7F8FA" FontFamily="Segoe UI" UseLayoutRounding="True" SnapsToDevicePixels="True">
  <Window.Resources>
    <Style x:Key="PrimaryButton" TargetType="Button">
      <Setter Property="Foreground" Value="White"/><Setter Property="Background" Value="#FF2E9A"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="20,11"/>
      <Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border Background="{TemplateBinding Background}" CornerRadius="12" Padding="{TemplateBinding Padding}">
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="SoftButton" TargetType="Button">
      <Setter Property="Foreground" Value="#34323A"/><Setter Property="Background" Value="#FFFFFF"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="12,7"/>
      <Setter Property="FontSize" Value="12"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border Background="{TemplateBinding Background}" CornerRadius="9" Padding="{TemplateBinding Padding}">
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid.RowDefinitions><RowDefinition Height="112"/><RowDefinition Height="66"/><RowDefinition Height="*"/><RowDefinition Height="38"/></Grid.RowDefinitions>
    <Border Grid.Row="0" CornerRadius="0,0,28,28">
      <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#D9F8FC" Offset="0"/><GradientStop Color="#FFF2A8" Offset="1"/></LinearGradientBrush></Border.Background>
      <Grid Margin="30,0"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel VerticalAlignment="Center">
          <TextBlock Text="meu mural" Foreground="#29313D" FontSize="30" FontWeight="Bold"/>
          <TextBlock Text="Lembretes leves para uma rotina mais tranquila." Foreground="#626C7A" FontSize="14" Margin="1,5,0,0"/>
        </StackPanel>
        <Button x:Name="BtnNovo" Grid.Column="1" Content="+  Novo lembrete" Style="{StaticResource PrimaryButton}" VerticalAlignment="Center"/>
      </Grid>
    </Border>
    <Grid Grid.Row="1" Margin="30,13,30,8">
      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="190"/><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <TextBlock Text="Visualizar" Foreground="#6D6978" VerticalAlignment="Center" Margin="0,0,10,0"/>
      <ComboBox x:Name="Filtro" Grid.Column="1" Height="36" SelectedIndex="0" Padding="10,6" Background="White" BorderBrush="#E5E1EB">
        <ComboBoxItem Content="Todos"/><ComboBoxItem Content="Pendentes"/><ComboBoxItem Content="Concluídos"/>
      </ComboBox>
      <TextBlock x:Name="ResumoTopo" Grid.Column="3" Foreground="#6D6978" VerticalAlignment="Center" FontSize="13"/>
    </Grid>
    <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="20,0,20,0">
      <WrapPanel x:Name="Mural" Margin="10"/>
    </ScrollViewer>
    <TextBlock Grid.Row="3" x:Name="Status" Foreground="#898491" FontSize="12" HorizontalAlignment="Right" Margin="0,4,30,0"/>
  </Grid>
</Window>
'@

$window = Ler-Xaml $xaml
$iconeJanela = Join-Path $appDir 'assets\icone-postits.ico'
if (Test-Path -LiteralPath $iconeJanela) {
    $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri($iconeJanela, [System.UriKind]::Absolute)))
}
$mural = $window.FindName('Mural')
$filtro = $window.FindName('Filtro')
$status = $window.FindName('Status')
$resumoTopo = $window.FindName('ResumoTopo')
$btnNovo = $window.FindName('BtnNovo')
$iconeBotao = Join-Path $appDir 'assets\botao-postits.png'
if (Test-Path -LiteralPath $iconeBotao) {
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.UriSource = New-Object System.Uri($iconeBotao, [System.UriKind]::Absolute)
    $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.DecodePixelWidth = 72
    $bitmap.EndInit()
    $bitmap.Freeze()
    $imagemBotao = New-Object System.Windows.Controls.Image
    $imagemBotao.Source = $bitmap
    $imagemBotao.Width = 38
    $imagemBotao.Height = 38
    $imagemBotao.Margin = '0,0,10,0'
    $textoBotao = New-Object System.Windows.Controls.TextBlock
    $textoBotao.Text = 'Novo lembrete'
    $textoBotao.FontSize = 14
    $textoBotao.FontWeight = 'SemiBold'
    $textoBotao.VerticalAlignment = 'Center'
    $conteudoBotao = New-Object System.Windows.Controls.StackPanel
    $conteudoBotao.Orientation = 'Horizontal'
    [void]$conteudoBotao.Children.Add($imagemBotao)
    [void]$conteudoBotao.Children.Add($textoBotao)
    $btnNovo.Content = $conteudoBotao
}

function Nova-Etiqueta([string]$texto, [string]$cor) {
    $border = New-Object System.Windows.Controls.Border
    $border.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($cor)
    $border.CornerRadius = 12
    $border.Padding = '9,4'
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = $texto
    $label.FontSize = 11
    $label.FontWeight = 'SemiBold'
    $label.Foreground = [System.Windows.Media.Brushes]::White
    $border.Child = $label
    return $border
}

function Atualizar-Mural {
    $mural.Children.Clear()
    $ordem = @{ 'Alta'=0; 'Média'=1; 'Baixa'=2 }
    $itens = @($script:lembretes | Sort-Object @{Expression={if($_.Concluido){1}else{0}}}, @{Expression={[datetime]$_.DataHora}}, @{Expression={$ordem[$_.Prioridade]}})
    $filtroAtual = [string](($filtro.SelectedItem).Content)
    if ($filtroAtual -eq 'Pendentes') { $itens = @($itens | Where-Object {-not $_.Concluido}) }
    if ($filtroAtual -eq 'Concluídos') { $itens = @($itens | Where-Object {$_.Concluido}) }

    if ($itens.Count -eq 0) {
        $empty = New-Object System.Windows.Controls.Border
        $empty.Width = 930; $empty.Height = 260; $empty.Background = [System.Windows.Media.Brushes]::White
        $empty.CornerRadius = 22; $empty.Margin = 10
        $empty.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E8E4EC'); $empty.BorderThickness = 1
        $stack = New-Object System.Windows.Controls.StackPanel
        $stack.VerticalAlignment = 'Center'; $stack.HorizontalAlignment = 'Center'
        $big = New-Object System.Windows.Controls.TextBlock
        $big.Text = 'Seu mural está livre'; $big.FontSize = 24; $big.FontWeight = 'SemiBold'; $big.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#34323A'); $big.HorizontalAlignment='Center'
        $small = New-Object System.Windows.Controls.TextBlock
        $small.Text = 'Crie um lembrete e deixe o aplicativo cuidar do horário.'; $small.FontSize=14; $small.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#898491'); $small.Margin='0,9,0,0'; $small.HorizontalAlignment='Center'
        [void]$stack.Children.Add($big); [void]$stack.Children.Add($small); $empty.Child=$stack; [void]$mural.Children.Add($empty)
    }

    foreach ($lem in $itens) {
        $quando = [datetime]$lem.DataHora
        $recorrencia = if([string]::IsNullOrWhiteSpace([string]$lem.Recorrencia)){'Nenhuma'}else{[string]$lem.Recorrencia}
        $variacaoCor=[Math]::Abs(([string]$lem.Id).GetHashCode()) % 2
        $fundo = if($lem.Concluido){'#E8E5EB'}elseif($lem.Prioridade -eq 'Alta'){'#FFD2EC'}elseif($lem.Prioridade -eq 'Média'){if($variacaoCor -eq 0){'#FFF09B'}else{'#FFD39A'}}else{if($variacaoCor -eq 0){'#C7F2FA'}else{'#E0F6A8'}}
        $etiqueta = if($lem.Prioridade -eq 'Alta'){'#EF5D78'}elseif($lem.Prioridade -eq 'Média'){'#E2A91B'}else{'#28A58B'}

        $card = New-Object System.Windows.Controls.Border
        $card.Width=285; $card.Height=205; $card.Margin=10; $card.Padding=18; $card.CornerRadius=20
        $card.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString($fundo)
        $card.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#E2DEE7'); $card.BorderThickness=1
        $grid=New-Object System.Windows.Controls.Grid
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height='Auto'}))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height='*'}))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height='Auto'}))

        $top=New-Object System.Windows.Controls.DockPanel
        $tag=Nova-Etiqueta ([string]$lem.Prioridade) $etiqueta
        [System.Windows.Controls.DockPanel]::SetDock($tag,'Left'); [void]$top.Children.Add($tag)
        if($recorrencia -ne 'Nenhuma'){
            $rep=New-Object System.Windows.Controls.TextBlock; $rep.Text='Repete: '+$recorrencia.ToLower(); $rep.FontSize=11; $rep.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#6D6978'); $rep.VerticalAlignment='Center'; $rep.HorizontalAlignment='Right'; [void]$top.Children.Add($rep)
        }
        [System.Windows.Controls.Grid]::SetRow($top,0); [void]$grid.Children.Add($top)

        $body=New-Object System.Windows.Controls.StackPanel; $body.Margin='0,15,0,10'
        $txt=New-Object System.Windows.Controls.TextBlock; $txt.Text=[string]$lem.Texto; $txt.FontSize=17; $txt.FontWeight='SemiBold'; $txt.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#34323A'); $txt.TextWrapping='Wrap'; $txt.MaxHeight=58
        if($lem.Concluido){$txt.TextDecorations='Strikethrough'; $txt.Opacity=.55}
        $date=New-Object System.Windows.Controls.TextBlock; $date.Text=$quando.ToString('ddd, dd/MM • HH:mm'); $date.FontSize=12; $date.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#6D6978'); $date.Margin='0,9,0,0'
        [void]$body.Children.Add($txt); [void]$body.Children.Add($date); [System.Windows.Controls.Grid]::SetRow($body,1); [void]$grid.Children.Add($body)

        $actions=New-Object System.Windows.Controls.DockPanel
        $done=New-Object System.Windows.Controls.Button; $done.Content=if($lem.Concluido){'Concluído'}elseif($recorrencia -ne 'Nenhuma'){'Próxima ocorrência'}else{'Concluir'}; $done.Tag=$lem.Id; $done.Style=$window.Resources['SoftButton']; $done.IsEnabled=-not $lem.Concluido
        $done.Add_Click({param($sender,$e); foreach($r in $script:lembretes){if($r.Id -eq [string]$sender.Tag){$tipo=if([string]::IsNullOrWhiteSpace([string]$r.Recorrencia)){'Nenhuma'}else{[string]$r.Recorrencia}; if($tipo -eq 'Nenhuma'){$r.Concluido=$true}else{$r.DataHora=(Obter-ProximaData ([datetime]$r.DataHora) $tipo).ToString('o'); $r.Concluido=$false; [void]$script:avisados.Remove([string]$r.Id)}}}; Salvar-Lembretes; Atualizar-Mural})
        [System.Windows.Controls.DockPanel]::SetDock($done,'Left'); [void]$actions.Children.Add($done)
        $delete=New-Object System.Windows.Controls.Button; $delete.Content='Excluir'; $delete.Tag=$lem.Id; $delete.Style=$window.Resources['SoftButton']; $delete.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#D84C63'); $delete.HorizontalAlignment='Right'
        $delete.Add_Click({param($sender,$e); if([System.Windows.MessageBox]::Show('Excluir este lembrete?','Confirmar','YesNo','Question') -eq 'Yes'){$script:lembretes=@($script:lembretes|Where-Object{$_.Id -ne [string]$sender.Tag}); Salvar-Lembretes; Atualizar-Mural}})
        [void]$actions.Children.Add($delete); [System.Windows.Controls.Grid]::SetRow($actions,2); [void]$grid.Children.Add($actions)
        $card.Child=$grid; [void]$mural.Children.Add($card)
    }
    $pendentes=@($script:lembretes|Where-Object{-not $_.Concluido}).Count
    $resumoTopo.Text="$pendentes pendente(s)"; $status.Text='Avisos verificados automaticamente a cada 15 segundos'
}

function Abrir-Criacao {
    $dialogXaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Novo lembrete" Width="520" Height="540" WindowStartupLocation="CenterOwner" ResizeMode="NoResize" Background="#F8F7F4" FontFamily="Segoe UI">
 <Grid Margin="28"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
  <TextBlock Text="Novo lembrete" FontSize="26" FontWeight="Bold" Foreground="#34323A"/>
  <TextBlock Grid.Row="1" Text="O que você quer lembrar?" Margin="0,22,0,7" Foreground="#6D6978"/>
  <TextBox x:Name="Texto" Grid.Row="2" Height="86" Padding="12" FontSize="14" TextWrapping="Wrap" AcceptsReturn="True" BorderBrush="#DDD8E3"/>
  <Grid Grid.Row="3" Margin="0,18,0,0"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="18"/><ColumnDefinition/></Grid.ColumnDefinitions>
   <StackPanel><TextBlock Text="Prioridade" Foreground="#6D6978" Margin="0,0,0,7"/><ComboBox x:Name="Prioridade" Height="38" SelectedIndex="1" Padding="9"><ComboBoxItem Content="Alta"/><ComboBoxItem Content="Média"/><ComboBoxItem Content="Baixa"/></ComboBox></StackPanel>
   <StackPanel Grid.Column="2"><TextBlock Text="Recorrência" Foreground="#6D6978" Margin="0,0,0,7"/><ComboBox x:Name="Recorrencia" Height="38" SelectedIndex="0" Padding="9"><ComboBoxItem Content="Nenhuma"/><ComboBoxItem Content="Semanal"/><ComboBoxItem Content="Quinzenal"/><ComboBoxItem Content="Mensal"/><ComboBoxItem Content="Anual"/></ComboBox></StackPanel>
  </Grid>
  <StackPanel Grid.Row="4" Margin="0,18,0,0"><TextBlock Text="Dia e horário" Foreground="#6D6978" Margin="0,0,0,7"/><DatePicker x:Name="Data" Height="38" Padding="9"/></StackPanel>
  <StackPanel Grid.Row="5" Orientation="Horizontal" Margin="0,12,0,0"><ComboBox x:Name="Hora" Width="100" Height="38" SelectedIndex="8" Padding="9"/><TextBlock Text=":" FontSize="20" Margin="8,5"/><ComboBox x:Name="Minuto" Width="100" Height="38" SelectedIndex="0" Padding="9"/></StackPanel>
  <StackPanel Grid.Row="6" Orientation="Horizontal" HorizontalAlignment="Right"><Button x:Name="Cancelar" Content="Cancelar" Width="110" Height="42" Margin="0,0,10,0"/><Button x:Name="Salvar" Content="Criar lembrete" Width="150" Height="42" Background="#FF2E9A" Foreground="White" BorderThickness="0" FontWeight="SemiBold"/></StackPanel>
 </Grid>
</Window>
'@
    $dialog=Ler-Xaml $dialogXaml; $dialog.Owner=$window
    $txt=$dialog.FindName('Texto'); $pri=$dialog.FindName('Prioridade'); $rec=$dialog.FindName('Recorrencia'); $data=$dialog.FindName('Data'); $hora=$dialog.FindName('Hora'); $min=$dialog.FindName('Minuto')
    0..23|ForEach-Object{[void]$hora.Items.Add($_.ToString('00'))}; @('00','15','30','45')|ForEach-Object{[void]$min.Items.Add($_)}
    $data.SelectedDate=(Get-Date).Date; $hora.SelectedItem=(Get-Date).AddHours(1).Hour.ToString('00'); $min.SelectedIndex=0
    $dialog.FindName('Cancelar').Add_Click({param($sender,$e); ([System.Windows.Window]::GetWindow($sender)).DialogResult=$false})
    $dialog.FindName('Salvar').Add_Click({param($sender,$e)
        $janela=[System.Windows.Window]::GetWindow($sender)
        $campoTexto=$janela.FindName('Texto'); $campoPrioridade=$janela.FindName('Prioridade'); $campoRecorrencia=$janela.FindName('Recorrencia')
        $campoData=$janela.FindName('Data'); $campoHora=$janela.FindName('Hora'); $campoMinuto=$janela.FindName('Minuto')
        if([string]::IsNullOrWhiteSpace($campoTexto.Text)){[System.Windows.MessageBox]::Show('Digite o texto do lembrete.','Campo obrigatório')|Out-Null; return}
        if($null -eq $campoData.SelectedDate -or $null -eq $campoHora.SelectedItem -or $null -eq $campoMinuto.SelectedItem){[System.Windows.MessageBox]::Show('Preencha a data e o horário.','Campos obrigatórios')|Out-Null; return}
        $quando=$campoData.SelectedDate.Date.AddHours([int]$campoHora.SelectedItem).AddMinutes([int]$campoMinuto.SelectedItem)
        if($quando -lt (Get-Date).AddMinutes(-1)){[System.Windows.MessageBox]::Show('Escolha uma data e hora futuras.','Data inválida')|Out-Null; return}
        $script:lembretes += [pscustomobject]@{Id=[guid]::NewGuid().ToString();Texto=$campoTexto.Text.Trim();Prioridade=[string]$campoPrioridade.SelectedItem.Content;DataHora=$quando.ToString('o');Recorrencia=[string]$campoRecorrencia.SelectedItem.Content;Concluido=$false}
        Salvar-Lembretes; Atualizar-Mural; $janela.DialogResult=$true
    })
    [void]$dialog.ShowDialog()
}

$btnNovo.Add_Click({Abrir-Criacao})
$filtro.Add_SelectionChanged({Atualizar-Mural})
$timer=New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromSeconds(15)
$timer.Add_Tick({foreach($lem in @($script:lembretes|Where-Object{-not $_.Concluido})){if([datetime]$lem.DataHora -le (Get-Date) -and -not $script:avisados.Contains([string]$lem.Id)){[void]$script:avisados.Add([string]$lem.Id); $window.Activate(); $window.Topmost=$true; [System.Windows.MessageBox]::Show("$($lem.Texto)`n`nPrioridade: $($lem.Prioridade)",'Hora do lembrete!')|Out-Null; $window.Topmost=$false}}})

Carregar-Lembretes
Atualizar-Mural
$timer.Start()
[void]$window.ShowDialog()
