; AeroZoom by WanderSick | http://wandersick.blogspot.com

; Sorry for the bad/messy commenting in advance.
; Some codes may be duplicated. They are better put in a subroutine. Maybe next version.
; If you have any questions, email me at wandersick@gmail.com

; * For each modifier.ahk, add panel launching, e.g. in Ctrl.ahk, add ^RButton:: ... (Search 'undocumented') if not x1 or x2, remove: Gosub, ZoomPad
; * For middle.ahk, uncomment mbutton & rbutton, mbutton & lbutton.
;   replace mbutton:: with ~MButton & LButton:: and delete some lines there
;   disable 'hold middle to snip/still zoom' by uncommenting line 134x
; * For x1.ahk and x2.ahk, uncomment the huge commented block (search for ;;) change x2 to x1 or x1 to x2 for some bits
;   in x1/x2 the undocumented part must contain: Gosub, ZoomPad (rename x1 to x2 if needed, and vice versa)

; Before release
; - Set read-only flag for Readme and Tips, bat vbs
; - Delete wget.gid
; - Be sure to update the updater.bat search terms
; - Check setup.ahk for more things
; - Update Product version in .ahk.ini

; Remember to create separate x64 executables (note: .ahk and _x64.ahk are exactly the same scripts. just compile them with different compilers)
; _x64.ahk.ini aren't used because Compile AHK II doesnt seem to support 64bit AutoHotkey_L
; Compile x64 executables with AutoHotkey_L (Installation being Unicode 64bit)
; Compile x84 with AutoHotkey (old version) to keep size small...

#Persistent
#SingleInstance force
SetBatchLines -1 ; run at fastest speed before init

IfEqual, unattendAZ, 1
	goto Install

verAZ = 2.0a
paused = 0

; Working directory check
IfNotExist, %A_WorkingDir%\Data
{
	Msgbox, 262192, AeroZoom, Wrong working directory. Ensure AeroZoom is not run from its sub-folder.
	ExitApp
}

RegRead,OSver,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentVersion
if (OSver<6.1) {
	Msgbox, 262144, AeroZoom, You're using an OS earlier than Windows 7. Expect abnormal behaviors.
} else if (OSver>6.1) {
	RegRead,newOSwarning,HKCU,Software\WanderSick\AeroZoom,newOSwarning
	if errorlevel
	{
		Msgbox, 262144, This message will be shown once only, You're using an newer operating system AeroZoom may not totally support.`n`nPlease check http://wandersick.blogspot.com if there's a new version available.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, newOSwarning, 1
	}
}

; if not A_IsAdmin
; {
;   DllCall("shell32\ShellExecuteA", uint, 0, str, "RunAs", str, A_AhkPath
;      , str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)  ; Last parameter: SW_SHOWNORMAL = 1
;   ExitApp
;}

menu, tray, add
; When the user double-clicks the tray icon, its default menu item is launched (show panel). 
menu, tray, add, Show/hide Panel, showPanel
menu, tray, Default, Show/Hide Panel
Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom.ico

; Retrieve hold middle setting
	
RegRead,holdMiddle,HKCU,Software\WanderSick\AeroZoom,holdMiddle
if errorlevel ; if the key is never created, i.e. first-run
{
	holdMiddle=1 ; hold middle button to snip/still zoom by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, holdMiddle, 1
}

; RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,Invert
; If last set, reflect color inversion immediately

; Whether to use Zoom Increment slider or Magnification slider
RegRead,SwitchZoomInc,HKCU,Software\WanderSick\AeroZoom,SwitchZoomInc
if errorlevel
	SwitchZoomInc=1
	
; Whether to use Mini mode or Normal mode
RegRead,SwitchMiniMode,HKCU,Software\WanderSick\AeroZoom,SwitchMiniMode

RegRead,hideOrMin,HKCU,Software\WanderSick\AeroZoom,HideOrMin ; hide (1) or minimize (2) or do neither (3)
if errorlevel
	HideOrMin=1
RegRead,hideOrMinPrev,HKCU,Software\WanderSick\AeroZoom,HideOrMin
if errorlevel
	HideOrMinPrev=1 ; Prev is for Advanced Options


; Retrieve last window positions. Applied if any of the radio buttons (except its own) is triggered.
; Otherwise, after launching script, window will not popup until user press left and right buttons
; where the position will be the MousePos at that time instead.

lastPosX=
lastPosY=
RegRead,lastPosX,HKCU,Software\WanderSick\AeroZoom,lastPosX
if not errorlevel
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX ; prevent it from reuse
RegRead,lastPosY,HKCU,Software\WanderSick\AeroZoom,lastPosY
if not errorlevel
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY

; Retrieve Notepad settings from Registry
; REG_SZ. 1 = use notepad. Otherwise, use WordPad (if customEdCheckbox is 1, then no Notepad/Wordpad)

RegRead,notepad,HKCU,Software\WanderSick\AeroZoom,Notepad

; Retrieve ZoomPad settings from Registry
; REG_SZ. 1 = disable ZoomPad.

RegRead,ZoomPad,HKCU,Software\WanderSick\AeroZoom,ZoomPad
if errorlevel ; if the key is never created, i.e. first-run
{
	zoomPad=1 ; zoom pad on by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, ZoomPad, 1
}


; Retrieve Sysinternals ZoomIt preference from Registry
; REG_SZ. 1 = enhance with ZoomIt. Otherwise, use Win 7 tools

RegRead,zoomit,HKCU,Software\WanderSick\AeroZoom,zoomit
if (zoomit=1) {
	Process, Exist, ZoomIt.exe
	If (errorlevel=0) {
		IfExist, %A_WorkingDir%\Data\ZoomIt.exe
		{
			Run, %A_WorkingDir%\Data\ZoomIt.exe
		}
	}
}

; ----------------------------------------------------- Radio Button 1 of 3 (Retrieve setting)

; Retrieve last checked radio button from Registry

RegRead,chkModRaw,HKCU,Software\WanderSick\AeroZoom,Modifier
if (chkModRaw=0x1) {
	chkCtrl=Checked
	chkMod=1
	modDisp=Ctrl key
} else if (chkModRaw=0x2) {
	chkAlt=Checked
	chkMod=2
	modDisp=Alt key
} else if (chkModRaw=0x3) {
	chkShift=Checked
	chkMod=3
	modDisp=Shift key
} else if (chkModRaw=0x4) {
	chkWin=Checked
	chkMod=4
	modDisp=Windows key
} else if (chkModRaw=0x5) {
	chkMouseL=Checked
	chkMod=5
	modDisp=Left mouse button
} else if (chkModRaw=0x6) {
	chkMouseR=Checked
	chkMod=6
	modDisp=Right mouse button
} else if (chkModRaw=0x7) {
	chkMouseM=Checked
	chkMod=7
	modDisp=Middle mouse button
} else if (chkModRaw=0x8) {
	chkMouseX1=Checked
	chkMod=8
	modDisp=Forward (Special)
} else if (chkModRaw=0x9) {
	chkMouseX2=Checked
	chkMod=9
	modDisp=Back (Special)
} else {
	chkMouseL=Checked
	chkMod=5
	modDisp=Left mouse button
}
; ----------------------------------------------------- Radio Button 1 of 3 END


; ----------------------------------------------------- Zoom Increment 1 of 3 (Retrieve last setting)

; Retrieve Zoom Increment and magnification from Registry to preset the slider

Gosub, ReadValueUpdatePanel
; ----------------------------------------------------- Zoom Increment 1 of 3 END

; Retrieve Advanced Options settings (Once more when opening Advanced Options menu
RegRead,panelX,HKCU,Software\WanderSick\AeroZoom,panelX
if errorlevel
{
	panelX=15 ; default offset value if unset
}
RegRead,panelY,HKCU,Software\WanderSick\AeroZoom,panelY
if errorlevel
{
	panelY=160
}
RegRead,panelTrans,HKCU,Software\WanderSick\AeroZoom,panelTrans
if errorlevel
{
	panelTrans=255
}
RegRead,stillZoomDelay,HKCU,Software\WanderSick\AeroZoom,stillZoomDelay
if errorlevel
	stillZoomDelay=650
RegRead,stillZoomDelayPrev,HKCU,Software\WanderSick\AeroZoom,stillZoomDelay
if errorlevel
	stillZoomDelayPrev=650 ; Prev is for Advanced Options
	

RegRead,delayButton,HKCU,Software\WanderSick\AeroZoom,delayButton
if errorlevel
	delayButton=100
RegRead,delayButtonPrev,HKCU,Software\WanderSick\AeroZoom,delayButton
if errorlevel
	delayButtonPrev=100 ; Prev is for Advanced Options
	
RegRead,customEdCheckbox,HKCU,Software\WanderSick\AeroZoom,customEdCheckbox
RegRead,customEdPath,HKCU,Software\WanderSick\AeroZoom,customEdPath

RegRead,customCalcCheckbox,HKCU,Software\WanderSick\AeroZoom,customCalcCheckbox
RegRead,customCalcPath,HKCU,Software\WanderSick\AeroZoom,customCalcPath



; this and tips must be placed after script init, before hotkey monitoring

; run magnifier minimized/hidden at start, unlike in v1 which was at zoom in
; advantages:  Magnifier does not show anymore on first zoom, and no more Ease
;              Of Access Center pop-ups thanks to this design.

Process, Exist, magnify.exe
if not errorlevel
{
	Run,"%windir%\system32\magnify.exe",,Min ; Min does not work for magnify.exe, hence the below
	if not (hideOrMin=3) ; if hideOrMin=3, dont hide or minimize
	{	
			WinWait, ahk_class MagUIClass,,5 ; Loop to hide Windows Magnifier
			if not ErrorLevel
			{
				if (hideOrMin=1) {
					WinMinimize, ahk_class MagUIClass ; minimize before hiding to remove the floating magnifier glass
					WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only
				} else if (hideOrMin=2) {					
					WinMinimize, ahk_class MagUIClass
				}
			}
		
	}
}
SetBatchLines, 10ms

RegRead,reload,HKCU,Software\WanderSick\AeroZoom,reload
if not errorlevel
{
	reload=
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload
	goto, skipTips
}

; First run welcome msg
RegRead,Welcome,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,Welcome
if not Welcome
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Welcome, 1
	Msgbox, 262148, AeroZoom %verAZ% Welcome, Welcome to the new AeroZoom!`n`nThere're quite a few improvements in this release. For example:`n - New mouse enhancements for Magnifier/Snipping Tool/ZoomIt (opt)`n - Mac OS X zoom, single-finger zoom, sliders, holding Middle button as trigger`n - Zoom one-handed in PowerPoint live without misclicking on slides.`n - Quickly preview full screen and move to other areas without zoom-out.`n - Mouse drag to capture regions of screen for annotation.`n`nTo learn all about the features, visit 'AeroZoom on the Web' via the help menu.`n`nWould you like to learn about AeroZoom and receive tips on start?
	IfMsgBox, No
	{
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, TipDisabled, 1 ; disabled bit is used so when enabled will continue where users left off
	}
	Else 
	{
		RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, TipDisabled
	}
	;goto, skipTips
}

Tips:
RegRead,TipDisabled,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,TipDisabled
if not TipDisabled
{
	RegRead,Tip,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,Tip
	if errorlevel
	{
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Tip, 1
		Tip := 1
	}
	if (Tip>=1) {
		FileReadLine, line, %A_WorkingDir%\Data\Tips_and_Tricks.txt, %tip%
		if errorlevel ; if the end is reached
		{
			RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Tip ; read tip from beginning of file again
			goto Tips
		}
		Msgbox, 262468, AeroZoom %verAZ% Tips and Tricks #%tip%, %line%`n`n--`nRead next tip? (Tips can be disabled in '?' menu)
		Tip += 1
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Tip, %Tip%
		;IfMsgBox, Cancel
		;{
		;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, TipDisabled, 1
		;}
		IfMsgBox, Yes
		{
			RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, TipDisabled
			goto, Tips
		}
	}
}

skipTips:

; --------------- Hotkey monitoring starts here

; if lastPosY and lastPosX are not 0 or undefined, use it as the last position
; this block must be placed above all hotkey assignment lines for it to load.
if lastPosY {
	if lastPosX {
		; Msgbox test1
		goto, lastPos ; to skip ~LButton & RButton::
	}
} 

; Msgbox test2

; Prevent closing ZoomIt Zoom Window
~!F4::
IfWinActive, ahk_class ZoomitClass
{
	Msgbox, 262144, Information, To prevent from crashing, instead of pressing [Alt+F4], hold the [Middle] button, right click or use the [Esc] key to exit any active ZoomIt window.
	Process, Close, zoomit.exe
	Process, Close, zoomit64.exe
	IfExist, %A_WorkingDir%\Data\ZoomIt.exe
		Sleep, 250
		Run, %A_WorkingDir%\Data\ZoomIt.exe
	return
}
return

; Update panel's magnification sldier while using keyboard to zoom

~#NumpadAdd::
~#NumpadSub::
~#-::
; ~#+:: <<-- since there is no way to specify this in AHK
~LWin & ~+::
~RWin & ~+::
If not SwitchZoomInc
{
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
	Gosub, ReadValueUpdatePanel ; this will update the slider on the panel in real-time
}
return

; Alternative keyboard shortcuts

; ZoomIncrement
#!F1::
zoomInc=1
; update/refresh GUI with new slider setting
GuiControl,, ZoomInc, 1
goto, SliderX

#!F2::
zoomInc=2
GuiControl,, ZoomInc, 2
goto, SliderX

#!F3::
zoomInc=3
GuiControl,, ZoomInc, 3
goto, SliderX

#!F4::
zoomInc=4
GuiControl,, ZoomInc, 4
goto, SliderX

#!F5::
zoomInc=5
GuiControl,, ZoomInc, 5
goto, SliderX

#!F6::
zoomInc=6
GuiControl,, ZoomInc, 6
goto, SliderX

; Color
#!I::
goto, Color

; Mouse
#!M::
goto, Mouse

; Keyboard
#!K::
goto, Keyboard

; Text
#!T::
goto, Text

; the following updates the viewsmenu on calling these hotkeys before executing them (~)
; View Full Screen
~^!F::
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Menu, ViewsMenu, Check, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
}
return

; View Lens
~^!L::
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Check, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
}
return

; View Docked
~^!D::
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Check, &Docked`tCtrl+Alt+D
}
return

; ----------------------------------------------------- Left Button Assignment START

~RButton & WheelUp::
if not (paused=1) {
	Gosub, ZoomPad
	; send {LWin down}{NumpadAdd}{LWin up}
	; the following is used instead instead of 'send' for better performance
	sendinput #{NumpadAdd}
	IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
	{
		Gosub, ReadValueUpdatePanel
	}
}
return

~RButton & WheelDown::
if not (paused=1) {
	; only enable zoompad when modifier is a mouse button
	if (chkMod>4)
	{	
		if zoomPad ; if zoompad is NOT disabled
		{
			IfWinNotActive, ahk_class AutoHotkeyGUI, AeroZoom ;if current win is not the panel (zooming over the panel does not require zoompad)
			{
				RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification ; when zooming out even if already unzoomed, do not activate zoompad
				if not (MagnificationRaw=0x64)
				{
					IfWinExist, AeroZoom Pad ; ZoomPad to prevent accidental clicks
					{
						WinActivate
					} else {
						Run, "%A_WorkingDir%\Data\ZoomPad.exe"
					}
				}
			}
		}
	}
	sendinput #{NumpadSub}
	IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
	{
		Gosub, ReadValueUpdatePanel
	}
}
return

; Run,"%windir%\system32\reg.exe" add HKCU\Software\Microsoft\ScreenMagnifier /v Magnification /t REG_DWORD /d 0x64 /f,,Min

; New snip

#!s::
Gosub, SnippingTool
return

; Pause hotkeys

#!o::
; IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
; {
;	Gui, Destroy
; }
goto, PauseScript
; suspend was not used because panel cannot be activated by mouse

; Reset magnifier
#!r::
; dontHideMag = 1 ; dont hide magnifier window for keyboard shortcuts
goto, default

; Reset all settings (this is a secret feature)
#!+r::
CheckboxRestoreDefault=1
goto, 3ButtonOK

; Reset zoom
#+-::
; dontHideMag = 1 ; dont hide magnifier window for keyboard shortcuts
goto, resetZoom

#+NumpadSub::
; dontHideMag = 1
goto, resetZoom

~RButton & MButton::
; dontHideMag = 0
if not (paused=1) {
	Gosub, ZoomPad
	goto, resetZoom
}
return

; for Middle mode only:
;~MButton & RButton::
;goto, resetZoom

resetZoom:
; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}
Process, Close, magnify.exe
GuiControl,, Magnification, 1
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
sleep, %delayButton%
Run,"%windir%\system32\magnify.exe",,Min

	WinWait, ahk_class MagUIClass,,3 


; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}
return

~MButton:: ; in MButton ahk, this is changed to ~MButton & LButton::
if not holdMiddle ; in MButton ahk, this is removed
	return ; in MButton ahk, this is removed
if not (paused=1) {
	MouseGetPos, oldX, oldY, ; in MButton ahk, this is removed
	sleep %stillZoomDelay% ; in MButton ahk, this is removed
	if GetKeyState("MButton") ; in MButton ahk, this is removed
	{
		Process, Exist, ZoomIt.exe
		If errorlevel
		{
			MouseGetPos, newX, newY,  ; in MButton ahk, this is removed
			if Abs(newX - oldX) > 200 || Abs(newY - oldY) > 200  ; in MButton ahk, this is removed
				return  ; in MButton ahk, this is removed
			RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
			if (MagnificationRaw<>0x64) ; if magnificationRaw is NOT 100 (0x64, i.e. zoomed out), then preview full screen
				goto, ViewPreview
			WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
			sendinput ^1
			WinWait, ahk_class ZoomitClass,,5
			WinWaitClose, ahk_class ZoomitClass
			If onTopBit
				WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
			Else
				WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
		} else {
			RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
			if (MagnificationRaw<>0x64) ; if magnificationRaw is NOT 100 (0x64, i.e. zoomed out), then preview full screen
				goto, ViewPreview
			Gosub, SnippingTool
		}
	}
}
return

;; the following only applies for X1 X2 modifiers and does not exist in other ahk
;; except this one, rename others to XButton1 in X2.ahk and vice versa
;~XButton2 & LButton:: ; this is the same as holding the Middle button except you dont need to hold it
;if not (paused=1) {
;	Process, Exist, ZoomIt.exe
;	If errorlevel
;	{
;		RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
;		if (MagnificationRaw<>0x64) ; if magnificationRaw is NOT 100 (0x64, i.e. zoomed out), then preview full screen
;		{
;			Gosub, ZoomPad
;			goto, ViewPreview
;		}
;		WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
;		sendinput ^1
;		WinWait, ahk_class ZoomitClass,,5
;		WinWaitClose, ahk_class ZoomitClass
;		If onTopBit
;			WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
;		Else
;			WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
;	} else {
;		RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
;		if (MagnificationRaw<>0x64) ; if magnificationRaw is NOT 100 (0x64, i.e. zoomed out), then preview full screen
;		{
;			Gosub, ZoomPad
;			goto, ViewPreview
;		}
;		; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
;		RegRead,padStayTime,HKCU,Software\WanderSick\AeroZoom,padStayTime
;		if errorlevel
;		{
;			padStayTime=150
;		}
;		padStayTimeTemp:=padStayTime*2 ; *2 is needed. see zoompad.ahk
;		Gosub, ZoomPad
;		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
;		Gosub, SnippingTool
;	}
;}
;return

;~XButton1 & LButton:: ; Break Timer if ZoomIt is enabled; otherwise, toggle Color
;if not (paused=1) {
;	Process, Exist, ZoomIt.exe
;	If errorlevel
;	{	
;		WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
;		sendinput ^3
;		WinWait, ahk_class ZoomitClass,,5
;		WinWaitClose, ahk_class ZoomitClass
;		If onTopBit
;			WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
;		Else
;			WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
;	} else {
;		Gosub, ZoomPad
;		goto, Color
;	}
;}
;return

;~XButton1 & MButton:: ; this resets the zoom increment only
;if (paused=1)
;	return

;Gosub, ZoomPad

;; check if a last magnifier window is available and record its status
;; so that after it restores it will remain hidden/minimized/normal

;; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
;; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
;Process, Exist, magnify.exe
;If errorlevel
;{
;	IfWinExist, ahk_class MagUIClass
;	{
;		WinGet, chkMin, MinMax, ahk_class MagUIClass
;		if (chkMin<0) { ; minimized
;			hideOrMinLast=2 ; minimized
;		} else {
;			hideOrMinLast=3 ; normal
;		}
;	} else {
;		hideOrMinLast=1 ; hidden
;	}
;} else {
;	hideOrMinLast= ; if not defined, use default settings
;}
;Process, Close, magnify.exe
;GuiControl,, ZoomInc, 3
;RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
;sleep, %delayButton%
;Run,"%windir%\system32\magnify.exe",,Min

;	WinWait, ahk_class MagUIClass,,3 


;; Hide or minimize or normalize magnifier window
;If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
;	if (hideOrMin=1) {
;		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
;		WinHide, ahk_class MagUIClass
;	} else if (hideOrMin=2) {
;		WinMinimize, ahk_class MagUIClass
;	}
;} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
;	WinMinimize, ahk_class MagUIClass
;	WinHide, ahk_class MagUIClass
;} else if (hideOrMinLast=2) {
;	WinMinimize, ahk_class MagUIClass
;}
;return

;~XButton1 & RButton:: ; show magnifier
;if (paused=1)
;	return
;Gosub, ZoomPad
;sleep, 500 ; prevent zoompad from misplacing (workaround)
;goto, ShowMagnifier
;return

;~XButton1 & Wheelup:: ; increase the zoom increment one step
;if (paused=1)
;	return
;Gosub, ZoomPad
;IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
;	ExistAZ=1
;RegRead,zoomIncRaw,HKCU,Software\Microsoft\ScreenMagnifier,ZoomIncrement
;if (zoomIncRaw=0x19) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 2
;	zoomInc=2
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x32
;} else if (zoomIncRaw=0x32) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 3
;	zoomInc=3
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
;} else if (zoomIncRaw=0x64) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 4
;	zoomInc=4
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x96
;} else if (zoomIncRaw=0x96) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 5
;	zoomInc=5
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0xc8
;} else if (zoomIncRaw=0xc8) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 6
;	zoomInc=6
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x190
;}
;ExistAZ=

;; check if a last magnifier window is available and record its status
;; so that after it restores it will remain hidden/minimized/normal

;; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
;; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
;Process, Exist, magnify.exe
;If errorlevel
;{
;	IfWinExist, ahk_class MagUIClass
;	{
;		WinGet, chkMin, MinMax, ahk_class MagUIClass
;		if (chkMin<0) { ; minimized
;			hideOrMinLast=2 ; minimized
;		} else {
;			hideOrMinLast=3 ; normal
;		}
;	} else {
;		hideOrMinLast=1 ; hidden
;	}
;	Process, Close, magnify.exe ; !!!!!! If magnifier is running, rerun Magnifier to apply the setting
;	sleep, %delayButton%
;	Run,"%windir%\system32\magnify.exe",,Min
;} else {
;	hideOrMinLast= ; if not defined, use default settings
;}

;	WinWait, ahk_class MagUIClass,,3 

;; Hide or minimize or normalize magnifier window
;If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
;	if (hideOrMin=1) {
;		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
;		WinHide, ahk_class MagUIClass
;	} else if (hideOrMin=2) {
;		WinMinimize, ahk_class MagUIClass
;	}
;} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
;	WinMinimize, ahk_class MagUIClass
;	WinHide, ahk_class MagUIClass
;} else if (hideOrMinLast=2) {
;	WinMinimize, ahk_class MagUIClass
;}

;return

;~XButton1 & Wheeldown:: ; decrease the zoom increment one step
;if (paused=1)
;	return
;Gosub, ZoomPad
;IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
;	ExistAZ=1
;	
;	
;RegRead,zoomIncRaw,HKCU,Software\Microsoft\ScreenMagnifier,ZoomIncrement
;if (zoomIncRaw=0x32) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 1
;	zoomInc=1
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x19
;} else if (zoomIncRaw=0x64) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 2
;	zoomInc=2
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x32
;} else if (zoomIncRaw=0x96) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 3
;	zoomInc=3
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
;} else if (zoomIncRaw=0xc8) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 4
;	zoomInc=4
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x96
;} else if (zoomIncRaw=0x190) {
;	if ExistAZ
;		GuiControl,, ZoomInc, 5
;	zoomInc=5
;	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0xc8
;}
;ExistAZ=

;; check if a last magnifier window is available and record its status
;; so that after it restores it will remain hidden/minimized/normal

;; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
;; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
;Process, Exist, magnify.exe
;If errorlevel
;{
;	IfWinExist, ahk_class MagUIClass
;	{
;		WinGet, chkMin, MinMax, ahk_class MagUIClass
;		if (chkMin<0) { ; minimized
;			hideOrMinLast=2 ; minimized
;		} else {
;			hideOrMinLast=3 ; normal
;		}
;	} else {
;		hideOrMinLast=1 ; hidden
;	}
;	Process, Close, magnify.exe ; !!!!!! If magnifier is running, rerun Magnifier to apply the setting
;	sleep, %delayButton%
;	Run,"%windir%\system32\magnify.exe",,Min
;} else {
;	hideOrMinLast= ; if not defined, use default settings
;}

;	WinWait, ahk_class MagUIClass,,3 

;; Hide or minimize or normalize magnifier window
;If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
;	if (hideOrMin=1) {
;		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
;		WinHide, ahk_class MagUIClass
;	} else if (hideOrMin=2) {
;		WinMinimize, ahk_class MagUIClass
;	}
;} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
;	WinMinimize, ahk_class MagUIClass
;	WinHide, ahk_class MagUIClass
;} else if (hideOrMinLast=2) {
;	WinMinimize, ahk_class MagUIClass
;}

;return


; Show/hide magnifier by Win + Ctrl + ESC
#+`::
goto, ShowMagnifier

; Show/hide panel by Win + Shift + ESC
#+ESC::
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Gui, Destroy
	return
}
;Gui, Destroy
goto, lastPos

; Show/hide panel by tray (center it)
showPanel:
centerPanel = 1
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Gui, Destroy
	return
}
;Gui, Destroy
goto, lastPos

; Normal way to launch AeroZoom panel (Right-handed)
~LButton & RButton::
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Gui, Destroy
	return
}
;Gui, Destroy
goto, lastPos

; Normal way to launch AeroZoom panel (Left-handed)
~RButton & LButton::
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Gui, Destroy
	return
}
;Gui, Destroy
goto, lastPos

;; Undocumented way to launch AeroZoom panel
;~XButton1 & RButton::
;IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
;{
;	Gosub, ZoomPad
;	Gui, Destroy
;	return
;}
;goto, lastPos

; Additional way to launch AeroZoom panel as backup
; ~MButton & LButton::
; Gui, Destroy
; goto, lastPos

lastPos:

Gui, Destroy ; ensure running Gui is impossible (otherwise strange errors)
	
if lastPosY
{
	if lastPosX
	{
		xPos2=%lastPosX%
		yPos2=%lastPosY%
		lastPosX=0 ; cleared to prevent reuse
		lastPosY=0
		; Msgbox test3
	}
} else {
		; if lastpos is 0 or undefined, get current mospos
		MouseGetPos, xPos, yPos
		xPos2 := xPos - panelX
		yPos2 := yPos - panelY
		; Msgbox test4
}

RegRead,customTypeMsg,HKCU,Software\WanderSick\AeroZoom,customTypeMsg
if errorlevel ; if the key is never created, i.e. first-run
{
	customTypeMsg=T&ype ; default value
}
RegRead,customCalcMsg,HKCU,Software\WanderSick\AeroZoom,customCalcMsg
if errorlevel ; if the key is never created, i.e. first-run
{
	customCalcMsg=&Calc ; default value
}
RegRead,legacyKill,HKCU,Software\WanderSick\AeroZoom,legacyKill
if errorlevel
	legacyKill=2 ; 1 = Yes 2 = No
RegRead,legacyKillPrev,HKCU,Software\WanderSick\AeroZoom,legacyKill
if errorlevel
	legacyKillPrev=2 ; Prev is for Advanced Options
RegRead,keepSnip,HKCU,Software\WanderSick\AeroZoom,keepSnip
if errorlevel
	keepSnip=2 ; 1 = Yes 2 = No
RegRead,keepSnipPrev,HKCU,Software\WanderSick\AeroZoom,keepSnip
if errorlevel
	keepSnipPrev=2 ; Prev is for Advanced Options
	
startUpChk=1
Gosub, updateMouseTextKB

; ----------------------------------------------------- Left Button Assignment END

; Adds Buttons
Gui, -MinimizeBox -MaximizeBox  ; Disable Minimize and Maximize button on Title bar

If SwitchZoomInc
{
	; ----------------------------------------------------- Zoom Increment 2 of 3 (Add to GUI)
	; Add a slider for Zoom Increment, the preset level is %zoominc% which was retrieved from registry
	; Variable (user-selected increment) is to be stored in ZoomInc(vZoomInc)
	; SliderX(gSliderX) is the subroutine to be performened
	Gui, Add, Slider, TickInterval1 Range1-6 x12 y3 w120 h25 vZoomInc gSliderX, %zoominc%
	ZoomInc_TT := "Set how much the view changes when zooming in or out"
	; ----------------------------------------------------- Zoom Increment 2 of 3 END
} else {
	Gosub, ReadValueUpdatePanel
	if (ZoomInc=1) {
		Gui, Add, Slider, x12 y3 w120 h25 Range1-61 vMagnification gSliderMag, %Magnification%
	} else if (ZoomInc=2) {
		Gui, Add, Slider, x12 y3 w120 h25 Range1-31 vMagnification gSliderMag, %Magnification%
	} else if (ZoomInc=3) {
		Gui, Add, Slider, x12 y3 w120 h25 Range1-16 vMagnification gSliderMag, %Magnification%
	} else if (ZoomInc=4) {
		Gui, Add, Slider, x12 y3 w120 h25 Range1-11 vMagnification gSliderMag, %Magnification%
	} else if (ZoomInc=5) {
		Gui, Add, Slider, x12 y3 w120 h25 Range1-9 vMagnification gSliderMag, %Magnification%
	} else if (ZoomInc=6) {
		Gui, Add, Slider, x12 y3 w120 h25 Range1-5 vMagnification gSliderMag, %Magnification%
	}
	Magnification_TT := "Slide to zoom"
}

Gui, Add, Text, x0 y0 h452 w16 gUiMove vTxt1, 
Txt1_TT := "Click to drag"
Gui, Add, Text, x125 y0 h452 w16 gUiMove vTxt2, 
Txt2_TT := "Click to drag"
; Gui, Add, Text, x0 y417 h22 w16 gUiMove vTxt3, 
; Txt3_TT := "Click to drag"
if SwitchMiniMode
{
	Gui, Add, Text, x0 y313 h11 w140 gUiMove vTxt4, 
	Txt4_TT := "Click to drag"
} else {
	Gui, Add, Text, x0 y397 h5 w140 gUiMove vTxt4, 
	Txt4_TT := "Click to drag"
}
Gui, Font, s8, Arial
Gui, Add, Button, x15 y27 w110 h43 gColor vColor, Color &Inversion
Color_TT := "Turn on/off color inversion [Win+Alt+I]"
Gui, Add, Button, x15 y70 w110 h43 gMouse vMouse, &Mouse %MouseCurrent% => %MouseNext%
Mouse_TT := "Follow the mouse pointer [Win+Alt+M]"
Gui, Add, Button, x15 y113 w110 h43 gKeyboard vKeyboard, &Keyboard %KeyboardCurrent% => %KeyboardNext%
Keyboard_TT := "Follow the keyboard focus [Win+Alt+K]"
Gui, Add, Button, x15 y156 w110 h43 gText vText, Te&xt %TextCurrent% => %TextNext%
Text_TT := "Have magnifier follow the text insertion point [Win+Alt+T]"

;WinGet, chkMin, MinMax, ahk_class MagUIClass
;if (chkMin<0) { ; if magnifier win is minimized, i.e. chkmin = -1
	Gui, Add, Button, x15 y201 w54 h28 gShowMagnifier vShowMagnifier, &Mag
	ShowMagnifier_TT := "Show/hide magnifier [Win+Shift+``]"
;} else {
;	Gui, Add, Button, x15 y201 w54 h28 gShowMagnifier vShowMagnifier, &Hide
;}

if (legacyKill=1) {
	Gui, Add, Button, x71 y201 w54 h28 gKillMagnifier vKillMagnifier, Kil&l
	KillMagnifier_TT := "Kill magnifier process"
} else {
	Gui, Add, Button, x71 y201 w54 h28 gKillMagnifier vKillMagnifier, &Paint
	KillMagnifier_TT := "Create and edit drawings"
}
if (zoomIt=1 AND KeepSnip<>1) {
	KillMagnifier_TT := "Break timer of ZoomIt [Ctrl+3]"
}
Gui, Add, Button, x15 y231 w54 h28 gDefault vDefault, &Reset
Default_TT := "Reset magnifier [Win+Alt+R]"

Gui, Add, Button, x71 y231 w54 h28 gCalc vCalc, %customCalcMsg%
if not customCalcPath
{
	if (customCalcMsg = "&Calc" OR customCalcMsg = "Calc" OR customCalcMsg = "C&alc" OR customCalcMsg = "Ca&lc" OR customCalcMsg = "Cal&c")
	{
		Calc_TT := "Show calculator" ; show tooltip only if the button is for launching the caluculator, not user-defined
	}
}

Gui, Add, Button, x15 y261 w54 h28 gDraw vDraw, &Snip
if (zoomIt=1 AND KeepSnip<>1) {
	Draw_TT := "Draw, type & still-zoom using ZoomIt [Ctrl+2]"
} else {
	Draw_TT := "Copy a portion of screen for annotation [Win+Alt+S]"
}

Gui, Add, Button, x71 y261 w54 h28 gType vType, %customTypeMsg%
if not customEdPath
{
	if (customTypeMsg = "T&ype" OR customTypeMsg = "Type" OR customTypeMsg = "&Type" OR customTypeMsg = "Ty&pe" OR customTypeMsg = "Typ&e")
	{
		Type_TT := "Show text editor"
	}
}
; Gui, Add, Button, x71 y214 w54 h28 gHide, &__


; ----------------------------------------------------- Radio Button 2 of 3 (Add to GUI)
; %chk*% checks last time's value remembered in the registry
if not SwitchMiniMode
{
	Gui, Font, CDefault, ; to word around a weird bug where all radio texts become red
	Gui, Add, Radio, %chkCtrl% -Wrap x22 y317 w38 h20 vchkMod gModifier, Ctrl
	Gui, Add, Radio, %chkAlt% -Wrap x22 y337 w35 h20 gModifier, Alt
	Gui, Add, Radio, %chkShift% -Wrap x22 y357 w42 h20 gModifier, Shift
	Gui, Add, Radio, %chkWin% -Wrap x22 y377 w38 h20 gModifier, Win
	Gui, Add, Radio, %chkMouseL% -Wrap x72 y317 w39 h20 gModifier, Left
	Gui, Add, Radio, %chkMouseR% -Wrap x72 y337 w43 h20 gModifier, Right
	Gui, Add, Radio, %chkMouseM% -Wrap x72 y357 w48 h20 gModifier, Middle
	Gui, Add, Radio, %chkMouseX1% -Wrap x72 y377 w26 h20 gModifier, F
	Gui, Add, Radio, %chkMouseX2% -Wrap x100 y377 w26 h20 gModifier, B
	; chkMod_TT := "Modifier keys: Ctrl/Alt/Shift/Winkey; mouse buttons: Left/Right/Middle/Forward/Back"
}

; ----------------------------------------------------- Radio Button 2 of 3 END

if (paused=0) {
	pausedMsg = &off
} else {
	pausedMsg = &on
}

Gui, Add, Button, x15 y291 w35 h22 gPauseScript vPauseScript, %pausedMsg%
PauseScript_TT := "Turn off/on all mouse hotkeys temporarily (except those for calling this panel) [Win+Alt+O]"
Gui, Add, Button, x52 y291 w36 h22 gHide vHide, &hide
Hide_TT := "Hide/show this panel [Win+Shift+Esc]"
Gui, Add, Button, x90 y291 w35 h22 gBye vBye, &quit
Bye_TT := "Quit AeroZoom [Q]"

; Adds Texts
Gui, Font, s10, Tahoma
if SwitchMiniMode
{
	Gui, Add, Text, x27 y324 w100 h42 vTxt gUiMove, AeroZoom %verAZ% ; v%verAZ%
} else {
	Gui, Add, Text, x27 y402 w100 h42 vTxt gUiMove, AeroZoom %verAZ% ; v%verAZ%
}
Txt_TT := "Click to drag"
Gui, Font, norm

hIcon32 := DllCall("LoadImage", uint, 0
    , str, "AeroZoom.ico"  ; Icon filename (this file may contain multiple icons).
    , uint, 1  ; Type of image: IMAGE_ICON
    , int, 32, int, 32  ; Desired width and height of image (helps LoadImage decide which icon is best).
    , uint, 0x10)  ; Flags: LR_LOADFROMFILE
Gui +LastFound
SendMessage, 0x80, 1, hIcon32  ; 0x80 is WM_SETICON; and 1 means ICON_BIG (vs. 0 for ICON_SMALL).

; IMPORTANT: Set Title, Window Size and Position
; Gui, Show, h452 w140 x%xPos2% y%yPos2%, `r
if SwitchMiniMode
{
	if centerPanel
	{
		Gui, Show, h378 w140, AeroZoom
		centerPanel=
	} else {
		Gui, Show, h378 w140 x%xPos2% y%yPos2%, AeroZoom
	}
} else {
	if centerPanel
	{
		Gui, Show, h456 w140, AeroZoom
		centerPanel=
	} else {
		Gui, Show, h456 w140 x%xPos2% y%yPos2%, AeroZoom
	}
}
OnMessage(0x200, "WM_MOUSEMOVE")

WinSet, Transparent, %panelTrans%, AeroZoom

; Adds Menus
Menu, AboutMenu, Add, &Disable Startup Tips, startupTips
Menu, AboutMenu, Add, &Quick Instructions, Instruction
Menu, AboutMenu, Add, &About, HelpAbout
; Menu, AboutMenu, Add, &Email a Bug, EmailBugs ; Cancelled due to not universally supported
Menu, AboutMenu, Add, &Check for Update, CheckUpdate
Menu, AboutMenu, Add, AeroZoom on the &Web, VisitWeb

Menu, ViewsMenu, Add, &Full Screen`tCtrl+Alt+F, ViewFullScreen
Menu, ViewsMenu, Add, &Lens`tCtrl+Alt+L, ViewLens
Menu, ViewsMenu, Add, &Docked`tCtrl+Alt+D, ViewDocked
; Menu, ViewsMenu, Add  ; empty horizontal line (messes up)
Menu, ViewsMenu, Add, &Preview Full Screen`tCtrl+Alt+Space, ViewPreview
; Menu, ViewsMenu, Add  ; empty horizontal line (messes up)
Menu, ViewsMenu, Add, &New Snip`tWin+Alt+S, SnippingTool
Menu, ViewsMenu, Add, ZoomIt - &Still Zoom`tCtrl+1, ViewStillZoom
Menu, ViewsMenu, Add, ZoomIt - &Draw`tCtrl+2, ViewDraw
Menu, ViewsMenu, Add, ZoomIt - Break &Timer`tCtrl+3, ViewBreakTimer
Menu, ViewsMenu, Add, ZoomIt - &Black Board`tCtrl+2`, K, ViewBlackBoard
Menu, ViewsMenu, Add, ZoomIt - &White Board`tCtrl+2`, W, ViewWhiteBoard

Menu, FileMenu, Add, &Hide/Show This Panel`tWin+Shift+Esc, HideAZ
; Menu, FileMenu, Add, &Hide/Show Magnifier`tWin+Shift+``, ShowMagnifier
if SwitchZoomInc
{
	Menu, FileMenu, Add, Switch to &Magnification Slider, SwitchZoomInc
} else {
	Menu, FileMenu, Add, Switch to &Zoom Increment Slider, SwitchZoomInc
}

if SwitchMiniMode
{
	Menu, FileMenu, Add, &Switch to Normal Mode, SwitchMiniMode
} else {
	Menu, FileMenu, Add, &Switch to Mini Mode, SwitchMiniMode
}

Menu, FileMenu, Add, &Quit AeroZoom`tQ, ExitAZ


; MySubmenus
IfExist, %windir%\System32\calc.exe
	Menu, MySubmenu, Add, &Calculator, WinCalc

Menu, MySubmenu, Add, ClearType Te&xt Tuner, ctTune
	
IfExist, %windir%\System32\cmd.exe
	Menu, MySubmenu, Add, Comm&and Prompt, WinCMD

IfExist, %windir%\System32\control.exe
	Menu, MySubmenu, Add, Control Pane&l, WinControl
	
Menu, MySubmenu, Add, &Ease of Access Center, easeOfAccess

IfExist, %CommonProgramFiles%\Microsoft Shared\Ink\mip.exe
	Menu, MySubmenu, Add, &Math Input Panel, WinMath

IfExist, %windir%\system32\narrator.exe
	Menu, MySubmenu, Add, Narrat&or, WinNarrator
	
IfExist, C:\Windows\System32\notepad.exe
	Menu, MySubmenu, Add, &Notepad, WinNote

IfExist, %windir%\System32\osk.exe
	Menu, MySubmenu, Add, On-Screen &Keyboard, WinKB

IfExist, %windir%\System32\mspaint.exe
	Menu, MySubmenu, Add, &Paint, WinPaint

IfExist, %windir%\System32\psr.exe
	Menu, MySubmenu, Add, Pro&blem Steps Recorder, WinPSR

IfExist, %windir%\system32\rundll32.exe
	Menu, MySubmenu, Add, &Run, WinRun



	
IfExist, %SystemRoot%\system32\SoundRecorder.exe
	Menu, MySubmenu, Add, Sound Recor&der, WinSound

IfExist, %windir%\system32\StikyNot.exe
	Menu, MySubmenu, Add, Stick&y Notes, WinSticky

IfExist, %windir%\System32\taskmgr.exe
	Menu, MySubmenu, Add, &Task Manager, WinTask
	
IfExist, %ProgramFiles%\Windows Journal\Journal.exe
	Menu, MySubmenu, Add, Windows &Journel, WinJournel

IfExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
	Menu, MySubmenu, Add, &WordPad, WinWord
	
IfExist, %windir%\Speech\Common\sapisvr.exe
	Menu, MySubmenu, Add, Windows Speech Recogn&ition, WinSpeech

Menu, ToolboxMenu, Add, &Windows Tools, :MySubmenu
Menu, ToolboxMenu, Add, &Sysinternals ZoomIt, ZoomIt
Menu, ToolboxMenu, Add, &Hold Middle as Trigger, HoldMiddle
Menu, ToolboxMenu, Add, &Misclick-Preventing Pad, UseZoomPad
Menu, ToolboxMenu, Add, Use &Notepad, UseNotepad
Menu, ToolboxMenu, Add, &Click-n-Go, ClicknGo
Menu, ToolboxMenu, Add, Always on &Top, OnTop
Menu, ToolboxMenu, Add, &Run on Startup, RunOnStartup
Menu, ToolboxMenu, Add, &Install to This Computer, Install
Menu, ToolboxMenu, Add, &ZoomIt Options, zoomitOptions
Menu, ToolboxMenu, Add, &Advanced Options, AdvancedOptions

Process, Exist, zoomit.exe
If (errorlevel=0) {
	Menu, ToolboxMenu, Disable, &ZoomIt Options
	Menu, ViewsMenu, Disable, ZoomIt - &Still Zoom`tCtrl+1
	Menu, ViewsMenu, Disable, ZoomIt - &Draw`tCtrl+2
	Menu, ViewsMenu, Disable, ZoomIt - &Black Board`tCtrl+2`, K
	Menu, ViewsMenu, Disable, ZoomIt - &White Board`tCtrl+2`, W
	Menu, ViewsMenu, Disable, ZoomIt - Break &Timer`tCtrl+3
} else {
	Menu, ToolboxMenu, Enable, &ZoomIt Options
	Menu, ViewsMenu, Enable, ZoomIt - &Still Zoom`tCtrl+1
	Menu, ViewsMenu, Enable, ZoomIt - &Draw`tCtrl+2
	Menu, ViewsMenu, Enable, ZoomIt - &Black Board`tCtrl+2`, K
	Menu, ViewsMenu, Enable, ZoomIt - &White Board`tCtrl+2`, W
	Menu, ViewsMenu, Enable, ZoomIt - Break &Timer`tCtrl+3
}

; Check Click 'n Go bit
RegRead,clickGoBit,HKCU,Software\WanderSick\AeroZoom,clickGoBit
if clickGoBit ; if  Click 'n Go bit exists and is not 0
{
	Menu, ToolboxMenu, Check, &Click-n-Go
	guiDestroy=Destroy
} else { ; else if Click 'n Go bit exists and is 0
	Menu, ToolboxMenu, Uncheck, &Click-n-Go
	guiDestroy=
}

; Check Always on Top bit
RegRead,onTopBit,HKCU,Software\WanderSick\AeroZoom,onTopBit
if errorlevel ; if the key is never created, i.e. first-run
{
	onTopBit=1 ; Always on Top by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, onTopBit, 1
}
if onTopBit ; if onTop bit exists and is not 0
{
	Menu, ToolboxMenu, Check, Always on &Top
	onTop=+AlwaysOnTop
} else { ; else if onTop bit exists and is 0
	Menu, ToolboxMenu, Uncheck, Always on &Top
	onTop=-AlwaysOnTop
}
; Set Always On Top
Gui, %onTop%

; Create the menu bar by attaching the sub-menus to it:
Menu, MyBar, Add, &Az, :FileMenu
Menu, MyBar, Add, &View, :ViewsMenu
Menu, MyBar, Add, &Tool, :ToolboxMenu
Menu, MyBar, Add, &?, :AboutMenu
	
; update view menu
StartupMagMode=1
Gosub, ReadValueUpdateMenu

; Check if notepad is preferred
if (notepad=1) {
	Menu, ToolboxMenu, Check, Use &Notepad
}

RegRead,TipDisabled,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,TipDisabled
if (TipDisabled=1) {
	Menu, AboutMenu, Check, &Disable Startup Tips
} else {
	Menu, AboutMenu, Uncheck, &Disable Startup Tips
}

; Menu, ToolboxMenu, Disable, &Hold Middle as Trigger ; uncomment in MButton.ahk

RegRead,holdMiddle,HKCU,Software\WanderSick\AeroZoom,holdMiddle
If (holdMiddle=1) {
	Menu, ToolboxMenu, Check, &Hold Middle as Trigger
} Else {
	Menu, ToolboxMenu, Uncheck, &Hold Middle as Trigger
}

; Check if zoompad is preferred
if (zoomPad=1) {
	Menu, ToolboxMenu, Check, &Misclick-Preventing Pad
}

; Check if AeroZoom is set to run in Startup in the current user startup folder
;IfExist, %A_Startup%\*AeroZoom*.*
;{
;	Menu, ToolboxMenu, Check, &Run on Startup
;}

; Below causes a huge delay in calling the AZ Panel. so now uses Reg key instead
;RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min ; check if task exist
;if (errorlevel=4) {
	;Menu, ToolboxMenu, Check, &Run on Startup
;}

RegRead,RunOnStartup,HKCU,Software\WanderSick\AeroZoom,RunOnStartup
If (RunOnStartup=1) {
	Menu, ToolboxMenu, Check, &Run on Startup
}

; Check if AeroZoom is installed on this computer
IfExist, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe
	Menu, ToolboxMenu, Check, &Install to This Computer
IfExist, %programfiles%\WanderSick\AeroZoom\AeroZoom.exe
	Menu, ToolboxMenu, Check, &Install to This Computer
IfExist, %programfiles% (x86)\WanderSick\AeroZoom\AeroZoom.exe
	Menu, ToolboxMenu, Check, &Install to This Computer

; Check if zoomit.exe is running or zoomit was perferred

if (zoomit=1) {
	Menu, ToolboxMenu, Check, &Sysinternals ZoomIt
	if not (KeepSnip=1) { ; if KeepSnip is not checked in the Advanced Options (1 = Yes; 2 = No)
		if (legacyKill=1) {
			GuiControl,, Kil&l, Tim&er
		} else {
			GuiControl,, &Paint, Tim&er
		}
		GuiControl,, &Snip, &Draw ; Change text 'Snip' to 'Draw'	
	}
}


; Attach the menu bar to the window:
Gui, Menu, MyBar

; go to subroutines to update the GUI
Gosub, ReadValueUpdatePanel

Loop 6

; record current magnifier window status (for use by settimer later)
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}


OnMessage(0x200, "WM_MOUSEMOVE")

SetTimer, updateMouseTextKB, 500 ; monitor registry for value changes

return

ShowMagnifier:
Process, Exist, magnify.exe
if errorlevel ; if running, return PID
{
	WinGet, chkMin, MinMax, ahk_class MagUIClass
	if (chkMin<0) { 
		WinShow, ahk_class MagUIClass
		WinRestore, ahk_class MagUIClass ; the old way WinRestore Magnifier may not work for non-english systems
		; GuiControl,, S&how, &Hide
	} else { ; if magnifier win is normal, chkmin=0; if minimized, chkmin=-1; if maximized, chkmin=1 (not possible for magnifier); if quit, chkmin= (cleared)
		if (hideOrMin=1) {
			WinMinimize, ahk_class MagUIClass
			WinHide, ahk_class MagUIClass
		} else {
			WinMinimize, ahk_class MagUIClass
		}
		; GuiControl,, &Hide, S&how
	}
} else { ; if not running
	Run,"%windir%\system32\magnify.exe",,
	; GuiControl,, S&how, &Hide
}
Gui, %guiDestroy%
return

KillMagnifier:
; if enhanced with ZoomIt, this will be the timer button.
if (zoomit=1 AND KeepSnip<>1) {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, %A_WorkingDir%\Data\ZoomIt.exe
		WinWait, ahk_class ZoomitClass,,3
	}
	IfWinExist, ahk_class ZoomitClass
	{
		WinActivate ; if Timer mode currently activated, send [esc] to close it
		sendinput {esc}
		;GuiControl,, Paus&e, Tim&er
	} else {
		;GuiControl,, Tim&er, Paus&e
		WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
		sendinput ^3
		WinWait, ahk_class ZoomitClass,,5
		WinWaitClose, ahk_class ZoomitClass
		If onTopBit
			WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
		Else
			WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
	}
	Gui, %guiDestroy%
		
	; the part below monitors if the break timer window is closed by user externally
	; so as to reflect the Pause/Tiemr status on the panel
	; this consumes much less cpu than a loop

	; this technique is found on the autohotkey forum shared by member SKAN:
	; http://www.autohotkey.com/forum/viewtopic.php?p=123323#123323
	; be sure to try the experiment 4 (Shell spy) to monitor the messages being received by the Shell
	;	Gui, +LastFound
	;	hWnd := WinExist()
	;	
	;	DllCall( "RegisterShellHookWindow", UInt,hWnd )
	;	MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
	;	OnMessage( MsgNum, "ShellMessageZoomIt" )
} else {
	; Run,"%windir%\system32\taskkill.exe" /f /im magnify.exe,,Min
	if (legacyKill=1)
	{
		Process, Exist, magnify.exe
		if errorlevel
		{
			Process, Close, magnify.exe
		}
		 ; GuiControl,, &Hide, S&how
		Gui, %guiDestroy%
	} else {
		; AZ v2 Runs Paint instead of Kill by default (since clicking Mag/Show button again hides it alrdy)
		IfWinExist, ahk_class MSPaintApp
			WinActivate
		else
			Run,"%windir%\system32\mspaint.exe",,
		Gui, %guiDestroy%
		If onTopBit
		{
			WinWait, ahk_class MSPaintApp,,3 ; Loop to ensure to wait until the program is run before setting it to Always on Top 
			WinSet, AlwaysOnTop, on, ahk_class MSPaintApp
		}
	}
}
return

; if zoomit timer window does not exist anymore, change the text label on the panel from Pasue to Timer 
;ShellMessageZoomIt( wParam,lParam ) {
;	if ( wParam = 4 ) { ; HSHELL_WINDOWACTIVATED - zoomit timer stopped (on [esc] press)
;		IfWinNotExist, ahk_class ZoomitClass
;		{
;			GuiControl,, Paus&e, Tim&er
;		}
;	} else if ( wParam = 32772 ) { ; UNKNOWN - zoomit timer stopped (on [esc] press)
;		IfWinNotExist, ahk_class ZoomitClass
;		{
;			GuiControl,, Paus&e, Tim&er
;		}
;	} 
;}

Default:
; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}
Process, Close, magnify.exe
GuiControl,, Magnification, 1
GuiControl,, ZoomInc, 3
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
sleep, %delayButton%
Run,"%windir%\system32\magnify.exe",,Min
; GuiControl,, &Hide, S&how
Gui, %guiDestroy%


	WinWait, ahk_class MagUIClass,,3 

; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}

return

Calc:
if customCalcCheckbox
{
	if customCalcPath
	{
		Run,"%customCalcPath%",,
		Gui, %guiDestroy%
		return
	}
}
IfWinExist, ahk_class CalcFrame
	WinActivate
else
	Run,"%windir%\system32\calc.exe",,
Gui, %guiDestroy%
	If onTopBit
	{
		WinWait, ahk_class CalcFrame,,3 ; Loop to ensure to wait until the program is run before setting it to Always on Top 
		WinSet, AlwaysOnTop, on, ahk_class CalcFrame
	}
return

Draw:
if (zoomit=1 AND KeepSnip<>1) {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, %A_WorkingDir%\Data\ZoomIt.exe
		WinWait, ahk_class ZoomitClass,,3
	}
	WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
	sendinput ^2
	WinWait, ahk_class ZoomitClass,,5
	WinWaitClose, ahk_class ZoomitClass
	If onTopBit
		WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
	Else
		WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
} else {
	Gosub, SnippingTool
}
Gui, %guiDestroy%
return


RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, ZoomItTimerTip, 1

Type:
if customEdCheckbox
{
	if customEdPath
	{
		Run,"%customEdPath%",,
		Gui, %guiDestroy%
		return
	}
}
if (notepad=1) {
	IfWinExist, ahk_class Notepad
		WinActivate
	else
		Run,"%windir%\system32\notepad.exe",,
	Gui, %guiDestroy%
	If onTopBit
	{
		WinWait, ahk_class Notepad,,3
		WinSet, AlwaysOnTop, on, ahk_class Notepad
	}
} else {
	IfWinExist, ahk_class WordPadClass
		WinActivate
	else
		Run,"%ProgramFiles%\Windows NT\Accessories\wordpad.exe",,
	Gui, %guiDestroy%
	If onTopBit
	{
		WinWait, ahk_class WordPadClass,,3
		WinSet, AlwaysOnTop, on, ahk_class WordPadClass
	}
}
return

Color:
Process, Exist, magnify.exe
if errorlevel 
	magRunning = 1
else
	magRunning =

; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
if magRunning
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}
	
Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,Invert
if (magnifierSetting=0x1) {
	if not magRunning ; if mag exe is not running BUT magnifierSetting is set to inverted, that means user's screen color is NOT inverted atm and he wants to INVERT it INSTEAD OF what clicking this button is supposed to do -- turning magnifierSetting to off (which uninverts it), simply run mag exe again would already invert the color.
	{
		goto, ColorSkip
	}
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x1
}
sleep, %delayButton%
ColorSkip:
Run,"%windir%\system32\magnify.exe",,Min
Gui, %guiDestroy%


	WinWait, ahk_class MagUIClass,,3 

; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}

Return

Mouse:

; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}

Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowMouse
if (magnifierSetting=0x1) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x0
	MouseCurrent = Off
	MouseNext = On
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
	MouseCurrent = On
	MouseNext = Off
}
sleep, %delayButton%
Run,"%windir%\system32\magnify.exe",,Min
Gui, %guiDestroy%



	WinWait, ahk_class MagUIClass,,3 

; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}


GuiControl,,Mouse,&Mouse %MouseCurrent% => %MouseNext%
Return

Keyboard:


; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}


Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowFocus
if (magnifierSetting=0x1) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
	KeyboardCurrent = Off
	KeyboardNext = On
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x1
	KeyboardCurrent = On
	KeyboardNext = Off
}
sleep, %delayButton%
Run,"%windir%\system32\magnify.exe",,Min
Gui, %guiDestroy%



	WinWait, ahk_class MagUIClass,,3 

; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}


GuiControl,,Keyboard,&Keyboard %KeyboardCurrent% => %KeyboardNext%
Return

Text:


; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}


Process, Close, magnify.exe
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowCaret
if (magnifierSetting=0x1) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
	TextCurrent = Off
	TextNext = On
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x1
	TextCurrent = On
	TextNext = Off
}
sleep, %delayButton%
Run,"%windir%\system32\magnify.exe",,Min
Gui, %guiDestroy%




	WinWait, ahk_class MagUIClass,,3 

; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}


GuiControl,,Text,Te&xt %TextCurrent% => %TextNext%
Return

PauseScript:
if (paused=0) {
	paused = 1
	Gui, Font, s9 Bold, Arial
	GuiControl,,PauseScript,&on
	GuiControl, Font, PauseScript
} else {
	paused = 0
	Gui, Font, s8 Norm, Arial
	GuiControl,,PauseScript,&off
	GuiControl, Font, PauseScript
}
Gui, %guiDestroy%
return

Hide:
HideAZ:
GuiEscape:    ; On ESC press
GuiClose:   ; On "Close" button press
Gui, Destroy
return

Bye:
Process, Close, magnify.exe
if CheckboxRestoreDefault {
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom
	RegDelete, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier
	Gui, 1:Font, CRed, 
	GuiControl,1:Font,Txt,
	GuiControl,1:,Txt,-  Restoring  -
	GuiControl,Disable,Bye
	Gui,+Disabled
	Process, Close, zoomit.exe
	Process, Close, zoomit64.exe
	IfExist, %A_WorkingDir%\Data\ZoomIt.exe
	{
		Msgbox, 262180, AeroZoom Restoration, Also delete ZoomIt and reset its hotkey? ; hotkey will be reset on next use of ZoomIt
		IfMsgBox Yes
		{
			Sleep, 1100
			FileDelete, %A_WorkingDir%\Data\ZoomIt.exe
			FileDelete, %A_WorkingDir%\Data\ZoomIt64.exe
		}
	}
}
ExitApp
return

ExitAZ:
Process, Close, magnify.exe
if CheckboxRestoreDefault {
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom
	RegDelete, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier
	Gui, 1:Font, CRed, 
	GuiControl,1:Font,Txt,
	GuiControl,1:,Txt,-  Restoring  -
	GuiControl,Disable,Bye
	Gui,+Disabled
	Process, Close, zoomit.exe
	Process, Close, zoomit64.exe
	IfExist, %A_WorkingDir%\Data\ZoomIt.exe
	{
		Msgbox, 262180, AeroZoom Restoration, Also delete ZoomIt and reset its hotkey? ; hotkey will be reset on next use of ZoomIt
		IfMsgBox Yes
		{
			Sleep, 1100
			FileDelete, %A_WorkingDir%\Data\ZoomIt.exe
			FileDelete, %A_WorkingDir%\Data\ZoomIt64.exe
		}
	}
}
ExitApp
return

Instruction:
Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui +Disabled  ; Disable main window.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Global Keyboard Shortcuts
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Full Screen`t`t=> [Ctrl] + [Alt] + [F]`nLens      `t`t=> [Ctrl] + [Alt] + [L]`nDocked    `t`t=> [Ctrl] + [Alt] + [D]`nPreview full screen`t=> [Ctrl] + [Alt] + [Space]`n`nZoom level`t`t=> [Win] + [Alt] + [F1 to F6]`nInvert color`t`t=> [Win] + [Alt] + [I]`nFollow mouse`t`t=> [Win] + [Alt] + [M]`nFollow key`t`t=> [Win] + [Alt] + [K]`nFollow text`t`t=> [Win] + [Alt] + [T]`n`nReset zoom`t`t=> [Win] + [Shift] + [-]`nReset magnifier`t=> [Win] + [Alt] + [R]`nShow|hide magnifier`t=> [Win] + [Shift] + [``]`nShow|hide panel`t=> [Win] + [Shift] + [Esc]`nNew snip`t`t=> [Win] + [Alt] + [S]`nTurn off|on hotkeys`t=> [Win] + [Alt] + [O]
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Modifier (User-defined Mouse Button)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Zoom in  `t`t=> [Modifier] + [Wheel-up]`nZoom out`t`t=> [Modifier] + [Wheel-down]`nReset zoom`t`t=> [Modifier] + [Middle]`nShow|hide panel`t=> [Left] + [Right]`nPreview full screen`t=> hold [Middle]  *when zoomed in`nNew snip`t`t=> hold [Middle]  **when zoomed out`nStill zoom on|off`t=> hold [Middle]  **requires ZoomIt
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, , Note:`tIn 'middle mode', hold [Mid] + [Right] to reset`n`tzoom, [Mid] + [Left] to snip/still-zoom/preview.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Font, CRed, 
Gui, 2:Add, Text, , At: %modDisp%
Gui, 1:Font, CDefault, 
Gui, 2:Font, s10, Arial, 
Gui, 2:Font, norm, 
Gui, 2:Add, Button, x184 y500 h30 w56 vExtraInstTemp gExtraInstButton, &Extras
ExtraInstTemp_TT := "Extra Instructions for Back/Forward Mouse Button"
Gui, 2:Add, Button, x240 y500 h30 w56 vZoomItInstTemp gZoomItInstButton, &ZoomIt
ZoomItInstTemp_TT := "ZoomIt Default Hotkeys"
Gui, 2:Add, Button, x296 y500 h30 w56 Default vOKtemp1, &OK
OKtemp1_TT := "Click to close"
Gui, 2:Show, w361 h537 , Quick Instructions
return

CheckUpdate:
Gui, 1:Font, CRed, 
GuiControl,1:Font,Txt,
GuiControl,1:,Txt,- Please Wait -
Gui, -AlwaysOnTop   ; To let the update check popup message show on top after checking, which is done thru batch and VBScript.
RunWait, "%comspec%" /c "%A_WorkingDir%\Data\_updateCheck.bat" /quiet, , Min
Gui, +AlwaysOnTop
Gui, 1:Font, CDefault, 
GuiControl,1:Font,Txt,
GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
WinActivate
Return

VisitWeb:
Run, http://wandersick.blogspot.com/p/aerozoom-for-windows-7-magnifier.html
return

HelpAbout:
Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui +Disabled  ; Disable main window.
Gui, 2:Font, s12, Arial bold, 
Gui, 2:Add, Text, , AeroZoom %verAZ%
; Gui, 2:Font, norm,
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, ,The wheel zoom and presentation kit?`nBetter Magnifier, Snipping Tool and ZoomIt?`nJust thought the idea's neat, so I created It.`n`nAn AutoHotkey-ware by a Cantonese.`nThis software is GPL so completely free.`n`nIf you like this, just love this world still.`nOr donate any $ to any cause you wish.
Gui, 2:Font, s10, Arial,
Gui, 2:Add, Text, ,Lastly if you have words to me, send it.`n@Wandersick via Gmail or tweet.
Gui, 2:Font, s10, Arial, 
;Gui, 2:Add, Text, ,Sorry for being me.
Gui, 2:Font, norm,
Gui, 2:Add, Button, x154 y249 h30 w60 vReadmetemp2, &Readme
Readmetemp2_TT := "View Readme"
Gui, 2:Add, Button, x214 y249 h30 w60 Default vOKtemp2, &OK
OKtemp2_TT := "Click to close"
Gui, 2:Show, w282 h286, About
return

ZoomItInstButton:
Msgbox, 262144, Default Hotkeys of Sysinternals ZoomIt, Operation Modes`n - Still-zoom : Ctrl+1`n - Draw : Ctrl+2`n - Break timer : Ctrl+3`n`nStill-zoom`n - Zoom in/out : Wheel up/down or arrow keys`n - Enter draw mode : Left click or press any draw mode key`n - Enter text mode : T`n`nDraw`n - Change color : R (Red) G (Green) B (Blue) Y (Yellow) P (Pink) O (Orange)`n - Undo an edit : Ctrl+Z`n - Erase all : E`n - Black board : K`n - White board : W`n - Straight line : hold Shift and drag`n - Straight arrow : hold Ctrl+Shift and drag`n - Rectangle : hold Ctrl and drag`n - Ellipse : hold Tab and drag`n - Center cursor : Space Bar`n - Undo : Ctrl+Z`n - Print screen : Ctrl+C`n - Save as PNG : Ctrl+S`n - Enter zoom mode : Wheel up/down or arrow keys`n - Enter text mode : T`n`nBreak Timer`n - Increase/decrease time : Wheel up/down or arrow keys`n`nTo change the font size in text mode : Wheel up/down or arrow keys`nTo exit a sub mode or ZoomIt : Right click or Esc (Never use Alt+F4)
return

ExtraInstButton:
Msgbox, 262144, Extra Hotkeys for Back/Forward Mouse Buttons, When using Back or Forward mouse button as a modifier, AeroZoom also makes use of the extra button to provide more features.`n`nWhat is an extra button? If you use the Back button (B) as the modifier, then the extra button would be the Forward button and vice versa, as in the following example.`n`n1: [Back+Left click] = (when unzoomed) snip/still-zoom with ZoomIt,`n(zoomed) preview full screen. *no need to hold them as holding a middle button.`n2: [Forward+Left click] = color inversion/break timer with ZoomIt.`n3: [Forward+Right click] = Show/hide Magnifier.`n4: [Forward+Wheel up] = Increase zoom increment by one step.`n5: [Forward+Wheel down] = decrease zoom increment by one step.`n6: [Forward+Middle button] = reset zoom increment to default level.`n`nBasically, this makes use of the extra button as a modifier to provide features such as scrolling to adjust zoom increment (how deep to zoom at each scroll) in addition to zooming in/out, etc. All other mouse hotkeys remain the same. Please refer to '? > Quick Instructions'.
return

2ButtonReadme:
Gui, 1:-Disabled
Gui, Destroy
Run,"%windir%\system32\notepad.exe" "%A_WorkingDir%\Data\AeroZoom_Readme.txt"
WinWait, AeroZoom_Readme,,3
WinSet, AlwaysOnTop, On, AeroZoom_Readme
return

2ButtonOK:  ; This section is used by the "about box" above.
2GuiClose:   ; On "Close" button press
2GuiEscape:   ; On ESC press
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Destroy  ; Destroy the about box.
return

AdvancedOptions:
; Retrieve settings (once more when starting AeroZoom or Zoom Pad)
RegRead,hideOrMin,HKCU,Software\WanderSick\AeroZoom,HideOrMin
if errorlevel
{
	HideOrMin=1
}
; hide (1) or minimize (2) or do neither (3)

RegRead,keepSnip,HKCU,Software\WanderSick\AeroZoom,keepSnip
if errorlevel
{
	keepSnip=2
}

RegRead,legacyKill,HKCU,Software\WanderSick\AeroZoom,legacyKill
if errorlevel
{
	legacyKill=2
}

RegRead,padTrans,HKCU,Software\WanderSick\AeroZoom,padTrans
if errorlevel
{
	padTrans=35
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
	padH=455
}
RegRead,padW,HKCU,Software\WanderSick\AeroZoom,padW
if errorlevel
{
	padW=455
}
RegRead,padBorder,HKCU,Software\WanderSick\AeroZoom,padBorder
if errorlevel
{
	padBorder=1
}
RegRead,padStayTime,HKCU,Software\WanderSick\AeroZoom,padStayTime
if errorlevel
{
	padStayTime=150
}
RegRead,panelX,HKCU,Software\WanderSick\AeroZoom,panelX
if errorlevel
{
	panelX=15
}
RegRead,panelY,HKCU,Software\WanderSick\AeroZoom,panelY
if errorlevel
{
	panelY=160
}
RegRead,panelTrans,HKCU,Software\WanderSick\AeroZoom,panelTrans
if errorlevel
{
	panelTrans=255
}
RegRead,stillZoomDelay,HKCU,Software\WanderSick\AeroZoom,stillZoomDelay
if errorlevel
{
	stillZoomDelay=650
}

RegRead,delayButton,HKCU,Software\WanderSick\AeroZoom,delayButton
if errorlevel
{
	delayButton=100
}

RegRead,customEdCheckbox,HKCU,Software\WanderSick\AeroZoom,customEdCheckbox
RegRead,customEdPath,HKCU,Software\WanderSick\AeroZoom,customEdPath
RegRead,customCalcCheckbox,HKCU,Software\WanderSick\AeroZoom,customCalcCheckbox
RegRead,customCalcPath,HKCU,Software\WanderSick\AeroZoom,customCalcPath
Gui, 3:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui, +Disabled
Gui, 3:-MinimizeBox -MaximizeBox 
Gui, 3:Add, Edit, x132 y320 w50 h20 +Center +Limit3 -Multi +Number -WantTab -WantReturn vPadTransTemp,
PadTransTemp_TT := "0 min (more transparent), 255 max (less transparent). Default: 35"
Gui, 3:Add, UpDown, x164 y320 w18 h20 vPadTrans Range1-255, %padTrans%
PadTrans_TT := "0 min (more transparent), 255 max (less transparent). Default: 50"

Gui, 3:Add, Edit, x72 y320 w50 h20 +Center +Limit3 -Multi +Number -WantTab -WantReturn vPanelTransTemp, 
PanelTransTemp_TT := "120 min (more transparent), 255 max (less transparent). Default: 255"
Gui, 3:Add, UpDown, x104 y320 w18 h20 vPanelTrans Range120-255, %panelTrans%
PanelTrans_TT := "120 min (more transparent), 255 max (less transparent). Default: 255"

if CheckboxRestoreDefault ; if Restore Default checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}

;Gui, 3:Font, CRed, 
;Gui, 3:Add, CheckBox, %Checked% -Wrap x22 y540 w150 h20 vCheckboxRestoreDefault, &Restore default settings
;Gui, 3:Font, CDefault, 
;CheckboxRestoreDefault_TT := "Restore AeroZoom and magnifier settings to their defaults (Require program restart)"

if CustomEdCheckbox 
{
	Checked=Checked1
	CheckboxDisable=
} else {
	Checked=Checked0
	CheckboxDisable=+Disabled
}
Gui, 3:Add, CheckBox, %Checked% -Wrap x22 y30 w150 h20 gCustomEdCheckbox vCustomEdCheckbox , Define &Type function
CustomEdCheckbox_TT := "Specify a program to override the default text editor (Notepad/Wordpad)"
Gui, 3:Add, Edit, %CheckboxDisable% x22 y50 w110 h20 -Multi -WantTab -WantReturn vCustomEdPath, %customEdPath%
CustomEdPath_TT := "Specify a program to override the default text editor (Notepad/Wordpad)"
Gui, 3:Add, Button, %CheckboxDisable% x132 y49 w50 h22 vCustomEdBrowse g3ButtonBrowse1, &Browse
CustomEdBrowse_TT := "Browse for an executable"

if CustomCalcCheckbox 
{
	Checked=Checked1
	CheckboxDisable=
} else {
	Checked=Checked0
	CheckboxDisable=+Disabled
}
Gui, 3:Add, CheckBox, %Checked% -Wrap x22 y70 w150 h20 gCustomCalcCheckbox vCustomCalcCheckbox , Define &Calc function
CustomCalcCheckbox_TT := "Specify a program to override the default calculator"
Gui, 3:Add, Edit, %CheckboxDisable% x22 y92 w110 h20 -Multi -WantTab -WantReturn vCustomCalcPath, %customCalcPath%
CustomCalcPath_TT := "Specify a program to override the default calculator"
Gui, 3:Add, Button, %CheckboxDisable% x132 y91 w50 h22 vCustomCalcBrowse g3ButtonBrowse2, Brow&se
CustomCalcBrowse_TT := "Browse for an executable"

; Gui, 3:Add, Text, x15 y108 w160 h20 +Left, Manual offset/size adjustment
Gui, 3:Add, Text, x72 y180 w50 h20 +Center, Panel
Gui, 3:Add, Text, x132 y180 w50 h20 +Center, Pad
Gui, 3:Add, Text, x22 y204 w50 h20 , Offset X
Gui, 3:Add, Text, x22 y234 w50 h20 , Offset Y
Gui, 3:Add, Text, x22 y264 w50 h20 , Width
Gui, 3:Add, Text, x22 y294 w50 h20 , Height

Gui, 3:Add, Edit, x72 y200 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPanelXtemp,
PanelXtemp_TT := "AeroZoom Panel: horizontal offset. Default: 15 px"
Gui, 3:Add, UpDown, x104 y200 w18 h20 vPanelX Range0-9999, %panelX%
PanelX_TT := "AeroZoom Panel: horizontal offset. Default: 15 px"

Gui, 3:Add, Edit, x72 y230 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPanelYtemp, 
PanelYtemp_TT := "AeroZoom Panel: vertical offset. Default: 160 px"
Gui, 3:Add, UpDown, x104 y230 w18 h20 vPanelY Range0-9999, %panelY%
PanelY_TT := "AeroZoom Panel: vertical offset. Default: 160 px"

Gui, 3:Add, Edit, x132 y200 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadXtemp, 
PadXtemp_TT := "Misclick-Preventing Pad: horizontal offset. Default: 235 px"
Gui, 3:Add, UpDown, x164 y200 w18 h20 vPadX Range0-9999, %padX%
PadX_TT := "Misclick-Preventing Pad: horizontal offset. Default: 235 px"

Gui, 3:Add, Edit, x132 y230 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadYtemp, 
PadYtemp_TT := "Misclick-Preventing Pad: vertical offset. Default: 240 px"
Gui, 3:Add, UpDown, x164 y230 w18 h20 vPadY Range0-9999, %padY%
PadY_TT := "Misclick-Preventing Pad: vertical offset. Default: 240 px"

Gui, 3:Add, Edit, x132 y260 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadWtemp, 
PadWtemp_TT := "Misclick-Preventing Pad: horizontal width. Default: 455 px"
Gui, 3:Add, UpDown, x164 y260 w18 h20 vPadW Range0-9999, %padW%
PadW_TT := "Misclick-Preventing Pad: horizontal width. Default: 455 px"

Gui, 3:Add, Edit, x132 y290 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadHtemp, 
PadHtemp_TT := "Misclick-Preventing Pad: vertical height. Default: 455 px"
Gui, 3:Add, UpDown, x164 y290 w18 h20 vPadH Range0-9999, %padH%
PadH_TT := "Misclick-Preventing Pad: vertical height. Default: 455 px"

Gui, 3:Add, Button, x12 y570 w60 h30 vOKtemp3, &OK
OKtemp3_TT := "Save changes"
Gui, 3:Add, Button, x72 y570 w60 h30 vResetTemp, &Reset
ResetTemp_TT := "Restore AeroZoom and magnifier settings to their defaults (Require program restart)"
Gui, 3:Add, Button, x132 y570 w60 h30 Default vCancelTemp, &Cancel
CancelTemp_TT := "Cancel changes"


Gui, 3:Add, Text, x22 y322 w50 h20 , Transp.
Gui, 3:Add, Text, x72 y120 w50 h20 +Center, Calc
Gui, 3:Add, Text, x132 y120 w50 h20 +Center, Type
Gui, 3:Add, Text, x22 y122 w50 h20 , Label
Gui, 3:Add, Edit, x72 y120 w50 h20 +Center +Limit8 -Multi -WantTab -WantReturn vCustomCalcMsg, %customCalcMsg%
CustomCalcMsg_TT := "Change text label of Calc here (where the character after & is the Alt keyboard shortcut)"
Gui, 3:Add, Edit, x132 y120 w50 h20 +Center +Limit8 -Multi -WantTab -WantReturn vCustomTypeMsg, %customTypeMsg%
CustomTypeMsg_TT := "Change text label of Type here (where the character after & is the Alt keyboard shortcut)"

Gui, 3:Add, GroupBox, x12 y160 w180 h310 , Fine-tuning
Gui, 3:Add, GroupBox, x12 y10 w180 h140 , Buttons

Gui, 3:Add, Text, x22 y352 w110 h20 , Middle hold time*
Gui, 3:Add, Edit, x132 y350 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vStillZoomDelayTemp, 
StillZoomDelayTemp_TT := "How long holding [Middle] button triggers snip/still-zoom/preview. Default: 650 ms (Require program restart)"
Gui, 3:Add, UpDown, x164 y350 w18 h20 vStillZoomDelay Range0-9999, %stillZoomDelay%

Gui, 3:Add, Text, x22 y382 w110 h20 , Button delay*
Gui, 3:Add, Edit, x132 y380 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vdelayButtonTemp, 
delayButtonTemp_TT := "Delay between each operation. Lower = faster but may cause lag in some PCs. Default: 100 ms (Require program restart)"
Gui, 3:Add, UpDown, x164 y380 w18 h20 vDelayButton Range0-9999, %delayButton%

Gui, 3:Add, Text, x22 y412 w100 h20 , Pad stay time
Gui, 3:Add, Edit, x132 y410 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadStayingTimeTemp, 
PadStayingTimeTemp_TT := "How long the misclick-preventing pad stays. Default: 150 ms (Approximate)"
Gui, 3:Add, UpDown, x164 y410 w18 h20 vPadStayTime Range0-9999, %padStayTime%

Gui, 3:Add, Text, x22 y443 w100 h20 , Pad borders
Gui, 3:Add, DropDownList, x132 y440 w50 h21 R2 +AltSubmit vPadBorder Choose%PadBorder%, Yes|No
PadBorder_TT := "Frame the misclick preventing pad? Default: Yes"

Gui, 3:Add, Text, x22 y483 w100 h20, Keep Snip, Paint*
Gui, 3:Add, DropDownList, x132 y480 w50 h20 R2 +AltSubmit vKeepSnip Choose%KeepSnip%, Yes|No
KeepSnip_TT := "Keep [Snip] and [Kill]/[Paint] buttons when ZoomIt is on. Default: No. (Require program restart)"

Gui, 3:Add, Text, x22 y513 w100 h20 , Use Kill button*
Gui, 3:Add, DropDownList, x132 y510 w50 h20 R2 +AltSubmit vLegacyKill Choose%LegacyKill%, Yes|No
LegacyKill_TT := "Replace [Paint] with [Kill]. Default: No. [Kill] is useful for Docked and Lens views. (Require program restart)"

Gui, 3:Add, Text, x22 y543 w100 h20 , Magnifier*
Gui, 3:Add, DropDownList, x132 y540 w50 h20 R3 +AltSubmit vHideOrMin Choose%hideOrMin%, Hide|Min|Show
HideOrMin_TT := "Hide/Minimize/Show the floating Magnifier window. Default: Hide (Require program restart)"

; Generated using SmartGUI Creator 4.0
Gui, 3:Show, h609 w204, Advanced Options

return

3ButtonReset:
checkboxRestoreDefault=1
Gui, 3:+Disabled
Goto, 3ButtonOK
return

3ButtonCancel:
3GuiClose:   ; On "Close" button press
3GuiEscape:   ; On ESC press
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Destroy
return

3ButtonOK:  ; This section is used by the "about box" above.
if checkboxRestoreDefault {
Msgbox, 262180, AeroZoom Restoration, AeroZoom will restore itself to default settings.`n`nEverything will be lost. Are you sure?
	IfMsgBox Yes
	{
		Gui, Destroy  ; Destroy the about box.
		Gui, 1:Font, CRed, 
		GuiControl,1:Font,Txt,
		GuiControl,1:,Txt,-  Restoring  -
		GuiControl,Disable,Bye
		Gui,+Disabled
		IfExist, %A_Startup%\*AeroZoom*.* ; this is legacy, not used anymore
		{
			FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
			FileDelete, %A_Startup%\*AeroZoom*.*
		}
		RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /deltask,"%A_WorkingDir%\",min ; del task
		RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 0
		RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, MagnificationMode, 0x2
		Process, Close, magnify.exe
		Process, Close, zoomit.exe
	Process, Close, zoomit64.exe
		IfExist, %A_WorkingDir%\Data\ZoomIt.exe
		{
			Msgbox, 262180, AeroZoom Restoration, Also delete ZoomIt and reset its hotkey? ; hotkey will be reset on next use (download) of ZoomIt
			IfMsgBox Yes
			{
				Sleep, 1100
				FileDelete, %A_WorkingDir%\Data\ZoomIt.exe
			FileDelete, %A_WorkingDir%\Data\ZoomIt64.exe
			}
		}
		; Save last AZ window position before exit so that it shows the GUI after restart
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI,
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		reload
		return
	}
	else
	{
		checkboxRestoreDefault=
		Gui, 3:-Disabled
		return
	}
}
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Submit
Gui, Destroy  ; Destroy the about box.
; if padTrans { } used because zoompad doesnt work at 0.
if padTrans {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padTrans, %padTrans%
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padX, %padX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padY, %padY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padH, %padH%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padW, %padW%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padBorder, %padBorder%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, padStayTime, %padStayTime%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, panelX, %panelX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, panelY, %panelY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, panelTrans, %panelTrans%
WinSet, Transparent, %panelTrans%, AeroZoom
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customEdCheckbox, %customEdCheckbox%
if customEdPath 
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customEdPath, %customEdPath%
	Type_TT := ""
} else {
	; if user cleared any custom editor path, even when the checkbox is checked, it gets unchecked
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customEdCheckbox
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customEdPath
}
if customEdCheckbox
{
	; If custom editor is selected, deselect UseNotepad
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Notepad
	Menu, ToolboxMenu, Uncheck, Use &Notepad
	notepad=0
}

RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customCalcCheckbox, %customCalcCheckbox%
if customCalcPath 
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customCalcPath, %customCalcPath%
	Calc_TT := ""
} else {
	; if user cleared any custom editor path, even when the checkbox is checked, it gets unchecked
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customCalcCheckbox
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customCalcPath
}

if (customCalcMsg <> "&Calc")
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customCalcMsg, %customCalcMsg%
	GuiControl,1:,Calc,%customCalcMsg%
}
if (customTypeMsg <> "T&ype")
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customTypeMsg, %customTypeMsg%
	GuiControl,1:,Type,%customTypeMsg%
}
if (hideOrMin<>hideOrMinPrev) { ; note hideOrMinPrev is differernt from hideOrMinLast
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, hideOrMin, %hideOrMin%
	restartRequired=1
}
if (keepSnip<>keepSnipPrev) { 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, keepSnip, %keepSnip%
	restartRequired=1
}
if (legacyKill<>legacyKillPrev) { 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, legacyKill, %legacyKill%
	restartRequired=1
}
if (stillZoomDelay <> stillZoomDelayPrev) { ; if value changed
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, stillZoomDelay, %stillZoomDelay%
	restartRequired=1
}
if (delayButton <> delayButtonPrev) { ; if value changed
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, delayButton, %delayButton%
	restartRequired=1
}

if restartRequired {
	Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
	; Save last AZ window position before exit so that it shows the GUI after restart
	WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI,
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
	Process, Close, magnify.exe
	restartRequired=
	reload
	return
}

return

; ----------------------------------------------------- Radio Button 3 of 3 (Subroutine)
Modifier:

; To submit the selected radio button
GUI, Submit, NoHide

if (chkMod=1) {
	; Modifier is not a Windows Magnifer setting but an AeroZoom setting
	; Write current Modifier setting to registry
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x1
	; Run the user-selected modifier version of AeroZoom
	; chkModRaw<>chkMod to prevent running the same instance
	if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit (restarting AeroZoom is required as changing
		; modifier key means switching executables)
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Ctrl_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Ctrl.exe",,
		ExitApp
	}
} else if (chkMod=2) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x2
	if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Alt_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Alt.exe",,
		ExitApp
	}
} else if (chkMod=3) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x3
	if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Shift_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Shift.exe",,
		ExitApp
	}
} else if (chkMod=4) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x4
	if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Win_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Win.exe",,
		ExitApp
	}
} else if (chkMod=5) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x5
	if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL_x64.exe",,
		Else		
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL.exe",,
		ExitApp
	}
} else if (chkMod=6) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x6
	if (chkModRaw<>chkMod) {
		; Switching to right-handed mode. Hold right+left mouse buttons to bring up panel.
		RegRead,RButton,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,RButton
		if (RButton<>1) {  ; check if message was shown before
		  Msgbox, 262144, This message will not be shown next time, This is for left-handed users to zoom holding the [Right] mouse button.
		  RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, RButton, 1
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseR_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseR.exe",,
		ExitApp
	}
} else if (chkMod=7) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x7
	if (chkModRaw<>chkMod) {
		RegRead,MButton,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,MButton
		if (MButton<>1) {  ; check if message was shown before
		  Msgbox, 262144, This message will not be shown next time, Only one button is required to zoom in this mode.`n`nWhen [Middle] button is pressed and held *hard*, scroll up/down to zoom.`n`nTo reset zoom, while holding [Middle], press [Right].`nTo snip/still-zoom/preview full screen, while holding [Middle], press [Left].`n`nNext time you can read this message at '? > Quick Instructions'
		  RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, MButton, 1
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseM_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseM.exe",,
		ExitApp
	}
} else if (chkMod=8) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x8
	if (chkModRaw<>chkMod) {
		RegRead,X1,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,X1
		if (X1<>1) {  ; check if message was shown before
		  Msgbox, 262144, This message will not be shown next time, This is for mouse with a [Forward] button.`n`nWhen using Back or Forward mouse button as a modifier, AeroZoom also makes use of the extra button to provide more features.`n`nWhat is an extra button? If you use the Forward button (F) as the modifier, then the extra button would be the Back button and vice versa, as in the following example.`n`n1: [Forward+Left click] = (when unzoomed) snip/still-zoom with ZoomIt,`n(zoomed) preview full screen. *no need to hold them as holding a middle button.`n2: [Back+Left click] = color inversion/break timer with ZoomIt.`n3: [Back+Right click] = Show/hide Magnifier.`n4: [Back+Wheel up] = Increase zoom increment by one step.`n5: [Back+Wheel down] = decrease zoom increment by one step.`n6: [Back+Middle button] = reset zoom increment to default level.`n`nBasically, this makes use of the extra button as a modifier to provide features such as scrolling to adjust zoom increment (how deep to zoom at each scroll) in addition to zooming in/out, etc. All other mouse hotkeys remain the same. Please refer to '? > Quick Instructions'.`n`nNext time you can read this message at '? > Quick Instructions > Extras'
		  RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, X1, 1
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX1_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX1.exe",,
		ExitApp
	}
} else if (chkMod=9) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x9
	if (chkModRaw<>chkMod) {
		RegRead,X2,HKEY_CURRENT_USER,Software\WanderSick\AeroZoom,X2
		if (X2<>1) {  ; check if message was shown before
		  Msgbox, 262144, This message will not be shown next time, This is for mouse with a [Back] button.`n`nWhen using Back or Forward mouse button as a modifier, AeroZoom also makes use of the extra button to provide more features.`n`nWhat is an extra button? If you use the Back button (B) as the modifier, then the extra button would be the Forward button and vice versa, as in the following example.`n`n1: [Back+Left click] = (when unzoomed) snip/still-zoom with ZoomIt,`n(zoomed) preview full screen. *no need to hold them as holding a middle button.`n2: [Forward+Left click] = color inversion/break timer with ZoomIt.`n3: [Forward+Right click] = Show/hide Magnifier.`n4: [Forward+Wheel up] = Increase zoom increment by one step.`n5: [Forward+Wheel down] = decrease zoom increment by one step.`n6: [Forward+Middle button] = reset zoom increment to default level.`n`nBasically, this makes use of the extra button as a modifier to provide features such as scrolling to adjust zoom increment (how deep to zoom at each scroll) in addition to zooming in/out, etc. All other mouse hotkeys remain the same. Please refer to '? > Quick Instructions'.`n`nNext time you can read this message at '? > Quick Instructions > Extras'
		  RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, X2, 1
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX2_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX2.exe",,
		ExitApp
	}
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Modifier, 0x4
	if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI, AeroZoom %verAZ% ; v%verAZ%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL.exe",,
		ExitApp
	}
}
return
; ----------------------------------------------------- Radio Button END (return to listen hotkeys)

; Magnification Part 3

SliderMag:
Sleep, 200 ; wait for user to release the slider

MagnificationNew=%Magnification%

; read latest values
Gosub, ReadValueUpdatePanel

if (Magnification=MagnificationNew) ; if old and new values are the same
	return

Process, Exist, magnify.exe ; Check if magnify.exe is running
if not errorlevel {
	Run,"%windir%\system32\magnify.exe",,Min
	;sleep, %delayButton%
	; hide/minimize Windows Magnifier
	WinWait, ahk_class MagUIClass,,4 
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
}

; calculate the number of hotkeys to send in order to zoom to the specified amount
if (Magnification<MagnificationNew) {
	MagLoopCount := MagnificationNew - Magnification
	GuiControl, Disable, Magnification
	if debug1
		msgbox count: %MagLoopCount% new %MagnificationNew% > old %Magnification%
	Loop, %MagLoopCount%
	{
		sendinput #{NumpadAdd}
		Gosub, ReadValueUpdatePanel ; update the slider
		Sleep 150
	}
	GuiControl, Enable, Magnification
	; GuiControl,, Magnification, %Magnification%
}

if (Magnification>MagnificationNew) {
	MagLoopCount := Magnification - MagnificationNew
	GuiControl, Disable, Magnification
	if debug1
		msgbox count: %MagLoopCount% new %MagnificationNew% < old %Magnification%
	Loop, %MagLoopCount%
	{
		sendinput #{NumpadSub}
		Gosub, ReadValueUpdatePanel
		Sleep 150
	}
	GuiControl, Enable, Magnification
	; GuiControl,, Magnification, %Magnification%
}

; Update the panel menu
if (MagnificationRaw=0x64) ; if zoomed out (because Preview Full Screen only works when zoomed in)
	Menu, ViewsMenu, Disable, &Preview Full Screen`tCtrl+Alt+Space
else ; if zoomed in
	Menu, ViewsMenu, Enable, &Preview Full Screen`tCtrl+Alt+Space
Return

; ----------------------------------------------------- Zoom Increment 3 of 3 (Subroutine)
SliderX:
; Gui, Submit, NoHide << not required if a gLabel is used in Slider
if (zoomInc=1) {
	zoomIncRaw=0x19
} else if (zoomInc=2) {
	zoomIncRaw=0x32
} else if (zoomInc=3) {
	zoomIncRaw=0x64
} else if (zoomInc=4) {
	zoomIncRaw=0x96
} else if (zoomInc=5) {
	zoomIncRaw=0xc8
} else if (zoomInc=6) {
	zoomIncRaw=0x190
} else {
	zoomIncRaw=0x64
}

; Write to Registry the user selected Zoom Increment setting
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, %zoomIncRaw%

; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
Process, Exist, magnify.exe
If errorlevel
{
	IfWinExist, ahk_class MagUIClass
	{
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { ; minimized
			hideOrMinLast=2 ; minimized
		} else {
			hideOrMinLast=3 ; normal
		}
	} else {
		hideOrMinLast=1 ; hidden
	}
	Process, Close, magnify.exe ; !!!!!! If magnifier is running, rerun Magnifier to apply the setting
	sleep, %delayButton%
	Run,"%windir%\system32\magnify.exe",,Min
} else {
	hideOrMinLast= ; if not defined, use default settings
}


	WinWait, ahk_class MagUIClass,,3 

; Hide or minimize or normalize magnifier window
If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
	if (hideOrMin=1) {
		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
		WinHide, ahk_class MagUIClass
	} else if (hideOrMin=2) {
		WinMinimize, ahk_class MagUIClass
	}
} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
	WinMinimize, ahk_class MagUIClass
	WinHide, ahk_class MagUIClass
} else if (hideOrMinLast=2) {
	WinMinimize, ahk_class MagUIClass
}


Return
; ----------------------------------------------------- Zoom Increment END (return to listen hotkey)

RunOnStartup:

Gui, 1:Font, CRed,
GuiControl,1:Font,Txt, ; to apply the color change
GuiControl,1:,Txt,- Please Wait -
GuiControl,Disable,Bye
Gui,+Disabled

; Check if AeroZoom task exist

IfExist, %A_Startup%\*AeroZoom*.* ; this is a precaution for legacy reasons
{
	FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
	FileDelete, %A_Startup%\*AeroZoom*.* ; delete all aerozoom shortcuts in startup folder
}
IfExist, %A_StartupCommon%\*AeroZoom*.*
{
	FileSetAttrib, -R, %A_StartupCommon%\*AeroZoom*.*
	FileDelete, %A_StartupCommon%\*AeroZoom*.*
}

RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat","%A_WorkingDir%\",min ; dynamically cre/del task
if (errorlevel=2) { ; if task existed and has just been successfully deleted
	Menu, ToolboxMenu, Uncheck, &Run on Startup
	RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 0
	Msgbox, 262144, AeroZoom, Task successfully removed.
} else if (errorlevel=3) { ; if task did not exist has just been successfully created
	Menu, ToolboxMenu, Check, &Run on Startup
	RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 1
	Msgbox, 262144, AeroZoom, Task successfully created.`n`nAeroZoom will start at boot time with current settings for this user: %A_UserName%`n`nUnder this copy of AeroZoom: %A_WorkingDir%
} else {
	Msgbox, 262192, AeroZoom, Sorry. There was a problem creating or deleting task.
}

Gui, 1:Font, CDefault,
GuiControl,1:Font,Txt,	
GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
Gui,-Disabled
GuiControl,Enable,Bye

return

Install:
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
	ExistAZ=1
; Install / Unisntall
regKey=SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AeroZoom
IfExist, %programfiles% (x86)\WanderSick\AeroZoom\AeroZoom.exe
{
	if ExistAZ
	{
		Menu, ToolboxMenu, Disable, &Install to This Computer
	}
	Msgbox, 262192, AeroZoom, Please uninstall AeroZoom from 'Control Panel\Programs and Features' or use Setup.exe /programfiles.
	ExistAZ=
	return
}
IfExist, %programfiles%\WanderSick\AeroZoom\AeroZoom.exe
{
	if ExistAZ
	{
		Menu, ToolboxMenu, Disable, &Install to This Computer
	}
	Msgbox, 262192, AeroZoom, Please uninstall AeroZoom from 'Control Panel\Programs and Features' or use Setup.exe /programfiles.
	ExistAZ=
	return
}
IfNotExist, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe
{
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Installer , Install AeroZoom for user '%A_UserName%' in the following location?`n`n%localappdata%\WanderSick\AeroZoom
		IfMsgBox No
		{
			ExistAZ=
			return
		}
	}
	Gui, 1:Font, CRed,
	GuiControl,1:Font,Txt, ; to apply the color change
	GuiControl,1:,Txt,- Please Wait -
	GuiControl,Disable,Bye
	Gui,+Disabled
	; Remove existing directory
	FileRemoveDir, %localappdata%\WanderSick\AeroZoom\Data, 1
	FileRemoveDir, %localappdata%\WanderSick\AeroZoom, 1
	; Copy AeroZoom to %localappdata%
	FileCopyDir, %A_WorkingDir%, %localappdata%\WanderSick\AeroZoom, 1
	; Create shortcut to Start Menu (Current User)
	IfExist, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe
	{
		FileCreateShortcut, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe, %A_Programs%\AeroZoom.lnk, %localappdata%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation tool,,
		FileCreateShortcut, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe, %A_Desktop%\AeroZoom.lnk, %localappdata%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation tool,,
	} else {
		FileCreateShortcut, %A_WorkingDir%\AeroZoom.exe, %A_Programs%\AeroZoom.lnk, %A_WorkingDir%,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation tool,,
		FileCreateShortcut, %A_WorkingDir%\AeroZoom.exe, %A_Desktop%\AeroZoom.lnk, %A_WorkingDir%,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation tool,,
	}
	; if a shortcut is in startup, re-create it to ensure its not linked to the portable version's path
	IfExist, %A_Startup%\*AeroZoom*.* ; this is legacy. now task is created instead of shortcut
	{
		FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
		FileDelete, %A_Startup%\*AeroZoom*.* ; ensure no shoutcut is left in startup folder.
	}
		RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min
		if (errorlevel=4) { ; if task exists, recreate it to ensure it links correctly
			RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /cretask /localappdata,"%A_WorkingDir%\",min ; create new one
			if (errorlevel=3) { ; if created successfully
				RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 1
				Menu, ToolboxMenu, Check, &Run on Startup
			}
		} else if (errorlevel=5) {
			RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 0
			Menu, ToolboxMenu, Uncheck, &Run on Startup
		}
		;IfExist, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe
		;{
			; FileCreateShortcut, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe, %A_Startup%\AeroZoom.lnk, %localappdata%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation tool,,
		;}
		;IfExist, %A_Startup%\*AeroZoom*.*
		;{
		;	Menu, ToolboxMenu, Check, &Run on Startup
		;}
	; Write uninstall entry to registry 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayIcon, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe,0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayName, AeroZoom %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallDate, %A_YYYY%%A_MM%%A_DD%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, HelpLink, http://wandersick.blogspot.com
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, URLInfoAbout, http://wandersick.blogspot.com
	
	; ******************************************************************************************
	; ******************************************************************************************
	; ******************************************************************************************
	; ******************************************************************************************
	
	
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %localappdata%\WanderSick\AeroZoom\setup.exe /unattendAZ=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallLocation, %localappdata%\WanderSick\AeroZoom
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayVersion, %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, Publisher, WanderSick
	; Calc folder size
	; SetBatchLines, -1  ; Make the operation run at maximum speed.
	EstimatedSize = 0
	Loop, %localappdata%\WanderSick\AeroZoom\*.*, , 1
	EstimatedSize += %A_LoopFileSize%
	EstimatedSize /= 1024
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, %regKey%, EstimatedSize, %EstimatedSize%
	IfExist, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe
	{
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}	
		if ExistAZ
		{
			Menu, ToolboxMenu, Check, &Install to This Computer
		}
		Msgbox, 262144, AeroZoom, Successfully installed.`n`nAccess the uninstaller in 'Control Panel\Programs and Features'. ; 262144 = Always on top
	} else {
		IfEqual, unattendAZ, 1
		{
			ExitApp, 1
		}
		Msgbox, 262192, AeroZoom, Installation failed.`n`nPlease ensure this folder is unlocked:`n`n%localappdata%\WanderSick\AeroZoom
	}
} else {
	; if unattend switch is on, skip the check since user must be running the uninstaller from control panel
	; not from AeroZoom program
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Uninstaller , Uninstall AeroZoom for the current user from the following location?`n`n%localappdata%\WanderSick\AeroZoom`n`nWarning: Preferences will be lost.
		IfMsgBox No
		{
			ExistAZ=
			return
		}
		Gui, 1:Font, CRed,
		GuiControl,1:Font,Txt, ; to apply the color change
		GuiControl,1:,Txt,- Uninstalling - 
		GuiControl,Disable,Bye
		Gui,+Disabled
		IfExist, %A_WorkingDir%\Data\ZoomIt.exe ; if ZoomIt exists, its setting is kept in order to avoid a bug (need to click 2 times in the menu)
			RegRead,zoomitTemp,HKCU,Software\WanderSick\AeroZoom,zoomit
			
		; (Same reason as above for the next check but to further look into the executables.)
		; AeroZoom has a built-in function to uninstall its copy in %localappdata%. That only works
		; if the AeroZoom running is a portable copy and not the installed one (because the currently
		; running AeroZoom in %localappdata% cannot delete itself)
		
		; ** Update: the following requires AutoHotkey_L. But even with _L, it worked fine on one PC but not another.
		; ** (maybe my codes suck lol) Given _L is 3 times larger than Basic, I will stick to Basic for now.
		
		; foundPos=0
		; for process in ComObjGet("winmgmts:").ExecQuery("Select CommandLine from Win32_Process")
		
			; this checks CommandLine row of Win32_Process to see if any of the currently running executables
			; are from %localappdata%\WanderSick\AeroZoom. (match wandersick\aerozoom\...\zoomit.exe aerozoom.exe, etc.)
			; if the expression returns non-zero (found), then uninstallation must be done via control panel 
			
				 ; FoundPos .= RegExMatch(process.CommandLine[A_Index-1], "i)WanderSick.*AeroZoom.*exe")
				 
				 ; this should output 000000005010000 or anything non-zero if a exe in %localappdata%\WanderSick\AeroZoom
				 ; is found running (then OK to uninstall)
				 ; this should output 000000000000000000 if not found (NOT OK to uninstall)
				 
		; If (FoundPos<>0) {
			; users will be prompted to remove AeroZoom from Control Panel\Programs and Features
			;**  the uninstaller code below is abandoned.
			if ExistAZ
			{
				Menu, ToolboxMenu, Disable, &Install to This Computer
			}
			Msgbox, 262192, AeroZoom, Please uninstall AeroZoom from 'Control Panel\Programs and Features' or use Setup.exe.
			Gui, 1:Font, CDefault,
			GuiControl,1:Font,Txt,	
			GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
			Gui,-Disabled
			GuiControl,Enable,Bye
			ExistAZ=
			return
		; }
	}
	; begin uninstalling
	; remove startup shortcuts
	IfExist, %A_Startup%\*AeroZoom*.*
	{
		FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
		FileDelete, %A_Startup%\*AeroZoom*.*
	}
	RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /deltask,"%A_WorkingDir%\",min
	RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min
	if (errorlevel=5) {
		RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 0
		Menu, ToolboxMenu, Uncheck, &Run on Startup
	}
	; remove reg keys
	RegDelete, HKEY_CURRENT_USER, %regKey%
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom
;	 RButton
;	 MButton
;	 X1
;	 X2
;	 Modifier
;	 Notepad
;	 ZoomPad
;	 ZoomIt
;	 lastPosX
;	 lastPosY and more
	FileSetAttrib, -R, %A_Programs%\AeroZoom.lnk
	FileDelete, %A_Programs%\AeroZoom.lnk
	FileSetAttrib, -R, %localappdata%\WanderSick\AeroZoom\*.*
	FileRemoveDir, %localappdata%\WanderSick\AeroZoom\Data, 1
	FileRemoveDir, %localappdata%\WanderSick\AeroZoom, 1
	IfNotExist, %localappdata%\WanderSick\AeroZoom\AeroZoom.exe
	{
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}
		if ExistAZ
		{
			Menu, ToolboxMenu, Uncheck, &Install to This Computer
		}
		if zoomitTemp
		{
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, ZoomIt, %zoomitTemp%
			zoomitTemp=
		}
		if ExistAZ
		{
			Msgbox, 262208, AeroZoom, Successfully uninstalled.
		} else {
			Msgbox, 262144, AeroZoom, Successfully uninstalled.
		}
	} else {
		IfEqual, unattendAZ, 1
		{
			ExitApp, 1
		}
		Msgbox, 262192, AeroZoom, Uninstallation failed.`n`nPlease ensure this folder is unlocked:`n`n%localappdata%\WanderSick\AeroZoom
	}
}
Gui, 1:Font, CDefault,
GuiControl,1:Font,Txt,	
GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
Gui,-Disabled
GuiControl,Enable,Bye
ExistAZ=
return

Zoomit:
Process, Exist, ZoomIt.exe
if (errorlevel<>0) {
	Process, Close, zoomit.exe
	Process, Close, zoomit64.exe
	Menu, ToolboxMenu, Uncheck, &Sysinternals ZoomIt
	Menu, ToolboxMenu, Disable, &ZoomIt Options
	Menu, ViewsMenu, Disable, ZoomIt - &Still Zoom`tCtrl+1
	Menu, ViewsMenu, Disable, ZoomIt - &Draw`tCtrl+2
	Menu, ViewsMenu, Disable, ZoomIt - &Black Board`tCtrl+2`, K
	Menu, ViewsMenu, Disable, ZoomIt - &White Board`tCtrl+2`, W
	Menu, ViewsMenu, Disable, ZoomIt - Break &Timer`tCtrl+3
	zoomit=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, ZoomIt, 0
	if not (KeepSnip=1) { ; if KeepSnip is not set in the Advanced Options
		if (legacyKill=1) {
			; Change text 'Timer' to 'Kill'
			GuiControl,, Tim&er, Kil&l
			;GuiControl,, Paus&e, Kil&l
		} else {
			GuiControl,, Tim&er, &Paint
			;GuiControl,, Paus&e, &Paint
		}
		GuiControl,, &Draw, &Snip
		if (legacyKill=1) {
			KillMagnifier_TT := "Kill magnifier process"
		} else {
			KillMagnifier_TT := "Create and edit drawings"
		}
		Draw_TT := "Copy a portion of screen for annotation [Win+Alt+S]"
	}
} else {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
	{
		goto, ZoomItDownload
	}
	If not skipEulaChk
	{
		; Check if ZoomIt exists BUT CORRUPTED
		EulaAccepted =
		RegRead,EulaAccepted,HKCU,Software\Sysinternals\ZoomIt,EulaAccepted
		If not EulaAccepted
		{
			Msgbox, 262196, NOTICE, Did you not accept the EULA of Sysinternals ZoomIt?`n`nAeroZoom has detected the step of accepting ZoomIt's End User Licensing Agreement has not been completed. If that is the case, click 'Yes'.`n`nIf you suspect the download failed and ZoomIt.exe is corrupt (sign: strange error prompts), click 'No' so that AeroZoom deletes the file and lets you download again. `n`nAlternatively, you can manually delete or put zoomit.exe into:`n`n%A_WorkingDir%\Data
			IfMsgbox, No
			{
				FileSetAttrib, -R, %A_WorkingDir%\Data\ZoomIt*
				FileDelete, %A_WorkingDir%\Data\ZoomIt.exe
				FileDelete, %A_WorkingDir%\Data\ZoomIt64.exe
				ZoomItFirstRun=
				goto, ZoomIt
			}
			ZoomItFirstRun=1
		}
	}
	skipEulaChk = 
	Run, %A_WorkingDir%\Data\ZoomIt.exe
	if ZoomItFirstRun
	{
		WinWait, ZoomIt License Agreement,,3 ; Prevent AZ panel fro covering EULA
		WinSet, AlwaysOnTop, Off, ahk_class AutoHotkeyGUI,AeroZoom
		WinSet, AlwaysOnTop, On, ZoomIt License Agreement
		WinWaitClose, ZoomIt License Agreement
		If onTopBit
			WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
		Else
			WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
	}
	ZoomItFirstRun=
	RegRead,EulaAccepted,HKCU,Software\Sysinternals\ZoomIt,EulaAccepted
	If not EulaAccepted
		return
	Menu, ToolboxMenu, Check, &Sysinternals ZoomIt
	Menu, ToolboxMenu, Enable, &ZoomIt Options
	Menu, ViewsMenu, Enable, ZoomIt - &Still Zoom`tCtrl+1
	Menu, ViewsMenu, Enable, ZoomIt - &Draw`tCtrl+2
	Menu, ViewsMenu, Enable, ZoomIt - &Black Board`tCtrl+2`, K
	Menu, ViewsMenu, Enable, ZoomIt - &White Board`tCtrl+2`, W
	Menu, ViewsMenu, Enable, ZoomIt - Break &Timer`tCtrl+3
	zoomit=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, ZoomIt, 1
	if not (KeepSnip=1) { ; if KeepSnip is not set in the Advanced Options
		if (legacyKill=1) {
			; Change text 'Kill' to 'Timer'
			GuiControl,, Kil&l, Tim&er
		} else {
			GuiControl,, &Paint, Tim&er
		}
		GuiControl,, &Snip, &Draw
		KillMagnifier_TT := "Break timer of ZoomIt [Ctrl+3]"
		Draw_TT := "Draw, type & still-zoom using ZoomIt [Ctrl+2]"
	}
}
return

UseZoomPad:
if (zoomPad=1) {
	zoomPad=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, ZoomPad, 0
	Menu, ToolboxMenu, Uncheck, &Misclick-Preventing Pad
	;GuiControl,, T&ype, Word
} else {
	zoomPad=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, ZoomPad, 1
	Menu, ToolboxMenu, Check, &Misclick-Preventing Pad
	;GuiControl,, T&ype, Note
}
return

HoldMiddle:
if (holdMiddle=1) {
	holdMiddle=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, holdMiddle, 0
	Menu, ToolboxMenu, Uncheck, &Hold Middle as Trigger
} else {
	holdMiddle=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, holdMiddle, 1
	Menu, ToolboxMenu, Check, &Hold Middle as Trigger
}
return

UseNotepad:
if (notepad=1) {
	notepad=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Notepad, 0
	Menu, ToolboxMenu, Uncheck, Use &Notepad
	;GuiControl,, &Note, Word
} else {
	notepad=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, Notepad, 1
	Menu, ToolboxMenu, Check, Use &Notepad
	; When useNotepad is selected, customEd is deselected
	RegDelete, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, customEdCheckbox
	customEdCheckbox=
	;GuiControl,, &Note, Note
}
return

ClicknGo:
; Toggle Click 'n Go
RegRead,clickGoBit,HKCU,Software\WanderSick\AeroZoom,clickGoBit
if clickGoBit
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, clickGoBit, 0
	Menu, ToolboxMenu, Uncheck, &Click-n-Go
	guiDestroy=
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, clickGoBit, 1
	Menu, ToolboxMenu, Check, &Click-n-Go
	guiDestroy=Destroy
}
return

OnTop:
; Toggle Always on Top
RegRead,onTopBit,HKCU,Software\WanderSick\AeroZoom,onTopBit
if onTopBit
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, onTopBit, 0
	Menu, ToolboxMenu, Uncheck, Always on &Top
	onTop=-AlwaysOnTop
	onTopBit=0
	WinSet, AlwaysOnTop, off, ahk_class CalcFrame
	WinSet, AlwaysOnTop, off, ahk_class MSPaintApp
	WinSet, AlwaysOnTop, off, ahk_class WordPadClass
	WinSet, AlwaysOnTop, off, ahk_class Notepad
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, onTopBit, 1
	Menu, ToolboxMenu, Check, Always on &Top
	onTop=+AlwaysOnTop
	onTopBit=1
}
Gui, %onTop%
return

customEdCheckbox:
GuiControl,3:Enable, customEdBrowse ;
GuiControl,3:Enable, customEdPath ;a variable is set, so text label is not used; if a variable is unset, then the text label is used (e.g. &Browse)
return

customCalcCheckbox:
GuiControl,3:Enable, customCalcBrowse ;
GuiControl,3:Enable, customCalcPath ;a variable is set, so text label is not used; if a variable is unset, then the text label is used (e.g. &Browse)
return

3ButtonBrowse1:
Gui, -AlwaysOnTop
FileSelectFile, customEdPath, 3, , Select a program to launch by this button, Executables (*.exe)
Gui, +AlwaysOnTop
if customEdPath
{
	GuiControl,3:,customEdPath,%customEdPath%
}
return

3ButtonBrowse2:
Gui, -AlwaysOnTop ; to prevent the Browse dialog from being covered by the Advanced Options dialog
FileSelectFile, customCalcPath, 3, , Select a program to launch by this button, Executables (*.exe)
Gui, +AlwaysOnTop
if customCalcPath
{
	GuiControl,3:,customCalcPath,%customCalcPath%
}
return

ctTune:
Run, %windir%\system32\cttune.exe
return

easeOfAccess:
Run, %windir%\explorer.exe shell:::{D555645E-D4F8-4c29-A827-D93C859C4F2A}
return

zoomitOptions:
RegRead,zoomItOptions,HKCU,Software\WanderSick\AeroZoom,zoomItOptions
if not zoomItOptions
{
	Msgbox, 262144, This message will only be shown once, Please do not modify the keyboard shortcuts in ZoomIt Options as AeroZoom depends on the default hotkeys to work.`n`nIn case they are modified, it can be reverted by checking 'Restore default settings' in Tool > Advanced Options, or by pressing Win+Shift+Alt+R.
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, zoomItOptions, 1
}
Run, %A_WorkingDir%\Data\ZoomIt.exe ; running an already running ZoomIt brings up the options menu.
WinWait, ZoomIt - Sysinternals: www.sysinternals.com,,3 ; Prevent AZ panel fro covering ZoomIt Options
WinSet, AlwaysOnTop, Off, ahk_class AutoHotkeyGUI,AeroZoom
WinSet, AlwaysOnTop, On, ZoomIt - Sysinternals: www.sysinternals.com
WinWaitClose, ZoomIt - Sysinternals: www.sysinternals.com
If onTopBit
	WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
Else
	WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
return

ViewFullScreen:
Process, Exist, magnify.exe
if not errorlevel ; if not running
	Run,"%windir%\system32\magnify.exe",,
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Menu, ViewsMenu, Check, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
}
sendinput ^!f
return

ViewLens:
Process, Exist, magnify.exe
if not errorlevel ; if not running
{
	Run,"%windir%\system32\magnify.exe",,
	WinWait, ahk_class MagUIClass,,3
}
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Check, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
}
sendinput ^!l
return

ViewDocked:
Process, Exist, magnify.exe
if not errorlevel ; if not running
{
	Run,"%windir%\system32\magnify.exe",,
	WinWait, ahk_class MagUIClass,,3
}
IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
{
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Check, &Docked`tCtrl+Alt+D
}
sendinput ^!d
return

ViewPreview:
Process, Exist, magnify.exe
if not errorlevel ; if not running
{
	Run,"%windir%\system32\magnify.exe",,
	WinWait, ahk_class MagUIClass,,3
}
sendinput ^!{Space}
return

ViewStillZoom:
WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
sendinput ^1
WinWait, ahk_class ZoomitClass,,5
WinWaitClose, ahk_class ZoomitClass
If onTopBit
	WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
Else
	WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
return

ViewBlackBoard:
WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
sendinput kt
WinWaitClose, ahk_class ZoomitClass
If onTopBit
	WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
Else
	WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
return

ViewWhiteBoard:
WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
sendinput wt
WinWaitClose, ahk_class ZoomitClass
If onTopBit
	WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
Else
	WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
return

ViewDraw:
WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
WinWaitClose, ahk_class ZoomitClass
If onTopBit
	WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
Else
	WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
return

ViewBreakTimer:
WinSet, Bottom,,ahk_class AutoHotkeyGUI,AeroZoom
sendinput ^3
WinWait, ahk_class ZoomitClass,,5
WinWaitClose, ahk_class ZoomitClass
If onTopBit
	WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI,AeroZoom
Else
	WinActivate, ahk_class AutoHotkeyGUI,AeroZoom
return

; 1-61
MagReadValues1:
	
RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0x7D) { ; 125
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x96) { ; 150
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0xAF) { ; 175
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4	
} else if (MagnificationRaw=0xC8) { ; 200
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0xE1) { ; 225
	if ExistAZ
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0xFA) { ; 250
	if ExistAZ
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x113) { ; 275
	if ExistAZ
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x12C) { ; 300
	if ExistAZ
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x145) { ; 325
	if ExistAZ
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x15E) { ; 350
	if ExistAZ
		GuiControl,, Magnification, 11
	Magnification=11
} else if (MagnificationRaw=0x177) { ; 375
	if ExistAZ
		GuiControl,, Magnification, 12
	Magnification=12
} else if (MagnificationRaw=0x190) { ; 400
	if ExistAZ
		GuiControl,, Magnification, 13
	Magnification=13
} else if (MagnificationRaw=0x1A9) { ; 425
	if ExistAZ
		GuiControl,, Magnification, 14
	Magnification=14
} else if (MagnificationRaw=0x1C2) { ; 450
	if ExistAZ
		GuiControl,, Magnification, 15
	Magnification=15
} else if (MagnificationRaw=0x1DB) { ; 475
	if ExistAZ
		GuiControl,, Magnification, 16
	Magnification=16
} else if (MagnificationRaw=0x1F4) { ; 500
	if ExistAZ
		GuiControl,, Magnification, 17
	Magnification=17
} else if (MagnificationRaw=0x20D) { ; 525
	if ExistAZ
		GuiControl,, Magnification, 18
	Magnification=18
} else if (MagnificationRaw=0x226) { ; 550
	if ExistAZ
		GuiControl,, Magnification, 19
	Magnification=19
} else if (MagnificationRaw=0x23F) { ; 575
	if ExistAZ
		GuiControl,, Magnification, 20
	Magnification=20
} else if (MagnificationRaw=0x258) { ; 600
	if ExistAZ
		GuiControl,, Magnification, 21
	Magnification=21
} else if (MagnificationRaw=0x271) { ; 625
	if ExistAZ
		GuiControl,, Magnification, 22
	Magnification=22
} else if (MagnificationRaw=0x28A) { ; 650
	if ExistAZ
		GuiControl,, Magnification, 23
	Magnification=23
} else if (MagnificationRaw=0x2A3) { ; 675
	if ExistAZ
		GuiControl,, Magnification, 24
	Magnification=24
} else if (MagnificationRaw=0x2BC) { ; 700
	if ExistAZ
		GuiControl,, Magnification, 25
	Magnification=25
} else if (MagnificationRaw=0x2D5) { ; 725
	if ExistAZ
		GuiControl,, Magnification, 26
	Magnification=26
} else if (MagnificationRaw=0x2EE) { ; 750
	if ExistAZ
		GuiControl,, Magnification, 27
	Magnification=27
} else if (MagnificationRaw=0x307) { ; 775
	if ExistAZ
		GuiControl,, Magnification, 28
	Magnification=28
} else if (MagnificationRaw=0x320) { ; 800
	if ExistAZ
		GuiControl,, Magnification, 29
	Magnification=29
} else if (MagnificationRaw=0x339) { ; 825
	if ExistAZ
		GuiControl,, Magnification, 30
	Magnification=30
} else if (MagnificationRaw=0x352) { ; 850
	if ExistAZ
		GuiControl,, Magnification, 31
	Magnification=31
} else if (MagnificationRaw=0x36B) { ; 875
	if ExistAZ
		GuiControl,, Magnification, 32
	Magnification=32
} else if (MagnificationRaw=0x384) { ; 900
	if ExistAZ
		GuiControl,, Magnification, 33
	Magnification=33
} else if (MagnificationRaw=0x39D) { ; 925
	if ExistAZ
		GuiControl,, Magnification, 34
	Magnification=34
} else if (MagnificationRaw=0x3B6) { ; 950
	if ExistAZ
		GuiControl,, Magnification, 35
	Magnification=35
} else if (MagnificationRaw=0x3CF) { ; 975
	if ExistAZ
		GuiControl,, Magnification, 36
	Magnification=36
} else if (MagnificationRaw=0x3E8) { ; 1000
	if ExistAZ
		GuiControl,, Magnification, 37
	Magnification=37
} else if (MagnificationRaw=0x401) { ; 1025
	if ExistAZ
		GuiControl,, Magnification, 38
	Magnification=38
} else if (MagnificationRaw=0x41A) { ; 1050
	if ExistAZ
		GuiControl,, Magnification, 39
	Magnification=39
} else if (MagnificationRaw=0x433) { ; 1075
	if ExistAZ
		GuiControl,, Magnification, 40
	Magnification=40
} else if (MagnificationRaw=0x44C) { ; 1100
	if ExistAZ
		GuiControl,, Magnification, 41
	Magnification=41
} else if (MagnificationRaw=0x465) { ; 1125
	if ExistAZ
		GuiControl,, Magnification, 42
	Magnification=42
} else if (MagnificationRaw=0x47E) { ; 1150
	if ExistAZ
		GuiControl,, Magnification, 43
	Magnification=43
} else if (MagnificationRaw=0x497) { ; 1175
	if ExistAZ
		GuiControl,, Magnification, 44
	Magnification=44
} else if (MagnificationRaw=0x4B0) { ; 1200
	if ExistAZ
		GuiControl,, Magnification, 45
	Magnification=45
} else if (MagnificationRaw=0x4C9) { ; 1225
	if ExistAZ
		GuiControl,, Magnification, 46
	Magnification=46
} else if (MagnificationRaw=0x4E2) { ; 1250
	if ExistAZ
		GuiControl,, Magnification, 47
	Magnification=47
} else if (MagnificationRaw=0x4FB) { ; 1275
	if ExistAZ
		GuiControl,, Magnification, 48
	Magnification=48
} else if (MagnificationRaw=0x514) { ; 1300
	if ExistAZ
		GuiControl,, Magnification, 49
	Magnification=49
} else if (MagnificationRaw=0x52D) { ; 1325
	if ExistAZ
		GuiControl,, Magnification, 50
	Magnification=50
} else if (MagnificationRaw=0x546) { ; 1350
	if ExistAZ
		GuiControl,, Magnification, 51
	Magnification=51
} else if (MagnificationRaw=0x55F) { ; 1375
	if ExistAZ
		GuiControl,, Magnification, 52
	Magnification=52
} else if (MagnificationRaw=0x578) { ; 1400
	if ExistAZ
		GuiControl,, Magnification, 53
	Magnification=53
} else if (MagnificationRaw=0x591) { ; 1425
	if ExistAZ
		GuiControl,, Magnification, 54
	Magnification=54
} else if (MagnificationRaw=0x5AA) { ; 1450
	if ExistAZ
		GuiControl,, Magnification, 55
	Magnification=55
} else if (MagnificationRaw=0x5C3) { ; 1475
	if ExistAZ
		GuiControl,, Magnification, 56
	Magnification=56
} else if (MagnificationRaw=0x5DC) { ; 1500
	if ExistAZ
		GuiControl,, Magnification, 57
	Magnification=57
} else if (MagnificationRaw=0x5F5) { ; 1525
	if ExistAZ
		GuiControl,, Magnification, 58
	Magnification=58
} else if (MagnificationRaw=0x60E) { ; 1550
	if ExistAZ
		GuiControl,, Magnification, 59
	Magnification=59
} else if (MagnificationRaw=0x627) { ; 1575
	if ExistAZ
		GuiControl,, Magnification, 60
	Magnification=60
} else if (MagnificationRaw=0x640) { ; 1600
	if ExistAZ
		GuiControl,, Magnification, 61
	Magnification=61
} else {
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
}

return

; 1-31
MagReadValues2:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0x96) { ; 150
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0xC8) { ; 200
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0xFA) { ; 250
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x12C) { ; 300
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x15E) { ; 350
	if ExistAZ
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x190) { ; 400
	if ExistAZ
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x1C2) { ; 450
	if ExistAZ
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x1F4) { ; 500
	if ExistAZ
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x226) { ; 550
	if ExistAZ
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x258) { ; 600
	if ExistAZ
		GuiControl,, Magnification, 11
	Magnification=11
} else if (MagnificationRaw=0x28A) { ; 650
	if ExistAZ
		GuiControl,, Magnification, 12
	Magnification=12
} else if (MagnificationRaw=0x2BC) { ; 700
	if ExistAZ
		GuiControl,, Magnification, 13
	Magnification=13
} else if (MagnificationRaw=0x2EE) { ; 750
	if ExistAZ
		GuiControl,, Magnification, 14
	Magnification=14
} else if (MagnificationRaw=0x320) { ; 800
	if ExistAZ
		GuiControl,, Magnification, 15
	Magnification=15
} else if (MagnificationRaw=0x352) { ; 850
	if ExistAZ
		GuiControl,, Magnification, 16
	Magnification=16
} else if (MagnificationRaw=0x384) { ; 900
	if ExistAZ
		GuiControl,, Magnification, 17
	Magnification=17
} else if (MagnificationRaw=0x3B6) { ; 950
	if ExistAZ
		GuiControl,, Magnification, 18
	Magnification=18
} else if (MagnificationRaw=0x3E8) { ; 1000
	if ExistAZ
		GuiControl,, Magnification, 19
	Magnification=19
} else if (MagnificationRaw=0x41A) { ; 1050
	if ExistAZ
		GuiControl,, Magnification, 20
	Magnification=20
} else if (MagnificationRaw=0x44C) { ; 1100
	if ExistAZ
		GuiControl,, Magnification, 21
	Magnification=21
} else if (MagnificationRaw=0x47E) { ; 1150
	if ExistAZ
		GuiControl,, Magnification, 22
	Magnification=22
} else if (MagnificationRaw=0x4B0) { ; 1200
	if ExistAZ
		GuiControl,, Magnification, 23
	Magnification=23
} else if (MagnificationRaw=0x4E2) { ; 1250
	if ExistAZ
		GuiControl,, Magnification, 24
	Magnification=24
} else if (MagnificationRaw=0x514) { ; 1300
	if ExistAZ
		GuiControl,, Magnification, 25
	Magnification=25
} else if (MagnificationRaw=0x546) { ; 1350
	if ExistAZ
		GuiControl,, Magnification, 26
	Magnification=26
} else if (MagnificationRaw=0x578) { ; 1400
	if ExistAZ
		GuiControl,, Magnification, 27
	Magnification=27
} else if (MagnificationRaw=0x5AA) { ; 1450
	if ExistAZ
		GuiControl,, Magnification, 28
	Magnification=28
} else if (MagnificationRaw=0x5DC) { ; 1500
	if ExistAZ
		GuiControl,, Magnification, 29
	Magnification=29
} else if (MagnificationRaw=0x60E) { ; 1550
	if ExistAZ
		GuiControl,, Magnification, 30
	Magnification=30
} else if (MagnificationRaw=0x640) { ; 1600
	if ExistAZ
		GuiControl,, Magnification, 31
	Magnification=31
} else {
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
}
return

; 1-16
MagReadValues3:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0xC8) { ; 200
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x12C) { ; 300
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x190) { ; 400
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x1F4) { ; 500
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x258) { ; 600
	if ExistAZ
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x2BC) { ; 700
	if ExistAZ
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x320) { ; 800
	if ExistAZ
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x384) { ; 900
	if ExistAZ
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x3E8) { ; 1000
	if ExistAZ
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x44C) { ; 1100
	if ExistAZ
		GuiControl,, Magnification, 11
	Magnification=11
} else if (MagnificationRaw=0x4B0) { ; 1200
	if ExistAZ
		GuiControl,, Magnification, 12
	Magnification=12
} else if (MagnificationRaw=0x514) { ; 1300
	if ExistAZ
		GuiControl,, Magnification, 13
	Magnification=13
} else if (MagnificationRaw=0x578) { ; 1400
	if ExistAZ
		GuiControl,, Magnification, 14
	Magnification=14
} else if (MagnificationRaw=0x5DC) { ; 1500
	if ExistAZ
		GuiControl,, Magnification, 15
	Magnification=15
} else if (MagnificationRaw=0x640) { ; 1600
	if ExistAZ
		GuiControl,, Magnification, 16
	Magnification=16
} else {
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
}

return

; 1-11
MagReadValues4:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0xFA) { ; 250
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x190) { ; 400
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x226) { ; 550
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x2BC) { ; 700
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x352) { ; 850
	if ExistAZ
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x3E8) { ; 1000
	if ExistAZ
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x47E) { ; 1150
	if ExistAZ
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x514) { ; 1300
	if ExistAZ
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x5AA) { ; 1450
	if ExistAZ
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x640) { ; 1600
	if ExistAZ
		GuiControl,, Magnification, 11
	Magnification=11
} else {
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
}
	
return

;1-9
MagReadValues5:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0xC8) { ; 200 
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x12C) { ; 300
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x190) { ; 400
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x1F4) { ; 500
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x258) { ; 600
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x2BC) { ; 700
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x320) { ; 800
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x384) { ; 900
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x3E8) { ; 1000
	if ExistAZ
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x44C) { ; 1100
	if ExistAZ
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x4B0) { ; 1200
	if ExistAZ
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x514) { ; 1300
	if ExistAZ
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x578) { ; 1400
	if ExistAZ
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x5DC) { ; 1500 ; when zooming out after zooming in to the max (1600), it reduces to 1400 instead of 1300, so both 1300 and 1400 share the same value, and vice versa
	if ExistAZ
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x640) { ; 1600
	if ExistAZ
		GuiControl,, Magnification, 9
	Magnification=9
} else {
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
}

return

; 1-5
MagReadValues6:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0x190) { ; 400
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x1F4) { ; 500
	if ExistAZ
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x320) { ; 800
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x384) { ; 900
	if ExistAZ
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x4B0) { ; 1200
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x514) { ; 1300
	if ExistAZ
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x640) { ; 1600
	if ExistAZ
		GuiControl,, Magnification, 5
	Magnification=5
} else {
	if ExistAZ
		GuiControl,, Magnification, 1
	Magnification=1
}

return

ReadValueUpdatePanel:

;if not quickZoomIncChk
;{
	IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
		ExistAZ=1
;}

; Refresh ZoomIncrement and Magnification ; note this may not be the best way of doing it
RegRead,zoomIncRaw,HKCU,Software\Microsoft\ScreenMagnifier,ZoomIncrement
if (zoomIncRaw=0x19) { ; Get values from registry, Hex to Dec
	if ExistAZ
		GuiControl,, ZoomInc, 1
	zoomInc=1
} else if (zoomIncRaw=0x32) {
	if ExistAZ
		GuiControl,, ZoomInc, 2
	zoomInc=2
} else if (zoomIncRaw=0x64) {
	if ExistAZ
		GuiControl,, ZoomInc, 3
	zoomInc=3
} else if (zoomIncRaw=0x96) {
	if ExistAZ
		GuiControl,, ZoomInc, 4
	zoomInc=4
} else if (zoomIncRaw=0xc8) {
	if ExistAZ
		GuiControl,, ZoomInc, 5
	zoomInc=5
} else if (zoomIncRaw=0x190) {
	if ExistAZ
		GuiControl,, ZoomInc, 6
	zoomInc=6
} else {
	if ExistAZ
		GuiControl,, ZoomInc, 3
	zoomInc=3
}

;if quickZoomIncChk ; reduce the burden for SetTimer to return more quickly
;	return	

; Check which zoom increment to use, then update the corresponding magnification
if (ZoomInc=1) {
	Gosub, MagReadValues1 ; Get values from registry, Hex to Dec
} else if (ZoomInc=2) {
	Gosub, MagReadValues2
} else if (ZoomInc=3) {
	Gosub, MagReadValues3
} else if (ZoomInc=4) {
	Gosub, MagReadValues4
} else if (ZoomInc=5) {
	Gosub, MagReadValues5
} else if (ZoomInc=6) {
	Gosub, MagReadValues6
}

if ExistAZ
{
	if (MagnificationMode=0x2) {
		if (MagnificationRaw=0x64) ; if zoomed out (because Preview Full Screen only works when zoomed in)
			Menu, ViewsMenu, Disable, &Preview Full Screen`tCtrl+Alt+Space
		else ; if zoomed in
			Menu, ViewsMenu, Enable, &Preview Full Screen`tCtrl+Alt+Space
	}
}
ExistAZ=
return

ReadValueUpdateMenu:

RegRead,MagnificationMode,HKCU,Software\Microsoft\ScreenMagnifier,MagnificationMode
If not StartupMagMode
{
	If (MagnificationMode=MagnificationModeOld) ; if no change, no need to refresh (used by settimer)
		return
}
StartupMagMode=

if (MagnificationMode=0x2) { ; full screen
	Menu, ViewsMenu, Enable, &Preview Full Screen`tCtrl+Alt+Space
	Menu, ViewsMenu, Check, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
} else if (MagnificationMode=0x3) { ; lens
	Menu, ViewsMenu, Disable, &Preview Full Screen`tCtrl+Alt+Space
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Check, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
} else if (MagnificationMode=0x1) { ; docked
	Menu, ViewsMenu, Disable, &Preview Full Screen`tCtrl+Alt+Space
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Check, &Docked`tCtrl+Alt+D
}

return

SwitchZoomInc:
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
If SwitchZoomInc
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, SwitchZoomInc, 0
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, SwitchZoomInc, 1
}
reload
return

SwitchMiniMode:
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
If SwitchMiniMode
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, SwitchMiniMode, 0
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, SwitchMiniMode, 1
}
reload
return

updateMouseTextKB:
; this part is better rewritten with RegNotifyChangeKeyValue (Need help on that!)
; http://www.autohotkey.com/forum/topic34226.html

; purpose: update the text of mouse/text/keyboard buttons of panel. runs at call of panel and settimer
; the values can be wrong if user modify Magnifier Options outside in the original magnigier instead of AZ panel.

if startUpChk
	goto startUpChkSkip ; Skip in case AZ Panel is called (at start) instead of being monitored using settimer

; To reduce registry polling by SetTimer, the following conditions must be met

; confirm AZ Panel is not hidden (if hidden, there is no need to update now, because when AZ panel is called, it is updated.)
IfWinNotExist, ahk_class AutoHotkeyGUI, AeroZoom 
	return
	
; confirm Magnifier is shown (if magnifier is hidden, user would have no way to change its settings there anyway, so no need to use DetectHiddenWindows)
IfWinNotExist, ahk_class MagUIClass,
	return

; Check the slider for update

ZoomIncOld=%ZoomInc%
; quickZoomIncChk=1 ; reduce the burden for SetTimer to return more quickly
Gosub, ReadValueUpdatePanel
; quickZoomIncChk=
If not SwitchZoomInc { ; no need to restart if AZ panel is not in 'magnification slider' mode
	If (ZoomIncOld<>ZoomInc)
	{
		; reload AZ script to update
		; Save last AZ window position before exit so that it shows the GUI after restart
		WinGetPos, lastPosX, lastPosY, , , ahk_class AutoHotkeyGUI,
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, reload, 1
		reload
	}
}

MagnificationModeOld=%MagnificationMode%
Gosub, ReadValueUpdateMenu
MagnificationModeOld=

startUpChkSkip:
startUpChk=

; Check the 3 big buttons for update
; there is no need to display on panel whether color is inverted as it can be seen but the following can not.

MouseLast=%MouseCurrent%
KeyboardLast=%KeyboardCurrent%
TextLast=%TextCurrent%

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

; if panel GUI is already created, update using GuiControl

If (MouseLast<>MouseCurrent)
	GuiControl,,Mouse,&Mouse %MouseCurrent% => %MouseNext%
If (KeyboardLast<>KeyboardCurrent)
	GuiControl,,Keyboard,&Keyboard %KeyboardCurrent% => %KeyboardNext%
If (TextLast<>TextCurrent)
	GuiControl,,Text,Te&xt %TextCurrent% => %TextNext%

return

startupTips:
if (TipDisabled=1) {
	TipDisabled=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, TipDisabled, 0
	Menu, AboutMenu, Uncheck, &Disable Startup Tips
} else {
	TipDisabled=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, TipDisabled, 1
	Menu, AboutMenu, Check, &Disable Startup Tips
}
return

WinCalc:
Run, %windir%\System32\calc.exe
return

WinCMD:
Run, %windir%\System32\cmd.exe
return

WinControl:
Run, %windir%\System32\control.exe
return

WinMath:
Run, %CommonProgramFiles%\Microsoft Shared\Ink\mip.exe
return

WinNote:
Run, C:\Windows\System32\notepad.exe
return

WinKB:
Run, %windir%\System32\osk.exe
return

WinNarrator:
Run, %windir%\system32\narrator.exe
return

WinPaint:
Run, %windir%\System32\mspaint.exe
return

WinPSR:
Run, %windir%\System32\psr.exe
return

WinRun:
Run, %windir%\System32\rundll32.exe shell32.dll`,#61
return

WinSound:
Run, %SystemRoot%\system32\SoundRecorder.exe
return

WinSticky:
Run, %windir%\system32\StikyNot.exe
return

WinJournel:
Run, %ProgramFiles%\Windows Journal\Journal.exe
return

WinWord:
Run, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
return

WinTask:
Run, %windir%\System32\taskmgr.exe
return

WinSpeech:
Run, %windir%\Speech\Common\sapisvr.exe -SpeechUX
return

ZoomPad:
; only enable zoompad if when modifier is a mouse button
if (chkMod>4)
{
	if zoomPad ; if zoompad is NOT disabled
	{
		IfWinNotActive, ahk_class AutoHotkeyGUI, AeroZoom ;if current win is not the panel (zooming over the panel does not require zoompad)
		{
			; ZoomPad to prevent accidental clicks
			IfWinExist, AeroZoom Pad
			{
				WinActivate
			} else {
				Run, "%A_WorkingDir%\Data\ZoomPad.exe"
			}
		}
	}
}
return

SnippingTool:
IfWinExist, ahk_class Microsoft-Windows-Tablet-SnipperToolbar
{
	WinHide, ahk_class AutoHotkeyGUI,AeroZoom
	WinRestore, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperToolbar
	Sleep, 50
	sendinput ^n
	WinWait, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,4
	If Errorlevel
		Gosub, SnippingToolRestart
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
	Sleep, 900
	WinWaitClose, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,8
	WinShow, ahk_class AutoHotkeyGUI,AeroZoom
	return
}
IfWinExist, ahk_class Microsoft-Windows-Tablet-SnipperEditor
{
	WinHide, ahk_class AutoHotkeyGUI,AeroZoom
	WinRestore, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	Sleep, 50
	sendinput ^n
	WinWait, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,4
	If Errorlevel
		Gosub, SnippingToolRestart
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
	Sleep, 900
	WinWaitClose, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,8
	WinShow, ahk_class AutoHotkeyGUI,AeroZoom
	return
}
WinHide, ahk_class AutoHotkeyGUI,AeroZoom
Run,"%windir%\system32\SnippingTool.exe",,
WinWait, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,6
If Errorlevel
	Gosub, SnippingToolRestart
WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
Sleep, 900
WinWaitClose, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,8
WinShow, ahk_class AutoHotkeyGUI,AeroZoom
return

SnippingToolRestart:
Process, Close, SnippingTool.exe
sleep, %delayButton%
Run,"%windir%\system32\SnippingTool.exe",,
return

ZoomItDownload:
Gui, 4:+owner1 
Gui, +Disabled
Gui, 4:-MinimizeBox -MaximizeBox 
userZoomItPath = http://live.sysinternals.com/ZoomIt.exe
Gui, 4:Add, Edit, x12 y140 w210 h20 -Multi -WantTab -WantReturn vUserZoomItPath, %UserZoomItPath%
userZoomItPath_TT := "Input the path to ZoomIt.exe"
Gui, 4:Add, Text, x12 y170 w270 h30 , Note: If it begins with 'http://'`, it will be downloaded.`n         (AeroZoom must not be used during download.)
Gui, 4:Add, Button, x222 y139 w60 h22 v4ButtonBrowse g4ButtonBrowse, &Browse
4ButtonBrowse_TT := "Browse for ZoomIt.exe"
Gui, 4:Add, Button, x142 y210 w70 h30 Default g4ButtonOK v4ButtonOKTemp, &OK
4ButtonOKTemp_TT := "Click to continue"
Gui, 4:Add, Button, x212 y210 w70 h30 g4ButtonCancel v4ButtonCancelTemp, &Cancel
4ButtonCancelTemp_TT := "Click to withdraw"
Gui, 4:Add, Text, x12 y10 w270 h120 , AeroZoom enhances mouse operations of Sysinternals ZoomIt`, a Microsoft freeware screen magnifier`, through providing access to its non-live zoom (still zoom) function by holding the [Middle] mouse button`; Draw`, Timer and more functions via buttons/menus on the panel.`n`nZoomIt's hotkeys will be set to defaults for that to work.`n`nTo continue`, please specify the path to ZoomIt.exe:
Gui, 4:Show, h252 w298, ZoomIt Enhancements Setup
return

4ButtonCancel:
4GuiClose:   ; On "Close" button press
4GuiEscape:   ; On ESC press
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Destroy
return

4ButtonBrowse:
Gui, -AlwaysOnTop
FileSelectFile, userZoomItPath, 3, , Select ZoomIt.exe, ZoomIt v4.0+ (ZoomIt.exe)
Gui, +AlwaysOnTop
if userZoomItPath
{
	GuiControl,4:,userZoomItPath,%userZoomItPath%
}
return

4ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
Menu, ToolboxMenu, Disable, &Sysinternals ZoomIt
Gui, 1:Font, CRed,
GuiControl,1:Font,Txt, ; to apply the color change 
GuiControl,1:,Txt,- Please Wait -
Haystack = %userZoomItPath%
Needle = http://
IfNotInString, Haystack, %Needle%
{
	IfNotExist, %userZoomItPath%
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%userZoomItPath%
		Gui, 1:Font, CDefault,
		GuiControl,1:Font,Txt,	
		GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
		;Gui,-Disabled
		Menu, ToolboxMenu, Enable, &Sysinternals ZoomIt
		return
	}
	FileCopy, %userZoomItPath%, %A_WorkingDir%\Data\ZoomIt.exe
	IfNotExist, %userZoomItPath%
	{
		Msgbox, 262192, ERROR, File copy failed:`n`n%userZoomItPath%`n`nEnsure destination is not locked.
		Gui, 1:Font, CDefault,
		GuiControl,1:Font,Txt,	
		GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
		;Gui,-Disabled
		Menu, ToolboxMenu, Enable, &Sysinternals ZoomIt
		return
	}
	goto, SkipZoomItDownload
}
GuiControl,1:Disable,Bye
GuiControl,1:,Txt,- Downloading -
; The followings need to be the default hotkeys, i.e. Ctrl+3 (Timer) and Ctrl+2 (Draw) for the function to work.
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, DrawToggleKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, BreakTimerKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, ToggleKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, EulaAccepted ; force user to reaccept EULA
;Gui,+Disabled ; To prevent user from moving panel. Now allow commented user to do so as download may take long.
UrlDownloadToFile, %userZoomItPath%, %A_WorkingDir%\Data\ZoomIt.exe
if (errorlevel<>0) {
	Msgbox, 262192, AeroZoom, Cannot download the file. Check Internet connection.`n`nYou may also manually put zoomit.exe into:`n`n%A_WorkingDir%\Data
	Gui, 1:Font, CDefault,
	GuiControl,1:Font,Txt,	
	GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
	;Gui,-Disabled
	GuiControl,1:Enable,Bye
	Menu, ToolboxMenu, Enable, &Sysinternals ZoomIt
	return
}
SkipZoomItDownload:
Gui, 1:Font, CDefault,
GuiControl,1:Font,Txt,	
Menu, ToolboxMenu, Enable, &Sysinternals ZoomIt
GuiControl,1:,Txt, AeroZoom %verAZ% ; v%verAZ%
GuiControl,1:Enable,Bye
;Gui,-Disabled
Msgbox, 262144, AeroZoom, Success.`n`nZoomIt will run in system tray alongside AeroZoom from now on.`n`n[Timer] and [Draw] are now available as buttons on the panel.`nConfigure their options in ZoomIt's tray icon or Tool > ZoomIt Options.`n`nStill zoom can be triggered/toggled by holding [Middle] mouse button for a specified time set in Tool > Advanced Options. Note it only works when zoomed out. If zoomed in, holding [Middle] triggers Full Screen Preview feature instead.`n`nFor usage and help, see '? > Quick Instructions > ZoomIt'.
skipEulaChk=1
ZoomItFirstRun=1
goto, ZoomIt
return

; Code from AutoHotkey help on GUI
; Note: with this on, if we also want to use 'keyboard shortcuts'(e.g. &Timer = press alt+T to run Timer), we must define a variable in each Gui, Add (e.g. vAnything) and refer to it using the var. Otherwise, strange error would pop up.

WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 1000
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 3000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

; Drag the borders to move the panel.
; http://www.autohotkey.com/forum/viewtopic.php?p=64185#64185 ; thanks to SKAN
uiMove:
PostMessage, 0xA1, 2,,, A 
Return

; EmailBugs:
; Run, mailto:wandersick+aerozoom@gmail.com?subject=AeroZoom %verAZ% Bug Report&body=Please describe your problem.
; return

; AeroZoom by WanderSick | http://wandersick.blogspot.com