# Inicialización de librerías gráficas
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()
try {
    # Activa el antialiasing (ClearType) en los textos de toda la aplicación
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
} catch {}

$baseDir = $PSScriptRoot

# Subir un nivel desde 'src' hacia la raíz del proyecto y entrar a 'assets'
$assetsDir = Join-Path (Split-Path $baseDir -Parent) "assets"
if (!(Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }
$logFile = Join-Path $assetsDir "error_log.txt"
$configFile = Join-Path $assetsDir "yt_config.ini"

# Limpieza automática de log viejo (si pesa más de 1MB)
if (Test-Path $logFile) {
    if ((Get-Item $logFile).Length -gt 1MB) { Remove-Item $logFile }
}

function Write-Log($detail) {
    "$(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') ERROR:`r`n$detail`r`n" + ("=" * 40) | Out-File $logFile -Append -Encoding utf8
}

function Mostrar-Carga($texto, $permitirCancelar = $false) {
    $c = New-Object System.Windows.Forms.Form
    $c.Text = "Procesando..."; $c.StartPosition = "CenterScreen"
    $c.FormBorderStyle = "FixedDialog"; $c.ControlBox = $false; $c.TopMost = $true
    $c.BackColor = [System.Drawing.Color]::White
    $c.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $texto; $lbl.SetBounds(25, 15, 290, 45)
    $c.Controls.Add($lbl)

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Style = "Marquee"; $pb.MarqueeAnimationSpeed = 35; $pb.SetBounds(25, 65, 285, 20)
    $c.Controls.Add($pb)
    
    if ($permitirCancelar) {
        $c.Size = "350,175"
        $btnC = New-Object System.Windows.Forms.Button
        $btnC.Text = "Cancelar"; $btnC.SetBounds(125, 95, 100, 30)
        $btnC.BackColor = [System.Drawing.Color]::LightGray
        $btnC.FlatStyle = "Flat"; $btnC.FlatAppearance.BorderSize = 0
        $btnC.Cursor = "Hand"
        $btnC.Add_Click({ 
            $frm = $this.FindForm()
            if ($frm) { $frm.Tag = "CANCEL" }
            $this.Text = "Cancelando..."
            $this.Enabled = $false
        })
        $c.Controls.Add($btnC)
    } else {
        $c.Size = "350,140"
    }

    $c.Show()
    for($i=0; $i -lt 15; $i++){ [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 15 }
    return [PSCustomObject]@{ Form = $c; Label = $lbl }
}

function Ejecutar-YtDlp($argumentos, $winObj, $esDescarga) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "yt-dlp"
    $psi.Arguments = $argumentos
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $proc = [System.Diagnostics.Process]::Start($psi)
    $sb = New-Object System.Text.StringBuilder; $lineSb = New-Object System.Text.StringBuilder
    $errSb = New-Object System.Text.StringBuilder

    $outTask = $proc.StandardOutput.ReadLineAsync()
    $errTask = $proc.StandardError.ReadLineAsync()
    $outActive = $true
    $errActive = $true

    # El bucle continúa hasta que el proceso termine Y ambos flujos de datos se vacíen por completo
    while (-not $proc.HasExited -or $outActive -or $errActive) {
        [System.Windows.Forms.Application]::DoEvents()
        if ($winObj.Form.Tag -eq "CANCEL") {
            try { 
                if (-not $proc.HasExited) {
                    $proc.Kill()
                    $proc.WaitForExit(3000) # Esperar hasta 3s a que el proceso libere los archivos
                }
            } catch {}
            return [PSCustomObject]@{ Status = "CANCELLED"; Output = "" }
        }
        
        $hasData = $false

        # Evaluar la salida estándar sin bloquear el hilo
        if ($outActive -and $outTask.IsCompleted) {
            if ($outTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) {
                $line = $outTask.Result
                if ($line -ne $null) {
                    $hasData = $true
                    try { [Console]::WriteLine($line) } catch {}
                    [void]$sb.AppendLine($line)
                    
                    if ($esDescarga) {
                        $trimLine = $line.Trim()
                        if ($trimLine -match "\[download\]\s*([\d\.]+%)\s*of\s*~?\s*[\d\.]+[a-zA-Z]+(?:.*?at\s+([^\s]+))?(?:\s+ETA\s+([^\s]+))?") {
                            $spd = if ($matches[2]) { $matches[2] } else { "---" }; $eta = if ($matches[3]) { $matches[3] } else { "---" }
                            $winObj.Label.Text = "Progreso: $($matches[1])`nVelocidad: $spd | ETA: $eta"
                        } elseif ($trimLine -match "\[Merger\]|\[ExtractAudio\]|\[VideoConvertor\]") {
                            $winObj.Label.Text = "Procesando audio/video (ffmpeg)...`nEsto puede tardar un momento."
                        }
                    }
                    # Iniciar la tarea de leer la siguiente línea
                    $outTask = $proc.StandardOutput.ReadLineAsync()
                } else { $outActive = $false } # Se alcanzó el fin del flujo
            } else { $outActive = $false }
        }

        # Evaluar los errores sin bloquear
        if ($errActive -and $errTask.IsCompleted) {
            if ($errTask.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) {
                $errLine = $errTask.Result
                if ($errLine -ne $null) {
                    $hasData = $true
                    try { [Console]::WriteLine($errLine) } catch {}
                    [void]$errSb.AppendLine($errLine)
                    $errTask = $proc.StandardError.ReadLineAsync()
                } else { $errActive = $false }
            } else { $errActive = $false }
        }
        
        if (-not $hasData) { Start-Sleep -Milliseconds 50 }
    }
    
    return [PSCustomObject]@{ Status = "COMPLETED"; Output = ($sb.ToString() + "`n" + $errSb.ToString()); ExitCode = $proc.ExitCode }
}

function Pedir-URL {
    $frm = New-Object System.Windows.Forms.Form
    $frm.Text = "LazyDLP"; $frm.Size = "400,180"; $frm.StartPosition = "CenterScreen"
    $frm.FormBorderStyle = "FixedSingle"; $frm.MaximizeBox = $false
    $frm.BackColor = [System.Drawing.Color]::White
    $frm.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Pega el link de YouTube:"
    $lbl.SetBounds(25, 20, 330, 20)
    $frm.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.SetBounds(25, 45, 330, 25)
    $frm.Controls.Add($txt)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "Continuar"; $btn.SetBounds(135, 85, 120, 35)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(255, 0, 120, 215); $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = "Flat"; $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = "Hand"; $frm.Controls.Add($btn)

    $btn.Add_Click({ $frm.Tag = $txt.Text; $frm.Close() })
    $frm.AcceptButton = $btn # Permite presionar 'Enter' para continuar

    $frm.ShowDialog() | Out-Null
    return $frm.Tag
}

try {
    # Verificar que los componentes están instalados antes de iniciar
    if (!(Get-Command yt-dlp -ErrorAction SilentlyContinue) -or !(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        $msgError = "Faltan dependencias necesarias para continuar.`n`n" +
                        "Se instalarán yt-dlp y ffmpeg en su versión más reciente.`n`n" +
                    "Deseas ejecutar el instalador automáticamente ahora?"
        $resp = [System.Windows.Forms.MessageBox]::Show($msgError, "Dependencias faltantes", "YesNo", "Information")
        if ($resp -eq "Yes") {
            $installerBat = Join-Path (Split-Path $baseDir -Parent) "LazyDLP-installer.bat"
            if (Test-Path $installerBat) {
                Start-Process $installerBat
            } else {
                [System.Windows.Forms.MessageBox]::Show("No se encontró LazyDLP-installer.bat en la raíz del proyecto.", "Error", "OK", "Error")
            }
        }
        exit
    }

    $url = Pedir-URL
    if ([string]::IsNullOrWhiteSpace($url)) { exit }

    $winCarga = Mostrar-Carga "Conectando con YouTube..." $true
    
    $argsJ = "-J --no-playlist --no-warnings --no-cache-dir --no-check-certificate `"$url`""
    $resJ = Ejecutar-YtDlp $argsJ $winCarga $false
    $winCarga.Form.Close()

    if ($resJ.Status -eq "CANCELLED") { exit }
    $jsonRaw = $resJ.Output

    if ($resJ.ExitCode -ne 0 -or $jsonRaw -match "ERROR:") { 
        throw "Fallo al obtener información del video:`r`n$jsonRaw" 
    }
    $videoData = $jsonRaw | ConvertFrom-Json

    $formatos = @()
    foreach ($fmt in $videoData.formats) {
        # 1. Filtrar formatos "basura" o fragmentos (ej. storyboards o mhtml)
        if ($fmt.format_note -match "storyboard" -or $fmt.ext -in @("mhtml", "none", "sb0")) { continue }

        # 2. Identificar qué contiene el formato realmente
        $isAudio = ($fmt.vcodec -eq "none" -or $fmt.vcodec -eq $null)
        $isVideoOnly = ($fmt.acodec -eq "none" -or $fmt.acodec -eq $null) -and -not $isAudio

        if ($isAudio) {
            $tipo = "AUDIO"; $detalle = if ($fmt.abr) { "$($fmt.abr)kbps" } else { "Audio" }; $fid = $fmt.format_id
        } elseif ($isVideoOnly) {
            $tipo = "VIDEO"; $detalle = if ($fmt.resolution) { $fmt.resolution } else { "$($fmt.width)x$($fmt.height)" }
            if ($fmt.fps) { $detalle += " @ $($fmt.fps)fps" }
            # 3. TRUCO: Al ID de solo video, le pedimos también el mejor audio disponible para fusionarlo
            $fid = "$($fmt.format_id)+bestaudio/best"
        } else {
            $tipo = "VIDEO+AUDIO"; $detalle = if ($fmt.resolution) { $fmt.resolution } else { "$($fmt.width)x$($fmt.height)" }
            if ($fmt.fps) { $detalle += " @ $($fmt.fps)fps" }
            $fid = $fmt.format_id
        }
        
        $formatos += [PSCustomObject]@{ L = "[$tipo] [.$($fmt.ext)] - $detalle"; format_id = $fid }
    }
    # 4. Limpiar opciones visualmente duplicadas y ordenar de mejor a menor calidad
    $formatos = $formatos | Group-Object -Property L | ForEach-Object { $_.Group[0] } | Sort-Object -Property L -Descending

    # Ventana Principal
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Descargar: $($videoData.title)"; $f.Size = "550,260"; $f.StartPosition = "CenterScreen"
    $f.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $f.BackColor = [System.Drawing.Color]::White
    $f.FormBorderStyle = "FixedSingle"; $f.MaximizeBox = $false
    
    $lastPath = if (Test-Path $configFile) { Get-Content $configFile } else { [Environment]::GetFolderPath("MyVideos") }
    
    $lblR = New-Object System.Windows.Forms.Label; $lblR.Text = "Destino: $lastPath"; $lblR.SetBounds(25,25,350,20); $lblR.AutoEllipsis = $true; $f.Controls.Add($lblR)
    
    $btnR = New-Object System.Windows.Forms.Button; $btnR.Text = "Cambiar Carpeta"; $btnR.SetBounds(385,20,120,30)
    $btnR.FlatStyle = "System"; $btnR.Cursor = "Hand"; $f.Controls.Add($btnR)
    
    $combo = New-Object System.Windows.Forms.ComboBox; $combo.SetBounds(25,75,480,30); $combo.DropDownStyle = "DropDownList"
    foreach ($item in $formatos) { [void]$combo.Items.Add($item.L) }; $combo.SelectedIndex = 0; $f.Controls.Add($combo)
    
    $btnC = New-Object System.Windows.Forms.Button; $btnC.Text = "Cancelar"; $btnC.SetBounds(25,135,140,45)
    $btnC.BackColor = [System.Drawing.Color]::LightGray; $btnC.FlatStyle = "Flat"; $btnC.FlatAppearance.BorderSize = 0
    $btnC.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnC.Cursor = "Hand"; $f.Controls.Add($btnC)

    $btnD = New-Object System.Windows.Forms.Button; $btnD.Text = "Descargar"; $btnD.SetBounds(175,135,330,45)
    $btnD.BackColor = [System.Drawing.Color]::FromArgb(255, 0, 120, 215); $btnD.ForeColor = [System.Drawing.Color]::White
    $btnD.FlatStyle = "Flat"; $btnD.FlatAppearance.BorderSize = 0
    $btnD.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnD.Cursor = "Hand"; $f.Controls.Add($btnD)

    $btnR.Add_Click({
        $fd = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fd.ShowDialog() -eq "OK") { $script:lastPath = $fd.SelectedPath; $lblR.Text = "Destino: $lastPath"; $lastPath | Out-File $configFile -Force }
    })

    $btnC.Add_Click({ $f.Tag = "CANCEL"; $f.Close() })
    $btnD.Add_Click({ $f.Tag = "GO"; $f.Close() })
    $f.ShowDialog() | Out-Null

    if ($f.Tag -eq "GO") {
        $winDl = Mostrar-Carga "Iniciando descarga..." $true
        $fid = $formatos[$combo.SelectedIndex].format_id
        $isAudioSel = $formatos[$combo.SelectedIndex].L -match "^\[AUDIO\]"
        
        $outName = "%(title)s [%(id)s].%(ext)s"
        $baseArgs = "-f `"$fid`" `"$url`" -P `"$lastPath`" -o `"$outName`" --windows-filenames --trim-filenames 150 --no-continue --no-cache-dir --no-check-certificate --verbose"
        
        if ($isAudioSel) {
            # Forzar extracción a MP3 puro para evitar el "ícono en blanco" de formatos webm
            $argsDl = "$baseArgs -x --audio-format mp3"
        } else {
            # Forzar empaquetado a MP4 puro para compatibilidad nativa en Windows
            $argsDl = "$baseArgs --merge-output-format mp4 --remux-video mp4"
        }
        
        $resDl = Ejecutar-YtDlp $argsDl $winDl $true
        $winDl.Form.Close()

        if ($resDl.Status -eq "CANCELLED") {
            Get-ChildItem -Path $lastPath -Filter "*.part" -ErrorAction SilentlyContinue | Remove-Item -Force
            Get-ChildItem -Path $lastPath -Filter "*.ytdl" -ErrorAction SilentlyContinue | Remove-Item -Force
            [System.Windows.Forms.MessageBox]::Show("Descarga cancelada y archivos limpiados.", "Cancelado", "OK", "Information") | Out-Null
            exit
        }

        if ($resDl.ExitCode -ne 0 -or $resDl.Output -match "ERROR:") { 
            Write-Log "Fallo en yt-dlp. Código de salida: $($resDl.ExitCode)`r`nDetalles de consola:`r`n$($resDl.Output)"
            throw "Ocurrió un error durante la descarga. Se ha guardado el detalle en el log."
        }
        
        # Pequeña pausa para que Windows Explorer, Antivirus o OneDrive actualicen sus cachés
        Start-Sleep -Seconds 2

        # Forzar reseteo de permisos de seguridad (Soluciona el bloqueo de UWP y el ícono en blanco)
        try {
            Get-ChildItem -Path $lastPath -Filter "*.mp4" -File -ErrorAction SilentlyContinue | ForEach-Object { icacls $_.FullName /reset /q 2>&1 | Out-Null }
            Get-ChildItem -Path $lastPath -Filter "*.mp3" -File -ErrorAction SilentlyContinue | ForEach-Object { icacls $_.FullName /reset /q 2>&1 | Out-Null }
        } catch {}

        if ([System.Windows.Forms.MessageBox]::Show("Completado! Abrir carpeta?", "Éxito", "YesNo", "Information") -eq "Yes") { explorer.exe $lastPath }
    }
} catch {
    Write-Log $_
    if ([System.Windows.Forms.MessageBox]::Show("Ocurrió un error.`nDeseas abrir el log?", "Error", "YesNo", "Error") -eq "Yes") { notepad.exe $logFile }
} finally {
    [Environment]::Exit(0)
}