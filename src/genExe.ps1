# Este script compila pequeños "lanzadores" .exe nativos usando el compilador de Windows.
# Generan archivos limpios que no son detectados como virus por Windows Defender.

Write-Host "Generando LazyDLP.exe..." -ForegroundColor Cyan
$codigoMain = @'
using System.Diagnostics;
using System.IO;
using System.Reflection;
class Program {
    static void Main() {
        string baseDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        string script = Path.Combine(baseDir, "src", "main.ps1");
        ProcessStartInfo p = new ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + script + "\"");
        p.CreateNoWindow = true;
        p.UseShellExecute = false;
        Process.Start(p);
    }
}
'@

$baseDir = Split-Path $PSScriptRoot -Parent
$iconPath = Join-Path $baseDir "assets\images\LazyDLP.ico"
$outExe = Join-Path $baseDir "LazyDLP.exe"

if (Test-Path $outExe) {
    Remove-Item -Path $outExe -Force -ErrorAction SilentlyContinue
}

$cp = New-Object System.CodeDom.Compiler.CompilerParameters
$cp.GenerateExecutable = $true
$cp.OutputAssembly = $outExe
$cp.CompilerOptions = "/target:winexe"
if (Test-Path $iconPath) { $cp.CompilerOptions += " /win32icon:`"$iconPath`"" }
$cp.ReferencedAssemblies.Add("System.dll") | Out-Null

Add-Type -TypeDefinition $codigoMain -Language CSharp -CompilerParameters $cp

Write-Host "¡Archivo LazyDLP.exe generado con éxito!" -ForegroundColor Green
Start-Sleep -Seconds 3