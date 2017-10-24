; AeroZoom by wanderSick | http://wandersick.blogspot.com

#SingleInstance IGNORE ; dont set to force or ghost frames

Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom.ico

; Check custom transparency setting
RegRead,padTrans,HKCU,Software\WanderSick\AeroZoom,padTrans
if errorlevel
{
	padTrans=1
}
RegRead,padX,HKCU,Software\WanderSick\AeroZoom,padX
if errorlevel
{
	padX=235
}
RegRead,padY,HKCU,Software\WanderSick\AeroZoom,padY
if errorlevel
{
	padY=240
}
RegRead,padH,HKCU,Software\WanderSick\AeroZoom,padH
if errorlevel
{
	padH=475
}
RegRead,padW,HKCU,Software\WanderSick\AeroZoom,padW
if errorlevel
{
	padW=475
}
RegRead,padBorder,HKCU,Software\WanderSick\AeroZoom,padBorder
if errorlevel
{
	padBorder=2
}
RegRead,padStayTime,HKCU,Software\WanderSick\AeroZoom,padStayTime
if errorlevel
{
	padStayTime=150
}

if (padBorder=1)
	padCaption=+Caption
else
	padCaption=-Caption

MouseGetPos, xPos, yPos
xPos2 := xPos - padX
yPos2 := yPos - padY
Gui, %padCaption% +LastFound -MaximizeBox -MinimizeBox +AlwaysOnTop +ToolWindow
Gui, Color, EEAA99 ; any color
WinSet, TransColor, EEAA99 %padTrans% ; this is better than doing a winset after gui show which causes a short 'ghost frame'
Gui, Add, Text, w%padW% h%padH% gUiMove,
Gui, Show, w%padW% h%padH% x%xPos2% y%yPos2%, AeroZoom Pad
; if any of these buttons are not held anymore, close ZoomPad
Loop
{
	Sleep, %padStayTime%
	if not ((GetKeyState("LButton") or GetKeyState("RButton") or GetKeyState("MButton") or GetKeyState("XButton1") or GetKeyState("XButton2")  or GetKeyState("WheelUp")  or GetKeyState("WheelDown")))
	{
		Sleep, %padStayTime%
		Exitapp
	}
}
Exitapp

uiMove:
PostMessage, 0xA1, 2,,, A 
Return

; AeroZoom by wanderSick | http://wandersick.blogspot.com