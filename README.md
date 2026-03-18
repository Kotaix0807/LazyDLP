# LazyDLP

LazyDLP es una herramienta con interfaz gráfica (GUI) ligera y nativa para Windows, diseñada para facilitar la descarga de videos y audios de YouTube aprovechando el poderoso motor de `yt-dlp` y `ffmpeg`.

## ✨ Características

- **Interfaz limpia y moderna:** Ventanas construidas nativamente con Windows Forms y PowerShell, con soporte para antialiasing (ClearType).
- **Instalación desatendida:** Incluye un instalador inteligente que descarga, actualiza y configura automáticamente **Python**, **yt-dlp** y **ffmpeg** utilizando `winget` y `pip`.
- **Instalación desatendida:** Incluye un instalador inteligente que descarga, actualiza y configura automáticamente **yt-dlp** y **ffmpeg** utilizando `winget`.
- **Auto-elevación de permisos:** El instalador solicita automáticamente permisos de Administrador utilizando UAC sin que el usuario tenga que hacerlo manualmente.
- **Selección de formatos:** Extrae las calidades disponibles del enlace en tiempo real, permitiendo elegir resoluciones exactas de video o descargar exclusivamente el audio.
- **Memoria inteligente:** Guarda y recuerda automáticamente la última carpeta de destino utilizada por el usuario.
- **Sanitización de Logs:** Registra errores y procesos de instalación limpiando automáticamente caracteres rotos o basura visual de las descargas en consola.

## 🚀 Instrucciones de Uso

### 1. Instalación (Solo la primera vez)
1. Descarga o clona este repositorio en tu computadora.
2. Ejecuta el archivo `LazyDLP-installer.bat`.
3. Acepta los permisos de Administrador cuando Windows te lo pregunte.
4. Una ventana visual te mostrará el progreso mientras se instalan las dependencias. Espera el mensaje de "¡Instalación completa!".

### 2. Descargar contenido
1. Ejecuta el archivo `LazyDLP-terminal.bat` para iniciar el programa principal.
2. Pega un enlace válido de YouTube y presiona la tecla **Enter**.
3. Selecciona en el menú desplegable la calidad de video (MP4) o audio (M4A/MP3) que deseas.
4. Haz clic en "Cambiar Carpeta" si deseas guardar el archivo en otro lugar.
5. Haz clic en **DESCARGAR**. Al finalizar, el programa te preguntará si deseas abrir la carpeta contenedora.

## 🤖 Desarrollo y Tecnología

Este proyecto fue estructurado, depurado y desarrollado con la asistencia de **Inteligencia Artificial (IA)**. A través de iteraciones guiadas, se transformaron scripts básicos de consola en una aplicación de escritorio completa, sólida y profesional, demostrando el potencial de las herramientas de IA en la ingeniería de software moderna.

### Tecnologías utilizadas:
- Windows PowerShell (Scripts y automatización)
- .NET Windows Forms (Interfaz Gráfica)
- Winget & PIP (Gestión de paquetes)
- yt-dlp & FFmpeg (Motor de descarga y procesamiento)