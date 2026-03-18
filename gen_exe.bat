@echo off
setlocal
cd /d "%~dp0"

set SCRIPT_NAME=genExe.ps1
set SCRIPT_PATH="%~dp0src\%SCRIPT_NAME%"

if exist %SCRIPT_PATH% (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File %SCRIPT_PATH%
) else (
    echo [ERROR] No se encuentra el archivo %SCRIPT_NAME% en la carpeta src.
    echo Asegurate de que el archivo no se llame %SCRIPT_NAME%.txt
    dir /b
)