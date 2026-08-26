# Configura as tarefas agendadas do NotaFood no Windows (Backend + Cloudflare Tunnel)
# Segue o mesmo padrão dos outros serviços da máquina (Viagem, Despacho, Ebird)

$tarefas = @(
    @{
        Nome = "NotaFood-Backend"
        Script = "C:\Projetos\notafood\iniciar_backend.ps1"
        Descricao = "Servidor Flask Backend do NotaFood (Porta 6001)"
    },
    @{
        Nome = "NotaFood-Cloudflared"
        Script = "C:\Projetos\notafood\iniciar_cloudflared.ps1"
        Descricao = "Túnel Cloudflare para notafood.pogti.com.br"
    }
)

foreach ($t in $tarefas) {
    $nome = $t.Nome
    $script = $t.Script
    $desc = $t.Descricao

    # Ação oculta do PowerShell
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""

    # Gatilhos: Ao fazer logon + repeticao periodica
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn
    $triggerHorario = New-ScheduledTaskTrigger -Once `
        -At (Get-Date).AddMinutes(-1) `
        -RepetitionInterval (New-TimeSpan -Minutes 5) `
        -RepetitionDuration (New-TimeSpan -Days 3650)

    # Configuracoes: Ignorar novas instancias se ja estiver rodando, reiniciar se falhar
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Days 0) `
        -MultipleInstances IgnoreNew `
        -RestartCount 999 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    try {
        # Registra ou substitui
        Unregister-ScheduledTask -TaskName $nome -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Register-ScheduledTask -TaskName $nome -Action $action -Trigger @($triggerLogon, $triggerHorario) -Settings $settings -Description $desc -ErrorAction Stop | Out-Null
        Write-Host "  [OK] Tarefa agendada configurada: $nome" -ForegroundColor Green

        # Inicia imediatamente
        Start-ScheduledTask -TaskName $nome
        Write-Host "  [OK] Iniciada: $nome" -ForegroundColor Cyan
    } catch {
        Write-Host "  [FALHA] $nome -> $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Conferindo tarefas:"
Get-ScheduledTask -TaskName "NotaFood*" | Format-Table TaskName, State, TaskPath
