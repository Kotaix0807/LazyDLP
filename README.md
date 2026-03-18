# LazyDLP

LazyDLP es una herramienta con interfaz gráfica (GUI) ligera y nativa para Windows, diseñada para facilitar la descarga de videos y audios de YouTube aprovechando el motor de `yt-dlp` y `ffmpeg`.

Principalmente el objetivo de esta herramienta, es brindar la capacidad de descargar videos de youtube de manera limpia, sencilla y libre de malware, específiamente desarrollado para el público general. Es por esta razón que no existe soporte para linux y/o mac.

## ✨ Características

- **Interfaz limpia y moderna:** Ventanas construidas nativamente con Windows Forms y PowerShell, con soporte para antialiasing (ClearType).
- **Instalación desatendida:** Incluye un instalador inteligente que descarga, actualiza y configura automáticamente **yt-dlp** y **ffmpeg** utilizando `winget`.
- **Auto-elevación de permisos:** El instalador solicita automáticamente permisos de Administrador utilizando UAC sin que el usuario tenga que hacerlo manualmente.
- **Selección de formatos:** Extrae las calidades disponibles del enlace en tiempo real, permitiendo elegir resoluciones exactas de video o descargar exclusivamente el audio.
- **Memoria inteligente:** Guarda y recuerda automáticamente la última carpeta de destino utilizada por el usuario.
- **Sanitización de Logs:** Registra errores y procesos de instalación limpiando automáticamente caracteres rotos o basura visual de las descargas en consola.

## 🚀 Instrucciones de Uso

### 1. Instalación (Solo la primera vez)
1. Descarga la última versión de la aplicación desde la sección **Releases** y extrae el archivo ZIP.
2. Haz doble clic en el archivo **`LazyDLP.exe`**.
3. Si es tu primera vez usándolo, el programa detectará automáticamente qué le falta y te pedirá permiso para instalarlo en una terminal. Acéptalo.

### 2. Descargar contenido
1. Ejecuta **`LazyDLP.exe`**. Opcionalmente te avisará si hay actualizaciones disponibles.
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