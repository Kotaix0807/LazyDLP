﻿# 1. Carga de librerías y Estilos
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Forzar codificación UTF-8 para evitar caracteres rotos en la consola
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8

# 2. Verificación de Administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Auto-solicitar permisos a Windows automáticamente
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    } catch {
        exit # Si el usuario le da "No" al aviso de Windows, simplemente salimos
    }
}

# Guardar el log en la carpeta 'assets' para mantener la carpeta de código limpia
$assetsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "assets"
if (!(Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }
$logFile = Join-Path $assetsDir "instalacion_log.txt"
if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }

function Write-Log($msg) {
    "$(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') - $msg" | Out-File $logFile -Append -Encoding utf8
}

function Limpiar-Texto($texto) {
    if ([string]::IsNullOrWhiteSpace($texto)) { return "" }
    $texto = $texto -replace "`e\[[0-9;]*[a-zA-Z]", "" # Quitar secuencias ANSI
    $texto = $texto -replace "(?m)^\s*[\-\\\|\/]\s*$", "" # Quitar spinners
    $texto = $texto -replace "(?m)^.*(?:█|▒|▓|Ôûê|ÔûÆ|■).*", "" # Quitar barras sólidas de winget
    $texto = $texto -replace "(?m)^.*-{5,}.*$", "" # Quitar barras de guiones de pip
    $texto = $texto -replace "(?m)^\s*\r?\n", "" # Quitar líneas en blanco adicionales
    # Reemplazo manual por si el UTF-8 nativo de la consola falla con Winget
    $texto = $texto -replace "Versi├│n", "Versión" -replace "instalaci├│n", "instalación"
    $texto = $texto -replace "aplicaci├│n", "aplicación" -replace "extra├¡do", "extraído"
    $texto = $texto -replace "verific├│", "verificó" -replace "l├¡nea", "línea"
    return $texto.Trim()
}

function Mostrar-Carga($texto) {
    $c = New-Object System.Windows.Forms.Form
    $c.Text = "Instalador de Dependencias"; $c.Size = "350,110"; $c.StartPosition = "CenterScreen"
    $c.FormBorderStyle = "FixedDialog"; $c.ControlBox = $false; $c.TopMost = $true
    
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $texto; $lbl.SetBounds(20, 15, 310, 20)
    $c.Controls.Add($lbl)

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Style = "Marquee"; $pb.MarqueeAnimationSpeed = 35; $pb.SetBounds(20, 40, 300, 20)
    $c.Controls.Add($pb)
    
    $c.Show()
    for($i=0; $i -lt 15; $i++){ [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 15 }
    return [PSCustomObject]@{ Form = $c; Label = $lbl }
}

try {
    $ErrorActionPreference = "Stop"

    $winCarga = Mostrar-Carga "Iniciando instalación..."
    Write-Log "Iniciando instalación..."

    $winCarga.Label.Text = "Configurando permisos de Windows..."
    [System.Windows.Forms.Application]::DoEvents()
    Write-Log "Configurando permisos y desbloqueando archivos de Windows..."
    # Quitar el bloqueo de Windows (Mark of the Web) a todos los archivos de la carpeta del proyecto
    Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

    # Verificar Internet
    if (!(Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) { throw "No hay internet." }

    # Verificar si winget está disponible
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "Winget no está instalado en este sistema. Actualiza el 'Instalador de aplicación' desde la Microsoft Store."
    }

    # Instalar o actualizar yt-dlp directamente (Versión Standalone, no requiere Python)
    if (!(Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        $winCarga.Label.Text = "Instalando yt-dlp via Winget..."
        [System.Windows.Forms.Application]::DoEvents()
        Write-Log "Instalando yt-dlp..."
        $wingetOut = winget install -e --id yt-dlp.yt-dlp --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-String
        Write-Log "Resultado Winget yt-dlp:`r`n$(Limpiar-Texto $wingetOut)"
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
    } else {
        $winCarga.Label.Text = "Verificando actualizaciones de yt-dlp..."
        [System.Windows.Forms.Application]::DoEvents()
        Write-Log "Actualizando yt-dlp..."
        $wingetOut = winget upgrade -e --id yt-dlp.yt-dlp --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-String
        Write-Log "Resultado Winget yt-dlp update:`r`n$(Limpiar-Texto $wingetOut)"
    }

    # Instalar ffmpeg
    if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        $winCarga.Label.Text = "Instalando ffmpeg via Winget..."
        [System.Windows.Forms.Application]::DoEvents()
        Write-Log "Instalando ffmpeg..."
        $wingetOut = winget install -e --id Gyan.FFmpeg --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-String
        Write-Log "Resultado Winget ffmpeg:`r`n$(Limpiar-Texto $wingetOut)"
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
    }

    if ($winCarga -and $winCarga.Form) { $winCarga.Form.Close() }
    [System.Windows.Forms.MessageBox]::Show("¡Instalación completa!", "Éxito")

} catch {
    if ($winCarga -and $winCarga.Form) { $winCarga.Form.Close() }
    Write-Log "ERROR CRÍTICO: $_ `r`nLínea: $($_.InvocationInfo.Line)`r`nDetalles del sistema:`r`n$($_.ScriptStackTrace)"
    [System.Windows.Forms.MessageBox]::Show("Error. Revisa el log: $logFile", "Error")
}