

Dim objShell
Set objShell = CreateObject("Shell.Application")
Call objShell.ShellExecute("cmd.exe", "/k ipconfig", "", "open", 1)

'Dim oShell
'Set oShell = CreateObject("WScript.Shell")
'oShell.CurrentDirectory = ".\"
'oShell.Run "cmd /k ipconfig", 1, True