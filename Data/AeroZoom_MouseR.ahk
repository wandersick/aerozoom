; AeroZoom by wanderSick | http://wandersick.blogspot.com

verAZ = v1.7
paused = 0

RegRead,OSver,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentVersion
if not (OSver>6) {
  MsgBox You're not using Windows 7 or later. Expect abnormal behaviors.
}

if not A_IsAdmin
{
   DllCall("shell32\ShellExecuteA", uint, 0, str, "RunAs", str, A_AhkPath
      , str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)  ; Last parameter: SW_SHOWNORMAL = 1
   ExitApp
}

~RButton & WheelUp::
if not (paused=1) {
	send {LWin down}{NumpadAdd}{LWin up}
}
return

~RButton & WheelDown::
if not (paused=1) {
	send {lwin down}{NumpadSub}{lwin up}
}
return

; Run,"%windir%\system32\reg.exe" add HKCU\Software\Microsoft\ScreenMagnifier /v Magnification /t REG_DWORD /d 0x64 /f,,Min

~RButton & MButton::
if not (paused=1) {
	Process, Close, magnify.exe
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
	Sleep, 10
	Run,"%windir%\system32\magnify.exe",,
}
return

~RButton & LButton::
Gui, Destroy
; Get Mouse Position
MouseGetPos, xPos, yPos
xPos2 := xPos - 15
yPos2 := yPos - 160
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,Invert
if (magnifierSetting=0x1) {
  ColorCurrent = On
  ColorNext = Off
} else {
  ColorCurrent = Off
  ColorNext = On
}
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowMouse
if (magnifierSetting=0x1) {
  MouseCurrent = On
  MouseNext = Off
} else {
  MouseCurrent = Off
  MouseNext = On
}
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowFocus
if (magnifierSetting=0x1) {
  KeyboardCurrent = On
  KeyboardNext = Off
} else {
  KeyboardCurrent = Off
  KeyboardNext = On
}
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowCaret
if (magnifierSetting=0x1) {
  TextCurrent = On
  TextNext = Off
} else {
  TextCurrent = Off
  TextNext = On
}

; Adds Buttons
Gui, -MinimizeBox -MaximizeBox  ; Disable Minimize and Maximize button on Title bar
Gui, Font, s8, Arial
Gui, Add, Button, x15 y10 w110 h43 gColor, &Color %ColorCurrent% => %ColorNext%
Gui, Add, Button, x15 y53 w110 h43 gMouse, &Mouse %MouseCurrent% => %MouseNext%
Gui, Add, Button, x15 y96 w110 h43 gKeyboard, &Keyboard %KeyboardCurrent% => %KeyboardNext%
Gui, Add, Button, x15 y139 w110 h43 gText, &Text %TextCurrent% => %TextNext%
Gui, Add, Button, x15 y184 w54 h28 gShowMagnifier, &Show
Gui, Add, Button, x71 y184 w54 h28 gKillMagnifier, Kil&l
Gui, Add, Button, x15 y214 w54 h28 gDefault, &Reset
Gui, Add, Button, x71 y214 w54 h28 gCalc, C&alc
Gui, Add, Button, x15 y244 w54 h28 gDraw, &Draw
Gui, Add, Button, x71 y244 w54 h28 gType, T&ype
; Gui, Add, Button, x71 y214 w54 h28 gHide, &__

if (paused=0) {
	pausedMsg = &off
} else {
	pausedMsg = &on
}

Gui, Add, Button, x15 y274 w35 h22 gPauseScript, %pausedMsg%
Gui, Add, Button, x52 y274 w36 h22 gHide, h&ide
Gui, Add, Button, x90 y274 w35 h22 gBye, &quit

; Adds Texts
Gui, Font, s10, Tahoma
Gui, Add, Text, x28 y307 w100 h17 vTxt, AeroZoom %verAZ%
Gui, Font, norm

; Set Title, Window Size and Position
Gui, Show, h361 w140 x%xPos2% y%yPos2%, `r

; Always On Top
Gui, +AlwaysOnTop

; Adds Menus
Menu, HelpMenu, Add, &Instructions, Instruction
Menu, HelpMenu, Add, &Check for update, CheckUpdate
Menu, HelpMenu, Add, &Read me, Readme
Menu, HelpMenu, Add, &About, HelpAbout

; Menu, FileMenu, Add, &Show magnifier`t[Right]+[Wheel-up], EnableAZ
; Menu, FileMenu, Add, &Kill magnifier`t, DisableAZ
; Menu, FileMenu, Add, &Restore defaults, ResetDefaultsAZ
; Menu, FileMenu, Add, &Reset zoom`t[Right]+[Middle], ResetZoomLevelAZ
; Menu, FileMenu, Add, &Pause / Resume`t[Alt]+[O], PauseScriptAZ
Menu, FileMenu, Add, &Hide this`t[ESC], HideAZ
Menu, FileMenu, Add, E&xit AeroZoom`t[Alt]+[Q], ExitAZ

; Create the menu bar by attaching the sub-menus to it:
Menu, MyBar, Add, &File, :FileMenu
Menu, MyBar, Add, &Help, :HelpMenu

; Attach the menu bar to the window:
Gui, Menu, MyBar
Loop 6
return

ShowMagnifier:
WinRestore Magnifier
Run,"%windir%\system32\magnify.exe",,
Gui, Destroy
return

KillMagnifier:
; Run,"%windir%\system32\taskkill.exe" /f /im magnify.exe,,Min
Process, Close, magnify.exe
Gui, Destroy
return

Default:
Process, Close, magnify.exe
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
Gui, Destroy
return

Calc:
IfWinExist Calculator
	WinActivate
else
	Run,"%windir%\system32\calc.exe",,
Gui, Destroy
return

Draw:
IfWinExist Snipping Tool
	WinActivate
else
	Run,"%windir%\system32\SnippingTool.exe",,
Gui, Destroy
return

Type:
IfWinExist Document - WordPad
	WinActivate
else
	Run,"%ProgramFiles%\Windows NT\Accessories\wordpad.exe",,
Gui, Destroy
return

Color:
Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,Invert
if (magnifierSetting=0x1) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x1
}
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
Gui, Destroy
Return

Mouse:
Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowMouse
if (magnifierSetting=0x1) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x0
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
}
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
Gui, Destroy
Return

Keyboard:
Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowFocus
if (magnifierSetting=0x1) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x1
}
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
Gui, Destroy
Return

Text:
Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowCaret
if (magnifierSetting=0x1) {
  RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
} else {
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x1
}
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
Gui, Destroy
Return

PauseScript:
if (paused=0) {
	paused = 1
} else {
	paused = 0
}
Gui, Destroy
return

Hide:
Gui, Destroy
return

Bye:
Process, Close, magnify.exe
ExitApp
return

PauseScriptAZ:
if (paused=0) {
	paused = 1
} else {
	paused = 0
}
return

ResetZoomLevelAZ:
Process, Close, magnify.exe
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
return

ResetDefaultsAZ:
Process, Close, magnify.exe
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
Sleep, 10
Run,"%windir%\system32\Magnify.exe",,
return

EnableAZ:
WinRestore Magnifier
Run,"%windir%\system32\magnify.exe",,
return

DisableAZ:
Process, Close, magnify.exe
return

HideAZ:
Gui, Destroy
return

ExitAZ:
Process, Close, magnify.exe
ExitApp
return

Instruction:
Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui +Disabled  ; Disable main window.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Mouse Buttons Instructions (Left-handed version)
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, , This panel`t=> [Right] + [Left]`nShow magnifier`t=> [Right] + [Wheel-up]`nReset zoom`t=> [Right] + [Middle]`nZoom in  `t=> hold [Right] + [Wheel-up]`nZoom out`t=> hold [Right] + [Wheel-down]
Gui, 2:Font, norm, 
Gui, 2:Add, Button, x256 y138 h30 w60 Default, OK
Gui, 2:Show, , Instructions
return

Readme:
Run,"%windir%\system32\notepad.exe" "%A_WorkingDir%\Data\readme.txt"
return

CheckUpdate:
GuiControl,1:,Txt,- Please Wait -
Gui, -AlwaysOnTop   ; To let the update check popup message show on top after checking, which is done thru batch and VBScript.
RunWait, "%comspec%" /c "%A_WorkingDir%\Data\_updateCheck.bat" /quiet, , Min
Gui, +AlwaysOnTop
GuiControl,1:,Txt, AeroZoom %verAZ%
WinActivate
Return

HelpAbout:
Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui +Disabled  ; Disable main window.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , AeroZoom %verAZ%
; Gui, 2:Font, norm,
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, , Mouse Control for Windows 7 Magnifier`n-- written using AutoHotKey`n`nIf you have any suggestion, please contact`nme at wandersick@gmail.com
Gui, 2:Font, norm,
Gui, 2:Add, Button, x206 y130 h30 w60 Default, OK
Gui, 2:Show, , About
return

2ButtonOK:  ; This section is used by the "about box" above.
2GuiClose:   ; On "Close" button press
2GuiEscape:   ; On ESC press
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Destroy  ; Destroy the about box.
return

GuiEscape:    ; On ESC press
Gui, Destroy  ; Hide (destroy) the Gui
return

GuiClose:   ; On "Close" button press
Gui, Destroy  ; Hide (destroy) the Gui
return

; AeroZoom by wanderSick | http://wandersick.blogspot.com
