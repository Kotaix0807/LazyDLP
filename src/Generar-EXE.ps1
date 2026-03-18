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
Add-Type -TypeDefinition $codigoMain -Language CSharp -OutputAssembly "LazyDLP.exe" -OutputType WindowsApplication

Write-Host "¡Archivo LazyDLP.exe generado con éxito!" -ForegroundColor Green
Start-Sleep -Seconds 3