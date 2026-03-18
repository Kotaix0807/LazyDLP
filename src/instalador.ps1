﻿# 1. Carga de librerías y Estilos
Add-Type -AssemblyName System.Windows.Forms

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

Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   Gestor de Dependencias de LazyDLP" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

try {
    Write-Host "[*] Desbloqueando archivos de seguridad..." -ForegroundColor Gray
    Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

    if (!(Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) { 
        Write-Host "[!] No se detectó conexión a Internet." -ForegroundColor Red
        Pause; exit
    }

    if (!(Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "`n[*] Instalando motor principal (yt-dlp)..." -ForegroundColor Yellow
        Start-Process -FilePath "winget" -ArgumentList "install -e --id yt-dlp.yt-dlp --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
    } else {
        Write-Host "`n[*] Descargando actualización de yt-dlp..." -ForegroundColor Yellow
        Start-Process -FilePath "winget" -ArgumentList "upgrade -e --id yt-dlp.yt-dlp --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
    }

    if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "`n[*] Instalando decodificador (FFmpeg)..." -ForegroundColor Yellow
        Start-Process -FilePath "winget" -ArgumentList "install -e --id Gyan.FFmpeg --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
    }

    Write-Host "`n[*] ¡Operación completada con éxito!" -ForegroundColor Green
    [System.Windows.Forms.MessageBox]::Show("Actualizado/Instalado correctamente.`n`nHaz clic en Aceptar para continuar e iniciar LazyDLP.", "¡Listo!", "OK", "Information") | Out-Null
} catch {
    Write-Host "`n[X] Ocurrió un error inesperado: $_" -ForegroundColor Red
    Pause
}