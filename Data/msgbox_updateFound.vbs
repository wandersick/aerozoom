'On Error Resume Next
Dim strMsg
set objShell = CreateObject("WScript.Shell")
strMsg = Msgbox("New version of AeroZoom is available! Visit tech.wandersick.com now?",4,"Update Check")
If strMsg = 6 Then
	objShell.Run "%comspec% /c start http://tech.wandersick.com" 
Else
	wscript.quit
End If