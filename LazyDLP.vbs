Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

' Obtiene la carpeta donde está este archivo .vbs
strPath = fso.GetParentFolderName(WScript.ScriptFullName)

' Cambia el directorio de trabajo a esa carpeta
WshShell.CurrentDirectory = strPath

' Ejecuta PowerShell de forma invisible (el 0 al final)
' Usamos -WindowStyle Hidden como refuerzo
WshShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""src\main.ps1""", 0, False