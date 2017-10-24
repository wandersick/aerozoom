'On Error Resume Next
Dim strMsg
set objShell = CreateObject("WScript.Shell")
strMsg = Msgbox("New version of AeroZoom is available! Visit wandersick.blogspot.com now?",4,"Found an update")
If strMsg = 6 Then
	objShell.Run "%comspec% /c start http://wandersick.blogspot.com" 
Else
	wscript.quit
End If