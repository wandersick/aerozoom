; (c) Copyright 2009-2015 AeroZoom by a wandersick | http://wandersick.blogspot.com

; Sorry for the messy commenting in advance :D ... As the purpose is to contribute as much as possible,
; the source is released (GPL v2). Hope it helps! :D

; If you have any questions, corrections or suggestions, you may send them to wandersick@gmail.com or wandersick's blog. :D
; BTW, wandersick speaks English and Cantonese/Mandarin. For those who understand: Chung Man/Zhong Wen is okay! :D

#Persistent
#MaxHotkeysPerInterval 999
#SingleInstance force
SetBatchLines -1 ; run at fastest speed before init

IfEqual, unattendAZ, 1
	goto Install

verAZ = 4.0 beta 1
paused = 

; Working directory check
IfNotExist, %A_WorkingDir%\Data
{
	Msgbox, 262192, AeroZoom, Wrong working directory. Ensure AeroZoom is not run from its sub-folder.
	ExitApp
}

; QuickProfileSwitch
RegRead,profileName1,HKCU,Software\wandersick\AeroZoom,profileName1
if errorlevel
	profileName1 = Home
RegRead,profileName2,HKCU,Software\wandersick\AeroZoom,profileName2
if errorlevel
	profileName2 = Work
RegRead,profileName3,HKCU,Software\wandersick\AeroZoom,profileName3
if errorlevel
	profileName3 = On-the-Go
RegRead,profileName4,HKCU,Software\wandersick\AeroZoom,profileName4
if errorlevel
	profileName4 = Presentation
RegRead,profileName5,HKCU,Software\wandersick\AeroZoom,profileName5
if errorlevel
	profileName5 = Gaming

RegRead,profileInUse,HKCU,Software\wandersick\AeroZoom,profileInUse
if errorlevel
	profileInUse = 0

; If profileInUse is enabled, load default registry values and import selected profile
Gosub, LoadDefaultRegImportQuickProfile

RegRead,EnableAutoBackup,HKCU,Software\wandersick\AeroZoom,EnableAutoBackup
if errorlevel ; if the key is never created, i.e. first-run
{
	EnableAutoBackup=1 ; on by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, EnableAutoBackup, 1
}
; Does not require admin right anymore
; If not A_IsAdmin ; requires regedit.exe which requires admin rights. (reg add is OK but it is visible and annoying if set to Auto)
;	EnableAutoBackup=0
	
RegRead,Welcome,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,Welcome
if Welcome ; if AZ version 2.0 or above is found, that means AeroZoom settings are found
{
	RegRead,ProgramVer,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,ProgramVer
	if (ProgramVer<>verAZ)
	{
		; prevent the same msgbox from prompting in each profile
		If not profileInUse
		{
			Msgbox, 262212, Found AeroZoom settings, Settings from a different version of AeroZoom has been found in the system registry. Would you like to use it (Yes)?`n`nIf you choose 'No', AeroZoom will back up the current settings before clearing them.`n`nTip: If problems arise after keeping old settings, a reset can be performed in 'Tool > Preferences > Advanced Options'.
			IfMsgbox, No
			{
				RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom
				Gosub, SaveCurrentProfile
				reload
			}
		}
	}
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ProgramVer, %verAZ%

RegRead,OSver,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentVersion

; new for Windows 10 (replaces the former if CurrentMajorVersionNumber is available)
; in Win 10, CurrentVersion is still 6.3 (same as Win 8.1) but CurrentMajorVersionNumber is new
if (OSver=6.3) {
	RegRead,CurrentMajorVersionNumber,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentMajorVersionNumber
	if (CurrentMajorVersionNumber=10) {
		OSver=10
	}
}

if (OSver<5.1) { ; if older than xp
	RegRead,oldOSwarning,HKCU,Software\wandersick\AeroZoom,oldOSwarning
	if errorlevel
	{
		If not profileInUse
			Msgbox, 262192, This message will only be shown once, You're using an OS earlier than Windows XP. Expect abnormal behaviors.
	}

	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, oldOSwarning, 1
} else if (OSver>10) {
	RegRead,newOSwarning,HKCU,Software\wandersick\AeroZoom,newOSwarning
	if errorlevel
	{
		If not profileInUse
			Msgbox, 262144, This message will only be shown once, You're using an newer operating system AeroZoom may not totally support.`n`nPlease urge wandersick or check http://wandersick.blogspot.com for a new version.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, newOSwarning, 1
	}
}

if (OSver>=6.1) { ; win7's mag cant be terminated by users with standard UAC on, unlike vista or xp
	RegRead,EnableLUA,HKLM,SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System,EnableLUA
	if EnableLUA {
		if not A_IsAdmin
		{
			RegRead,limitedAcc,HKCU,Software\wandersick\AeroZoom,limitedAcc
			if errorlevel
			{
				If not profileInUse
					Msgbox, 262180, This message will only be shown once, You're using a Limited User Account with User Account Control (UAC) on Windows. Some functions of AeroZoom does not work under this condition. Please disable UAC or run AeroZoom as Administrator; otherwise AeroZoom will run in a limited functionality mode.`n`nClick 'Yes to disable UAC (Requires admin rights).`nClick 'No' to continue AeroZoom in limited mode.
				RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, limitedAcc, 1
				IfMsgBox Yes
				{
					RunWait, *Runas "%A_WorkingDir%\Data\DisableUAC.exe" ; disable UAC
					If (errorlevel=100) { ; if success and reboot is pending
						Exitapp
					}
				}
			}
		}
	}
}

if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
	RegRead,limitedAcc2,HKCU,Software\wandersick\AeroZoom,limitedAcc2
	if errorlevel
	{
		If not profileInUse
			Msgbox,262208,This message will only be shown once,You can return AeroZoom to full functionality mode anytime at 'Az > Switch to Full Functionality Mode' or 'Az > Switch off User Account Control'.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, limitedAcc2, 1
	}
}

if (OSver>=6.0) { ; vista or later includes editions
	RegRead,EditionID,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,EditionID
}
if (OSver>=6.1) { ; win 7 start/home basic doesnt support aero and snipping tool
	If (EditionID="Starter") {
		RegRead,EditionMsg,HKCU,Software\wandersick\AeroZoom,EditionMsg
		if errorlevel
		{
			If not profileInUse
				Msgbox,262208,This message will only be shown once,You are using Windows 7 Starter which does not support Aero.`n`nAero is required for Full Screen and Lens views of Magnifier, therefore only Docked view is available.`n`nAs a workaround, AeroZoom adds wheel-zoom capability to the Live Zoom function of Sysinternals ZoomIt, a Microsoft freeware screen magnifier, which is full screen. To use this feature, enable 'Tools > Wheel-Zoom by ZoomIt', or disable it a docked magnifier is wanted.`n`nAlso, AeroSnip requires Home Premium or later, so only the Print Screen button is enhanced to Save Captures to disk, and optionally paste in an editor afterwards. You can enable this feature in 'Tool > Save Captures' and configure the details in 'Tool > Preferences > AeroSnip Options'.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, EditionMsg, 1
		}
	} else if (EditionID="HomeBasic") {
		RegRead,EditionMsg2,HKCU,Software\wandersick\AeroZoom,EditionMsg2
		if errorlevel
		{
			If not profileInUse
				Msgbox,262208,This message will only be shown once,You are using Windows 7 Home Basic which does not support Aero.`n`nAero is required for Full Screen and Lens views of Magnifier, therefore only Docked view is available.`n`nAs a workaround, AeroZoom adds wheel-zoom capability to the Live Zoom function of Sysinternals ZoomIt, a Microsoft freeware screen magnifier, which is full screen. To use this feature, enable 'Tools > Wheel-Zoom by ZoomIt', or disable it if a docked magnifier is wanted.`n`nAlso, AeroSnip requires Home Premium or later, so only Print Screen button is enhanced to Save Captures to disk, and optionally paste in an editor afterwards. You can enable this feature in 'Tool > Save Captures' and configure the details in 'Tool > Preferences > AeroSnip Options'.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, EditionMsg2, 1
		}
	}
}
	
; Check Mouse-Centered Zoom bit
if (OSver>=6.1)
	RegRead,mouseCenteredZoomBit,HKCU,Software\wandersick\AeroZoom,mouseCenteredZoomBit

; Check numPadAddBit and numPadSubBit
; for Windows 10 (and possibly others), #{NumpadAdd} and #- seem to work better than other combinations. This avoids +/- character being generated during zoom in/out
; Reference:
; numPadAddBit  1 = {NumpadAdd}  0 = {+}
; numPadSubBit  1 = {NumpadSub}  0 = {-}
RegRead,numPadAddBit,HKCU,Software\wandersick\AeroZoom,numPadAddBit
if errorlevel ; if the key is never created, i.e. first-run
{
	numPadAddBit=1 ; {NumpadAdd} by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, numPadAddBit, 1
}
RegRead,numPadSubBit,HKCU,Software\wandersick\AeroZoom,numPadSubBit
if errorlevel ; if the key is never created, i.e. first-run
{
	numPadSubBit=0 ; {-} by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, numPadSubBit, 0
}

; enable live zoom for vista or win 7 home basic and starter
RegRead,zoomitLive,HKCU,Software\wandersick\AeroZoom,zoomitLive
if errorlevel
{
	if (OSver>=6.1 AND (EditionID="HomeBasic" OR EditionID="Starter")) {
		zoomitLive=1
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitLive, 1
	}
}

if (OSver>=6) { ; xp uses still zoom automatically
	RegRead,zoomitStill,HKCU,Software\wandersick\AeroZoom,zoomitStill
	If (OSver>=6.1) { ; under win 7, if both still and live are on, live will take precedence unless the following is done
		If zoomitStill
			zoomitLive=
	}
}

if (OSver=6.0) { ; vista msg
	zoomitLive=1 ; forced to use Live Zoom on Vista
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitLive, 1
	If (EditionID="Starter") {
		zoomitStill=1 ; ZoomIt requires Aero for Live Zoom to work under Vista (Win7 is OK) but Vista Home Basic/Starter does not have Aero, so only Still Zoom is used.
		RegRead,VistaMsg,HKCU,Software\wandersick\AeroZoom,VistaMsg
		if errorlevel
		{
			If not profileInUse
				Msgbox,262208,This message will only be shown once,AeroZoom works best on Windows 7 Home Premium or above. You are using Windows Vista Starter which does not support full-screen zoom or Aero.`n`nAs a workaround, AeroZoom adds wheel-zoom capability to the Still Zoom function of Sysinternals ZoomIt, a Microsoft freeware screen magnifier, which is full screen.`n`nAlso, AeroSnip requires Home Premium or later, so only Print Screen button is enhanced to automatically Save Captures, and optionally paste in an editor afterwards. You can enable this feature by pushing the slider on AeroZoom panel to the right and configure the details in 'Tool > Preferences > AeroSnip Options'.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, VistaMsg, 1
		}
	} else if (EditionID="HomeBasic") {
		zoomitStill=1 ; ZoomIt requires Aero for Live Zoom to work under Vista (Win7 is OK) but Vista Home Basic/Starter does not have Aero, so only Still Zoom is used.
		RegRead,VistaMsg2,HKCU,Software\wandersick\AeroZoom,VistaMsg2
		if errorlevel
		{
			If not profileInUse
				Msgbox,262208,This message will only be shown once,AeroZoom works best on Windows 7 Home Premium or above. You are using Windows Vista Home Basic which does not support full-screen zoom or Aero.`n`nAs a workaround, AeroZoom adds wheel-zoom capability to the Still Zoom function of Sysinternals ZoomIt, a Microsoft freeware screen magnifier, which is full screen.`n`nAlso, AeroSnip requires Home Premium or later, so only Print Screen button is enhanced to automatically Save Captures, and optionally paste in an editor afterwards. You can enable this feature by pushing the slider on AeroZoom panel to the right and configure the details in 'Tool > Preferences > AeroSnip Options'.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, VistaMsg2, 1
		}
	} else {
		RegRead,VistaMsg3,HKCU,Software\wandersick\AeroZoom,VistaMsg3
		if errorlevel
		{
			If not profileInUse
				Msgbox,262208,This message will only be shown once,AeroZoom works best on Windows 7 Home Premium or above. You are using Windows Vista which does not support full-screen zoom.`n`nAs a workaround, AeroZoom adds wheel-zoom capability to the Live Zoom function of Sysinternals ZoomIt, a Microsoft freeware screen magnifier, which is full screen.`n`nOn the other hand, AeroSnip enhances Snipping Tool and the Print Screen button to automatically Save Captures, and optionally paste in an editor afterwards. You can enable this feature in 'Tool > Save Captures' and configure the details in 'Tool > Preferences > AeroSnip Options'.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, VistaMsg3, 1
		}
	}
}

;if (OSver<6) OR (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
;	zoomitLive= ; safety measure for win7 non-basic os (if the aerozoom settings were imported from another version of windows)
;}

if (OSver<6.0) { ; xp msg
	RegRead,XPmsg,HKCU,Software\wandersick\AeroZoom,XPmsg
	if errorlevel
	{
		If not profileInUse
			Msgbox,262208,This message will only be shown once,AeroZoom works best on Windows 7 Home Premium or above, but you use an earlier OS that does not support full-screen zoom. As a workaround, AeroZoom adds wheel-zoom capability to the zoom function of Sysinternals ZoomIt, a Microsoft freeware screen magnifier, which is full screen. (Note: Zoom is only still on this OS, as live zooming requires Vista or later.)`n`nAlso, AeroSnip requires Windows Vista Home Premium or later, so only the Print Screen button is enhanced to Save Captures to disk, and optionally paste in an editor afterwards. You can enable this feature by pushing the slider on AeroZoom panel to the right and configure the details in 'Tool > Preferences > AeroSnip Options'.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, XPmsg, 1
	}
}

IfExist, %windir%\system32\SnippingTool.exe
{
	If (EditionID<>"HomeBasic" AND EditionID<>"Starter") {
		SnippingToolExists=1
	}
}

;{
;   DllCall("shell32\ShellExecuteA", uint, 0, str, "RunAs", str, A_AhkPath
;      , str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1)  ; Last parameter: SW_SHOWNORMAL = 1
;   ExitApp
;}

; blank separator
; menu, tray, add
menu, tray, NoStandard
; When the user double-clicks the tray icon, its default menu item is launched (show panel). 
menu, tray, add, &Show Panel`t[Win+Shift+ESC], showPanel
If not menuInit
	menu, tray, add ; separator
menu, tray, Default, &Show Panel`t[Win+Shift+ESC]
menu, tray, add, &Pause All Hotkeys`t[Click tray icon], SuspendScript
menu, tray, add, Pause &Mouse Hotkeys`t[Win+Alt+H], PauseScriptViaTrayPauseMouseOnly
If not menuInit
	menu, tray, add ; separator
menu, tray, add, &Quick Instructions`t[Win+Alt+Q], Instruction
If not menuInit
	menu, tray, add ; separator
Menu, tray, Add, User Experience &Survey, UserExperienceSurvey
Menu, tray, Add, AeroZoom &Web, VisitWeb
menu, tray, add, &About, HelpAbout
If not menuInit
	menu, tray, add ; separator
if profileInUse {
	profileInUseDisplay = %profileInUse%
} else {
	profileInUseDisplay = None
}
menu, tray, add, Restore &Default Settings [Profile: %profileInUseDisplay%], RestoreDefaultSettings
	menu, tray, add ; separator
menu, tray, add, &Restart, RestartAZ
menu, tray, add, &Exit, ExitAZ
Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom.ico, ,1
Menu, Tray, Tip, AeroZoom %verAZ% with AeroSnip`n`n1. Click to disable/enable hotkeys`n2. Double-click for AeroZoom Panel

; disable Magnifier warning in XP
if (OSver<6) { 
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Magnify, ShowWarning, 0x0
}

; for Snipping Tool to work or work better (does this only once at fresh run)
if not Welcome
{
	RegRead,AutoCopyToClipboard,HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool,AutoCopyToClipboard
	If not (AutoCopyToClipboard=0x1)
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, AutoCopyToClipboard, 0x1

	RegRead,PromptToSave,HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool,PromptToSave
	If (PromptToSave=0x1 OR !PromptToSave)
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, PromptToSave, 0x0
}

; Change calc class

If (OSver>=6.1) {
	calcClass=CalcFrame
} Else {
	calcClass=SciCalc
}

; RegData Ini Read

IniRead, regName, %A_WorkingDir%\Data\AeroZoom.ini, RegData, Name
IniRead, regType, %A_WorkingDir%\Data\AeroZoom.ini, RegData, Type
IniRead, regSN, %A_WorkingDir%\Data\AeroZoom.ini, RegData, SN
if (regSN="AZDF9-839JD-2UDUH-GYUA9-2I9EF")
	registered:=1

; Snipping Tool init - START

RegRead,PrintScreenEnhanceCheckbox,HKCU,Software\wandersick\AeroZoom,PrintScreenEnhanceCheckbox
if errorlevel 
{
	PrintScreenEnhanceCheckbox=1
}

If !SnippingToolExists ; force this to be on. for system without snipping tools, it doesnt need to decide between snipping or normal capturing
	PrintScreenEnhanceCheckbox=1

RegRead,SnipSaveFormatNo,HKCU,Software\wandersick\AeroZoom,SnipSaveFormatNo
If errorlevel
	SnipSaveFormatNo=5
; 1 .bmp, 2 .gif, 3 .jpg, 4 .tiff, 5 .png (default)

If (SnipSaveFormatNo=1) {
	SnipSaveFormat=bmp
} else if (SnipSaveFormatNo=2) {
	SnipSaveFormat=gif
} else if (SnipSaveFormatNo=3) {
	SnipSaveFormat=jpg
} else if (SnipSaveFormatNo=4) {
	SnipSaveFormat=tiff
} else {
	SnipSaveFormat=png
}

RegRead,SnipSaveDir,HKCU,Software\wandersick\AeroZoom,SnipSaveDir
IfNotExist, %SnipSaveDir%
	SnipSaveDir=%A_Desktop%
	
RegRead,SnipWin,HKCU,Software\wandersick\AeroZoom,SnipWin
If errorlevel
	SnipWin=3 ; default: show.  minimize better if user use the snip in apps other than snipping tool
; 1 = hide  2 = min  3 = show

RegRead,SnipRunBeforeCommandCheckbox,HKCU,Software\wandersick\AeroZoom,SnipRunBeforeCommandCheckbox
RegRead,SnipRunBeforeCommand,HKCU,Software\wandersick\AeroZoom,SnipRunBeforeCommand
RegRead,SnipRunCommandCheckbox,HKCU,Software\wandersick\AeroZoom,SnipRunCommandCheckbox
RegRead,SnipRunCommand,HKCU,Software\wandersick\AeroZoom,SnipRunCommand
if errorlevel 
{
	SnipRunCommand=mspaint
}
RegRead,SnipPasteCheckbox,HKCU,Software\wandersick\AeroZoom,SnipPasteCheckbox
if errorlevel 
{
	SnipPasteCheckbox=1
}
RegRead,SnipDelay,HKCU,Software\wandersick\AeroZoom,SnipDelay

;RegRead,SnipToClipboard,HKCU,Software\wandersick\AeroZoom,SnipToClipboard
;If errorlevel
;	SnipToClipboard=1

; 1 = free-form  2 = rectangular  3 = window  4 = full-screen
RegRead,SnipMode,HKCU,Software\wandersick\AeroZoom,SnipMode
If errorlevel
	SnipMode=2
	
; Snipping Tool init - END
	
RegRead,padBorder,HKCU,Software\wandersick\AeroZoom,padBorder
if errorlevel
{
	padBorder=2 ; no
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padBorder, 2
}
RegRead,padTrans,HKCU,Software\wandersick\AeroZoom,padTrans
if errorlevel
{
	padTrans=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padTrans, 1
}
RegRead,zoomitColor,HKCU,Software\wandersick\AeroZoom,ZoomitColor
RegRead,zoomitPanel,HKCU,Software\wandersick\AeroZoom,ZoomitPanel
RegRead,zoomItGuidance,HKCU,Software\wandersick\AeroZoom,ZoomItGuidance
RegRead,killGuidance,HKCU,Software\wandersick\AeroZoom,killGuidance
RegRead,configGuidance,HKCU,Software\wandersick\AeroZoom,configGuidance
; RegRead,profileGuidance,HKCU,Software\wandersick\AeroZoom,profileGuidance

; for customizing google url
RegRead,GoogleUrl,HKCU,Software\wandersick\AeroZoom,GoogleUrl
if errorlevel
{
	GoogleUrl=google.com
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, GoogleUrl, google.com
}


RegRead,OSD,HKCU,Software\wandersick\AeroZoom,OSD
if errorlevel
{
	OSD=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, OSD, 1
}


; required by the Customizable hotkeys (esp the back/forward buttons)
RegRead,padStayTime,HKCU,Software\wandersick\AeroZoom,padStayTime
if errorlevel
{
	padStayTime=150
}


; for Customize MButton
RegRead,CustomMiddlePath,HKCU,Software\wandersick\AeroZoom,CustomMiddlePath
if errorlevel 
{
	CustomMiddlePath=Run a command, program or URL
}
RegRead,MiddleButtonAction,HKCU,Software\wandersick\AeroZoom,MiddleButtonAction
if errorlevel ; if the key is never created, i.e. first-run
{
	; MiddleButtonAction=1 ; snip by default
	MiddleButtonAction=42 ; No action by default (since v4.0, as it may annoy users and Snipping Tool automation does not work as well in Win 10)
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, MiddleButtonAction, 1
}

; --
; Custom Hotkey (Part 1) Start
; --

; This part also exists in the external Custom Hotkey exe's

; for Customize Left/Right Buttons
RegRead,CustomLeftMiddlePath,HKCU,Software\wandersick\AeroZoom,CustomLeftMiddlePath
if errorlevel 
{
	CustomLeftMiddlePath=! Select 'Custom (define)' !
}
RegRead,CustomLeftRightPath,HKCU,Software\wandersick\AeroZoom,CustomLeftRightPath
RegRead,CustomLeftWupPath,HKCU,Software\wandersick\AeroZoom,CustomLeftWupPath
RegRead,CustomLeftWdownPath,HKCU,Software\wandersick\AeroZoom,CustomLeftWdownPath
RegRead,CustomRightLeftPath,HKCU,Software\wandersick\AeroZoom,CustomRightLeftPath
RegRead,CustomRightMiddlePath,HKCU,Software\wandersick\AeroZoom,CustomRightMiddlePath
RegRead,CustomRightWupPath,HKCU,Software\wandersick\AeroZoom,CustomRightWupPath
RegRead,CustomRightWdownPath,HKCU,Software\wandersick\AeroZoom,CustomRightWdownPath
RegRead,LeftMiddleAction,HKCU,Software\wandersick\AeroZoom,LeftMiddleAction
if errorlevel ; if the key is never created, i.e. first-run
{
	LeftMiddleAction=41
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftMiddleAction, 41
}
RegRead,LeftRightAction,HKCU,Software\wandersick\AeroZoom,LeftRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	LeftRightAction=38 ; showHidePanel
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftRightAction, 38
}


RegRead,LeftWupAction,HKCU,Software\wandersick\AeroZoom,LeftWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	LeftWupAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftWupAction, 37
}
RegRead,LeftWdownAction,HKCU,Software\wandersick\AeroZoom,LeftWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	LeftWdownAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftWdownAction, 37
}


RegRead,RightLeftAction,HKCU,Software\wandersick\AeroZoom,RightLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	RightLeftAction=38 ; showHidePanel
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightLeftAction, 38
}
RegRead,RightMiddleAction,HKCU,Software\wandersick\AeroZoom,RightMiddleAction
if errorlevel ; if the key is never created, i.e. first-run
{
	RightMiddleAction=41
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightMiddleAction, 41
}

RegRead,RightWupAction,HKCU,Software\wandersick\AeroZoom,RightWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	RightWupAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightWupAction, 37
}
RegRead,RightWdownAction,HKCU,Software\wandersick\AeroZoom,RightWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	RightWdownAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightWdownAction, 37
}


; for Customize XButton
RegRead,CustomBackLeftPath,HKCU,Software\wandersick\AeroZoom,CustomBackLeftPath
if errorlevel 
{
	CustomBackLeftPath=! Select 'Custom (define)' !
}
RegRead,CustomBackRightPath,HKCU,Software\wandersick\AeroZoom,CustomBackRightPath
RegRead,CustomBackWupPath,HKCU,Software\wandersick\AeroZoom,CustomBackWupPath
RegRead,CustomBackWdownPath,HKCU,Software\wandersick\AeroZoom,CustomBackWdownPath
RegRead,CustomForwardLeftPath,HKCU,Software\wandersick\AeroZoom,CustomForwardLeftPath
RegRead,CustomForwardRightPath,HKCU,Software\wandersick\AeroZoom,CustomForwardRightPath
RegRead,CustomForwardWupPath,HKCU,Software\wandersick\AeroZoom,CustomForwardWupPath
RegRead,CustomForwardWdownPath,HKCU,Software\wandersick\AeroZoom,CustomForwardWdownPath
RegRead,BackLeftAction,HKCU,Software\wandersick\AeroZoom,BackLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	BackLeftAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackLeftAction, 37
}
RegRead,BackRightAction,HKCU,Software\wandersick\AeroZoom,BackRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	BackRightAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackRightAction, 37
}


RegRead,BackWupAction,HKCU,Software\wandersick\AeroZoom,BackWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	BackWupAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackWupAction, 37
}
RegRead,BackWdownAction,HKCU,Software\wandersick\AeroZoom,BackWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	BackWdownAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackWdownAction, 37
}


RegRead,ForwardLeftAction,HKCU,Software\wandersick\AeroZoom,ForwardLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ForwardLeftAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardLeftAction, 37
}
RegRead,ForwardRightAction,HKCU,Software\wandersick\AeroZoom,ForwardRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ForwardRightAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardRightAction, 37
}

RegRead,ForwardWupAction,HKCU,Software\wandersick\AeroZoom,ForwardWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ForwardWupAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardWupAction, 37
}
RegRead,ForwardWdownAction,HKCU,Software\wandersick\AeroZoom,ForwardWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ForwardWdownAction=37
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardWdownAction, 37
}

; for Customize Keys
RegRead,template,HKCU,Software\wandersick\AeroZoom,template
RegRead,CustomCtrlLeftPath,HKCU,Software\wandersick\AeroZoom,CustomCtrlLeftPath
if template 
{
	CustomCtrlLeftPath="C:\Users\Public\Music\Sample Music\Sleep Away.mp3"
}
RegRead,CustomCtrlRightPath,HKCU,Software\wandersick\AeroZoom,CustomCtrlRightPath
if template 
{
	CustomCtrlRightPath=www.google.hk
}
RegRead,CustomCtrlWupPath,HKCU,Software\wandersick\AeroZoom,CustomCtrlWupPath
if template 
{
	CustomCtrlWupPath=::{645ff040-5081-101b-9f08-00aa002f954e}
}
RegRead,CustomCtrlWdownPath,HKCU,Software\wandersick\AeroZoom,CustomCtrlWdownPath
if template 
{
	CustomCtrlWdownPath=cmd /c start "" /min http://english-quotes.blogspot.com
}
RegRead,CustomAltLeftPath,HKCU,Software\wandersick\AeroZoom,CustomAltLeftPath
if errorlevel 
{
	CustomAltLeftPath=! Select 'Custom (define)' !
}
if template
{
	CustomAltLeftPath=cmd
}
RegRead,CustomAltRightPath,HKCU,Software\wandersick\AeroZoom,CustomAltRightPath
if template 
{
	CustomAltRightPath=*RunAs cmd
}
RegRead,CustomAltWupPath,HKCU,Software\wandersick\AeroZoom,CustomAltWupPath
if template 
{
	CustomAltWupPath=mspaint
}
RegRead,CustomAltWdownPath,HKCU,Software\wandersick\AeroZoom,CustomAltWdownPath
if template 
{
	CustomAltWdownPath=wmplayer
}
RegRead,CustomShiftLeftPath,HKCU,Software\wandersick\AeroZoom,CustomShiftLeftPath
if template 
{
	CustomShiftLeftPath=mailto:wandersick@gmail.com
}
RegRead,CustomShiftRightPath,HKCU,Software\wandersick\AeroZoom,CustomShiftRightPath
if template 
{
	CustomShiftRightPath=cmd /c echo `%date`% `%time`%&pause
}
RegRead,CustomShiftWupPath,HKCU,Software\wandersick\AeroZoom,CustomShiftWupPath
if template 
{
	CustomShiftWupPath=http://wandersick.blogspot.com
}
RegRead,CustomShiftWdownPath,HKCU,Software\wandersick\AeroZoom,CustomShiftWdownPath
if template 
{
	CustomShiftWdownPath=properties c:
}
RegRead,CustomWinLeftPath,HKCU,Software\wandersick\AeroZoom,CustomWinLeftPath
if template 
{
	CustomWinLeftPath=explore c:\
}
RegRead,CustomWinRightPath,HKCU,Software\wandersick\AeroZoom,CustomWinRightPath
if template 
{
	CustomWinRightPath=find c:
}
RegRead,CustomWinWupPath,HKCU,Software\wandersick\AeroZoom,CustomWinWupPath
if template 
{
	CustomWinWupPath=edit "%A_WorkingDir%\Readme.txt"
}
RegRead,CustomWinWdownPath,HKCU,Software\wandersick\AeroZoom,CustomWinWdownPath
if template 
{
	CustomWinWdownPath=[REMOVE] print "%A_WorkingDir%\Readme.txt"
}
RegRead,CtrlLeftAction,HKCU,Software\wandersick\AeroZoom,CtrlLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	CtrlLeftAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlLeftAction, 41
}
RegRead,CtrlRightAction,HKCU,Software\wandersick\AeroZoom,CtrlRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	CtrlRightAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlRightAction, 41
}
RegRead,CtrlWupAction,HKCU,Software\wandersick\AeroZoom,CtrlWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	CtrlWupAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlWupAction, 39
}
RegRead,CtrlWdownAction,HKCU,Software\wandersick\AeroZoom,CtrlWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	CtrlWdownAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlWdownAction, 39
}
RegRead,AltLeftAction,HKCU,Software\wandersick\AeroZoom,AltLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	AltLeftAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltLeftAction, 41
}
RegRead,AltRightAction,HKCU,Software\wandersick\AeroZoom,AltRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	AltRightAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltRightAction, 41
}
RegRead,AltWupAction,HKCU,Software\wandersick\AeroZoom,AltWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	AltWupAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltWupAction, 39
}
RegRead,AltWdownAction,HKCU,Software\wandersick\AeroZoom,AltWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	AltWdownAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltWdownAction, 39
}
RegRead,ShiftLeftAction,HKCU,Software\wandersick\AeroZoom,ShiftLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ShiftLeftAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftLeftAction, 41
}
RegRead,ShiftRightAction,HKCU,Software\wandersick\AeroZoom,ShiftRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ShiftRightAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftRightAction, 41
}
RegRead,ShiftWupAction,HKCU,Software\wandersick\AeroZoom,ShiftWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ShiftWupAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftWupAction, 39
}
RegRead,ShiftWdownAction,HKCU,Software\wandersick\AeroZoom,ShiftWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	ShiftWdownAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftWdownAction, 39
}
RegRead,WinLeftAction,HKCU,Software\wandersick\AeroZoom,WinLeftAction
if errorlevel ; if the key is never created, i.e. first-run
{
	WinLeftAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinLeftAction, 41
}
RegRead,WinRightAction,HKCU,Software\wandersick\AeroZoom,WinRightAction
if errorlevel ; if the key is never created, i.e. first-run
{
	WinRightAction=41 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinRightAction, 41
}
RegRead,WinWupAction,HKCU,Software\wandersick\AeroZoom,WinWupAction
if errorlevel ; if the key is never created, i.e. first-run
{
	WinWupAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinWupAction, 39
}
RegRead,WinWdownAction,HKCU,Software\wandersick\AeroZoom,WinWdownAction
if errorlevel ; if the key is never created, i.e. first-run
{
	WinWdownAction=39 ; none by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinWdownAction, 39
}

; --
; Custom Hotkey (Part 1) End
; --

; Dynamic switching (simply choose None: Dynamic. No need for this)
RegRead,DisableZoomItMiddle,HKCU,Software\wandersick\AeroZoom,DisableZoomItMiddle
if errorlevel {
	DisableZoomItMiddle=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, DisableZoomItMiddle, 1
}
RegRead,disablePreviewFullScreen,HKCU,Software\wandersick\AeroZoom,DisablePreviewFullScreen
; Retrieve hold middle setting

RegRead,disableZoomResetHotkey,HKCU,Software\wandersick\AeroZoom,DisableZoomResetHotkey
; Retrieve disable zoom reset hotkey setting
	
RegRead,holdMiddle,HKCU,Software\wandersick\AeroZoom,holdMiddle
if errorlevel ; if the key is never created, i.e. first-run
{
	holdMiddle=1 ; hold middle button to snip/still zoom by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, holdMiddle, 1
}
RegRead,CtrlAltShiftWin,HKCU,Software\wandersick\AeroZoom,CtrlAltShiftWin
RegRead,ForwardBack,HKCU,Software\wandersick\AeroZoom,ForwardBack
RegRead,LeftRight,HKCU,Software\wandersick\AeroZoom,LeftRight

; RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,Invert
; If last set, reflect color inversion immediately

; Whether to use -1- Zoom Rate slider -2- or Magnify Slider -3- or Snipping slider -4- or older OS slider
RegRead,SwitchSlider,HKCU,Software\wandersick\AeroZoom,SwitchSlider
if errorlevel
{
	If (OSver>=6.1) {
		;If SnippingToolExists
		;{
		;	SwitchSlider=3
		;}
		;Else
		;{
			If (!A_IsAdmin AND EnableLUA) { ; zoom inc slider involves killing mag process which is impossible under limited acc with uac
				SwitchSlider=2
			} else {
				SwitchSlider=1 ; use Zoom Rate slider as default setting since v4.0 (fading out AeroSnip)
			}
		;}
	} else if (OSver=6) {
		;If SnippingToolExists
		;	SwitchSlider=3
		SwitchSlider=1 ; use Zoom Rate slider as default setting since v4.0 (fading out AeroSnip)
	} else {
		SwitchSlider=4
	}
}

; Ensure SwitchSlider settings work across Windows versions

If (OSver>=6.1) {
	If (SwitchSlider=4) { ; 4 is reserved for vista home basic/starter and xp
		If SnippingToolExists
		{
			SwitchSlider=3
		}
		Else
		{
			If (!A_IsAdmin AND EnableLUA) { ; zoom inc slider involves killing mag process which is impossible under win 7 limited acc with uac
				SwitchSlider=2
			} else {
				SwitchSlider=1
			}
		}
	} else if (SwitchSlider=3) {
		If !SnippingToolExists
		{
			If (!A_IsAdmin AND EnableLUA) { ; zoom inc slider involves killing mag process which is impossible under win 7 limited acc with uac
				SwitchSlider=2
			} else {
				SwitchSlider=1
			}
		}
	} else if (SwitchSlider=1) {
		If (!A_IsAdmin AND EnableLUA) { ; zoom inc slider involves killing mag process which is impossible under win 7 limited acc with uac
			SwitchSlider=2
		}
	}
} else if (OSver=6) {
	If (EditionID="Starter" OR EditionID="HomeBasic")
	{
		If (SwitchSlider<>4) { ; 4 is the only slider that can be used for vista home basic. (4 is an unknown tool as of this moment)
			SwitchSlider=4
		}
	} else {
		If (SwitchSlider<>3) { ; snipping tool (3) is available
			SwitchSlider=3
		}
	}
} else if (OSver<6) {
	If (SwitchSlider<>4) { ; 4 is the only slider that can be used for xp
		SwitchSlider=4
	}
}

; Whether to use Mini mode or Normal mode
RegRead,SwitchMiniMode,HKCU,Software\wandersick\AeroZoom,SwitchMiniMode

RegRead,hideOrMin,HKCU,Software\wandersick\AeroZoom,HideOrMin ; hide (1) or minimize (2) or do neither (3)
if errorlevel
{
	HideOrMin=1
	if (OSver>=6.2)
		HideOrMin=2 ; In Windows 8, Magnifier cannot be closed gracefully when hidden (a graceful close is required for the big 4 buttons and zoominc to work.)
}
RegRead,hideOrMinPrev,HKCU,Software\wandersick\AeroZoom,HideOrMin
if errorlevel
{
	HideOrMinPrev=1 ; Prev is for Advanced Options
	if (OSver>=6.2)
		HideOrMinPrev=2 ; For Windows 8 ...
}

; Retrieve last window positions. Applied if any of the radio buttons (except its own) is triggered.
; Otherwise, after launching script, window will not popup until user press left and right buttons
; where the position will be the MousePos at that time instead.

lastPosX=
lastPosY=
RegRead,lastPosX,HKCU,Software\wandersick\AeroZoom,lastPosX
if not errorlevel
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX ; prevent it from reuse
RegRead,lastPosY,HKCU,Software\wandersick\AeroZoom,lastPosY
if not errorlevel
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY

; Retrieve Notepad settings from Registry
; REG_SZ. 1 = use notepad. Otherwise, use WordPad (if customEdCheckbox is 1, then no Notepad/Wordpad)

RegRead,notepad,HKCU,Software\wandersick\AeroZoom,Notepad

; Retrieve ZoomPad settings from Registry
; REG_SZ. 1 = disable ZoomPad.

RegRead,ZoomPad,HKCU,Software\wandersick\AeroZoom,ZoomPad
if errorlevel ; if the key is never created, i.e. first-run
{
	zoomPad=1 ; zoom pad on by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomPad, 1
}

RegRead,ElasticZoom,HKCU,Software\wandersick\AeroZoom,ElasticZoom
if errorlevel ; if the key is never created, i.e. first-run
{
	ElasticZoom=1 ; Elastic Zoom on by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ElasticZoom, 1
}

RegRead,NirCmd,HKCU,Software\wandersick\AeroZoom,NirCmd


; Retrieve Sysinternals ZoomIt preference from Registry
; REG_SZ. 1 = enhance with ZoomIt. Otherwise, use Win 7 tools

RegRead,zoomit,HKCU,Software\wandersick\AeroZoom,zoomit
if (zoomit=1) {
	Process, Exist, ZoomIt.exe
	If (errorlevel=0) {
		IfExist, %A_WorkingDir%\Data\ZoomIt.exe
		{
			Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		}
	}
}

; ----------------------------------------------------- Radio Button 1 of 3 (Retrieve setting)

; Retrieve last checked radio button from Registry

RegRead,chkModRaw,HKCU,Software\wandersick\AeroZoom,Modifier
if (chkModRaw=0x1) {
	chkCtrl=Checked
	chkMod=1
	;chkModRaw=1
	modDisp=Ctrl key
	modDispAlt=Ctrl
} else if (chkModRaw=0x2) {
	chkAlt=Checked
	chkMod=2
	;chkModRaw=2
	modDisp=Alt key
	modDispAlt=Alt
} else if (chkModRaw=0x3) {
	chkShift=Checked
	chkMod=3
	;chkModRaw=3
	modDisp=Shift key
	modDispAlt=Shift
} else if (chkModRaw=0x4) {
	chkWin=Checked
	chkMod=4
	;chkModRaw=4
	modDisp=Windows key
	modDispAlt=Win
} else if (chkModRaw=0x5) {
	chkMouseL=Checked
	chkMod=5
	;chkModRaw=5
	modDisp=Left mouse click
	modDispAlt=Left
} else if (chkModRaw=0x6) {
	chkMouseR=Checked
	chkMod=6
	;chkModRaw=6
	modDisp=Right mouse click
	modDispAlt=Right
} else if (chkModRaw=0x7) {
	chkMouseM=Checked
	chkMod=7
	;chkModRaw=7
	modDisp=Middle mouse click
	modDispAlt=Middle
} else if (chkModRaw=0x8) {
	chkMouseX1=Checked
	chkMod=8
	;chkModRaw=8
	modDisp=Forward (Special)
	modDispAlt=Fwd
	modDispReverse=Back
} else if (chkModRaw=0x9) {
	chkMouseX2=Checked
	chkMod=9
	;chkModRaw=9
	modDisp=Back (Special)
	modDispAlt=Back
	modDispReverse=Fwd
} else {
	chkMouseL=Checked
	chkMod=5
	;chkModRaw=5
	modDisp=Left mouse click
	modDispAlt=Left
}
; ----------------------------------------------------- Radio Button 1 of 3 END


; ----------------------------------------------------- Zoom Increment 1 of 3 (Retrieve last setting)

; Retrieve Zoom Increment and magnification from Registry to preset the slider

Gosub, ReadValueUpdatePanel
; ----------------------------------------------------- Zoom Increment 1 of 3 END

; Retrieve Advanced Options settings (Once more when opening Advanced Options menu
RegRead,panelX,HKCU,Software\wandersick\AeroZoom,panelX
if errorlevel
{
	panelX=15 ; default offset value if unset
}
RegRead,panelY,HKCU,Software\wandersick\AeroZoom,panelY
if errorlevel
{
	panelY=160
}
RegRead,panelTrans,HKCU,Software\wandersick\AeroZoom,panelTrans
if errorlevel
{
	panelTrans=255
}
RegRead,stillZoomDelay,HKCU,Software\wandersick\AeroZoom,stillZoomDelay
if errorlevel
	stillZoomDelay=850
;Unnecessary
;RegRead,stillZoomDelayPrev,HKCU,Software\wandersick\AeroZoom,stillZoomDelay
;if errorlevel
;	stillZoomDelayPrev=800 ; Prev is for Advanced Options
	

RegRead,delayButton,HKCU,Software\wandersick\AeroZoom,delayButton
if errorlevel
	delayButton=100
;RegRead,delayButtonPrev,HKCU,Software\wandersick\AeroZoom,delayButton
;if errorlevel
;	delayButtonPrev=100 ; Prev is for Advanced Options
	
RegRead,customEdCheckbox,HKCU,Software\wandersick\AeroZoom,customEdCheckbox
RegRead,customEdPath,HKCU,Software\wandersick\AeroZoom,customEdPath

RegRead,customCalcCheckbox,HKCU,Software\wandersick\AeroZoom,customCalcCheckbox
RegRead,customCalcPath,HKCU,Software\wandersick\AeroZoom,customCalcPath



; this and tips must be placed after script init, before hotkey monitoring

; run magnifier minimized/hidden at start, unlike in v1 which was at zoom in
; advantages:  Magnifier does not show anymore on first zoom, and no more Ease
;              Of Access Center pop-ups thanks to this design.

RegRead,RunMagOnStart,HKCU,Software\wandersick\AeroZoom,RunMagOnStart
If errorlevel ; if first-run
{
	if (OSver<6.1 OR EditionID="Starter" OR EditionID="HomeBasic") { ; Old magnifier only supports docked view which is undesirable to launch with it at start / Home Basic or Starter of Win 7 only can use docked view due to lack of Aero
		RunMagOnStart=0
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RunMagOnStart, %RunMagOnStart%
	} else {
		RunMagOnStart=1
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RunMagOnStart, %RunMagOnStart%
	}
}

; Ensure setting imported works across Windows versions
if (OSver<6.1 OR EditionID="Starter" OR EditionID="HomeBasic") {
	RunMagOnStart=0
}

if (RunMagOnStart=1) {
	Process, Exist, magnify.exe
	if not errorlevel
	{
		Run,"%windir%\system32\magnify.exe",,Min ; Min does not work for magnify.exe, hence the below
		If (OSver>6) {
			if not (hideOrMin=3) ; if hideOrMin=3, dont hide or minimize
			{	
				WinWait, ahk_class MagUIClass,,5 ; Loop to hide Windows Magnifier
				if not ErrorLevel
				{
					if (hideOrMin=1) {
						WinMinimize, ahk_class MagUIClass ; minimize before hiding to remove the floating magnifier glass
						if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
							WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
					} else if (hideOrMin=2) {					
						WinMinimize, ahk_class MagUIClass
					}
				}
			}
		}
	}
}

SetBatchLines, 10ms

RegRead,reload,HKCU,Software\wandersick\AeroZoom,reload
if not errorlevel
{
	reload=
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload
	goto, skipTips
}

; First run welcome msg
; RegRead,Welcome,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,Welcome
if not Welcome
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Welcome, 1 ; do not set welcome=1 as the 'zoomit EULA message' check for first-run with this var not defined
	If not profileInUse
	{
		Msgbox, 262148, AeroZoom %verAZ% - Welcome!, Recent features:`n`n1) - Windows 10 Support - zoom operations are improved for Windows 10 and older versions. `n`n2) - AeroSnip - enhanced operations for Snipping Tool and Print Screen, more hotkeys, save-to-disk and custom editor.`n`n3) - Elastic Zoom - automatically zoom in and out by holding and releasing [Ctrl]+[Caps Lock].`n`n4) - ZoomIt Panel - improved mouse operation of Sysinternals ZoomIt with an easy-to-use interface, wheel zoom, elastic zoom and more.`n`n5) - Custom Hotkeys - hotkeys can now be customized for most AeroZoom actions.`n`nTo learn about more features, visit 'AeroZoom Web' via '?' menu.`n`nWould you like tips to get started?
		IfMsgBox, No
		{
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, TipDisabled, 1 ; disabled bit is used so when enabled will continue where users left off
		}
		Else
		{
			RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, TipDisabled
		}
		;goto, skipTips
	}
}

Tips:
; Tips are not available if Quick Profiles are used
If profileInUse
	goto, skipTips
RegRead,TipDisabled,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,TipDisabled
if not TipDisabled
{
	RegRead,Tip,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,Tip
	if errorlevel
	{
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Tip, 1
		Tip := 1
	}
	if (Tip>=1) {
		FileReadLine, line, %A_WorkingDir%\Data\Tips_and_Tricks.txt, %tip%
		if errorlevel ; if the end is reached
		{
			RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Tip ; read tip from beginning of file again
			goto Tips
		}
		Msgbox, 262468, AeroZoom %verAZ% Tips and Tricks #%tip%, %line%`n`n--`nRead next tip? (Tips can be disabled in '?' menu)
		Tip += 1
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Tip, %Tip%
		;IfMsgBox, Cancel
		;{
		;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, TipDisabled, 1
		;}
		IfMsgBox, Yes
		{
			RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, TipDisabled
			goto, Tips
		}
	}
}

skipTips:

RegRead,GuideDisabled,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,GuideDisabled
; disable guides if Quick Profiles are in use
If profileInUse
	GuideDisabled = 1

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
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
	return
}
return

;; elastic zoom

^CapsLock::
If not ElasticZoom
	return
if (OSver=6.0 AND !zoomitStill) OR (OSver>=6.1 AND zoomitLive=1) { ; elastic zoom with zoomit live zoom
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	IfWinExist, ahk_class MagnifierClass ; ZoomIt Live Zoom
	{
		sendinput ^{Up} ; zoom deeper if already in live zoom
	} else {
		sendinput ^4
	}
		KeyWait Ctrl
		sendinput ^4
} else if (OSver<6 OR zoomitStill) { ; elastic zoom with zoomit still zoom
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	IfWinExist, ahk_class ZoomitClass ; ZoomIt Still Zoom
	{
		sendinput {esc} ; exit if already in zoom
	} else {
		;process, close, zoompad.exe ; although this shouldnt be needed here
		process, close, osd.exe ; prevent osd from showing in 'picture'
		WinHide, AeroZoom Panel
		sendinput ^1
		WinWait, ahk_class ZoomitClass,,5
		gosub, ZoomItColor
		KeyWait Ctrl
		sendinput {esc}
		WinShow, AeroZoom Panel
	}
} else if (OSver>6) {
	if numPadAddBit
		SendInput #{NumpadAdd} ; elastic zoom with win 7 magnifier
	else
		SendInput #{+}
	KeyWait Ctrl
	if numPadSubBit
		SendInput #{NumpadSub}
	else
		SendInput #{-}
}
return

+CapsLock::
; elastic zoom with zoomit still zoom
If not ElasticZoom
	return
Process, Exist, zoomit.exe
If not errorlevel
{
	Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
	return
}
IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
	goto, zoomit
IfWinExist, ahk_class ZoomitClass ; ZoomIt Still Zoom
{
	sendinput {esc} ; exit if already in zoom
} else {
	;process, close, zoompad.exe ; although this shouldnt be needed here
	process, close, osd.exe ; prevent osd from showing in 'picture'
	WinHide, AeroZoom Panel
	sendinput ^1
	WinWait, ahk_class ZoomitClass,,5
	gosub, ZoomItColor
	KeyWait Shift
	sendinput {esc}
	WinShow, AeroZoom Panel
}
return

; Make color slider function work for ZoomIt hotkeys

~^1::
~^2::
~^3::
;process, close, zoompad.exe ; although this shouldnt be needed here <--- must not use process close here or it wont work at all
;process, close, osd.exe ; prevent osd from showing in 'picture' <---
WinHide, AeroZoom Panel
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

~^4::
goto, WorkaroundFullScrLiveZoom
return

; Update panel's magnify Slider while using keyboard to zoom

; ~#+:: <<-- since there is no way to specify this in AHK
~#NumpadAdd::
~LWin & ~+::
~RWin & ~+::
;process, close, zoompad.exe ; although this shouldnt be needed here
process, close, osd.exe ; prevent osd from showing
if (OSver=6) { ; use zoomit live zoom for vista
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	; Gosub, ZoomPad
	IfWinExist, ahk_class MagnifierClass ; ZoomIt Live Zoom
	{
		sendinput ^{Up}
	} else {
		sendinput ^4
		gosub, WorkaroundFullScrLiveZoom
	}
} else if (OSver<6) { ; use zoomit still zoom for xp
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	IfWinExist, ahk_class ZoomitClass
	{
		sendinput {Up}
	} Else {
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		WinHide, AeroZoom Panel
		sendinput ^1
		WinWait, ahk_class ZoomitClass,,5
		WinWaitClose, ahk_class ZoomitClass
		WinShow, AeroZoom Panel
	}
} else {
	If (SwitchSlider=2) ; update slider on gui (win7)
	{
		; originally the title was 'AeroZoom' and this was called: IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom
		; but it doesn't work at times (e.g. under standard user account)
		; then I found out I could use
		; IfWinExist, ahk_class AutoHotkeyGUI
		;     IfWinExist, AeroZoom
		; as a workaround
		; but it doesnt work for functions like winset (impossible to nest 2 winset's)
		; so in the end I simply renamed the title to 'AeroZoom Panel'
		IfWinExist, AeroZoom Panel
			Gosub, ReadValueUpdatePanel ; this will update the slider on the panel in real-time
	}
}
return

~#NumpadSub::
~#-::
if (OSver=6) { ; use zoomit live zoom for vista
	; Gosub, ZoomPad
	IfWinExist, ahk_class MagnifierClass ; ZoomIt Live Zoom
	{
		sendinput ^{Down}
	}
} else if (OSver<6) { ; use zoomit still zoom for xp
	IfWinExist, ahk_class ZoomitClass
		sendinput {Down}
} else {
	If (SwitchSlider=2) ; update slider on gui (win7)
	{
		IfWinExist, AeroZoom Panel
			Gosub, ReadValueUpdatePanel ; this will update the slider on the panel in real-time
	}
}
return

; Enhance print screen when NirCmd (Save Captures) is on
~PrintScreen::
If (!PrintScreenEnhanceCheckbox)
	return
Sleep, %delayButton%
If NirCmd
{
	IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
		Run, "%A_WorkingDir%\Data\NirCmd.exe" clipboard saveimage "%SnipSaveDir%\Snip%A_YYYY%%A_MM%%A_DD%%A_Hour%%A_Min%%A_Sec%.%SnipSaveFormat%", ,min
	Else
		goto, NirCmdDownloadAlt
}
If (SnipRunCommandCheckbox AND SnipRunCommand)
{
	Process, WaitClose, NirCmd.exe, 5 ; ensure capture is complete before running a command
	Run, %SnipRunCommand%,,,SnipCommandPID
	If SnipPasteCheckbox
	{
		WinWait, ahk_pid %SnipCommandPID%,,10
		WinActivate
		sendinput ^v
	}
}
return

~!PrintScreen::
If (!PrintScreenEnhanceCheckbox OR !NirCmd)
	return
Sleep, %delayButton%
If NirCmd
{
	IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
		Run, "%A_WorkingDir%\Data\NirCmd.exe" clipboard saveimage "%SnipSaveDir%\Snip%A_YYYY%%A_MM%%A_DD%%A_Hour%%A_Min%%A_Sec%.%SnipSaveFormat%", ,min
	Else
		goto, NirCmdDownloadAlt
}
If (SnipRunCommandCheckbox AND SnipRunCommand)
{
	Process, WaitClose, NirCmd.exe, 5 ; ensure capture is complete before running a command
	Run, %SnipRunCommand%,,,SnipCommandPID
	If SnipPasteCheckbox
	{
		WinWait, ahk_pid %SnipCommandPID%,,10
		WinActivate
		sendinput ^v
	}
}
return

; Alternative keyboard shortcuts

; ZoomIncrement
#!F1::
if (OSver>6) {
	zoomInc=1
	; update/refresh GUI with new slider setting
	GuiControl,, ZoomInc, 1
	goto, SliderX
}
return

#!F2::
if (OSver>6) {
	zoomInc=2
	GuiControl,, ZoomInc, 2
	goto, SliderX
}
return

#!F3::
if (OSver>6) {
	zoomInc=3
	GuiControl,, ZoomInc, 3
	goto, SliderX
}
return

#!F4::
if (OSver>6) {
	zoomInc=4
	GuiControl,, ZoomInc, 4
	goto, SliderX
}
return

#!F5::
if (OSver>6) {
	zoomInc=5
	GuiControl,, ZoomInc, 5
	goto, SliderX
}
return

#!F6::
if (OSver>6) {
	zoomInc=6
	GuiControl,, ZoomInc, 6
	goto, SliderX
}
return

; Color
#!I::
if (OSver>6) {
	goto, ColorHK
}
return

; Mouse
#!M::
if (OSver>6) {
	goto, MouseHK
}
return

; Keyboard
#!K::
if (OSver>6) {
	goto, KeyboardHK
}
return

; Text
#!T::
if (OSver>6) {
	goto, TextHK
}
return

; the following updates the viewsmenu on calling these hotkeys before executing them (~)
; View Full Screen
~^!F::
If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
	IfWinExist, AeroZoom Panel
	{
		Menu, ViewsMenu, Check, &Full Screen`tCtrl+Alt+F
		Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
		Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
	}
}
return

; View Lens
~^!L::
If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
	IfWinExist, AeroZoom Panel
	{
		Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
		Menu, ViewsMenu, Check, &Lens`tCtrl+Alt+L
		Menu, ViewsMenu, Uncheck, &Docked`tCtrl+Alt+D
	}
}
return

; View Docked
~^!D::
If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
	IfWinExist, AeroZoom Panel
	{
		Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
		Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
		Menu, ViewsMenu, Check, &Docked`tCtrl+Alt+D
	}
}
return

; ----------------------------------------------------- Left Button Assignment START

+WheelUp::
if paused
	return
IfWinExist, ahk_class MagnifierClass  ; if zoomit is working, enhance it instead
{
	sendinput ^{Up}
	return
}
IfWinExist, ahk_class ZoomitClass
{
	sendinput {Up}
	return
}
if (OSver=6.0 AND !zoomitStill) OR (OSver>=6.1 AND zoomitLive=1) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	; Gosub, ZoomPad ; causes huge delay in W7HB. also I found out later there is no need for Zoompad while using Live Zoom or Still Zoom of ZoomIt
	IfWinExist, ahk_class MagnifierClass  ; ZoomIt Live Zoom for vista and win7 home basic/starter
	{
		sendinput ^{Up}
	} else {
		sendinput ^4
		gosub, WorkaroundFullScrLiveZoom
	}
} else if (OSver<6 OR zoomitStill) {  ; still zoom for xp
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	IfWinExist, ahk_class ZoomitClass
	{
		sendinput {Up}
	} Else {
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
		Process, Close, ZoomPad.exe ; prevent zoompad frame from appearing in zoomit
		process, close, osd.exe ; prevent osd from showing in 'picture'
		sendinput ^1 ; here, do not send aerozoom panel to bottom and reactivate it later like others
	}
} else {
	; send {LWin down}{NumpadAdd}{LWin up}
	; the following is used instead instead of 'send' for better performance
	Gosub, ZoomPad
	
	; Mouse-Centered Zoom (center the cursor before zoom)
	if (OSver>=6.1) {
		;RegRead,mouseCenteredZoomBit,HKCU,Software\wandersick\AeroZoom,mouseCenteredZoomBit
		if mouseCenteredZoomBit
			Gosub, MouseCenteredZoom
	}
	
	if numPadAddBit
		sendinput #{NumpadAdd}
	else
		SendInput #{+}
	IfWinExist, AeroZoom Panel
	{
		Gosub, ReadValueUpdatePanel
	}
}
return

+WheelDown::
if paused
	return
IfWinExist, ahk_class MagnifierClass ; if zoomit is working, enhance it instead
{
	If (OSver>=6.1 AND (EditionID="Starter" OR EditionID="HomeBasic")) {
		sendinput ^4 ; {Down} causes cursor to disappear in those OSes, so just quit. Live Zoom magnificartion level cant be tuned there anyway.
		return
	} else {
		sendinput ^{Down}
		return
	}
}
IfWinExist, ahk_class ZoomitClass
{
	sendinput {Down}
	return
}
if (OSver=6.0 AND !zoomitStill) OR (OSver>=6.1 AND zoomitLive=1) {
	Gosub, ZoomPad
	IfWinExist, ahk_class MagnifierClass ; ZoomIt Live Zoom for vista and win7 home basic/starter
	{
		sendinput ^{Down}
	}
} else if (OSver<6 OR zoomitStill) { ; still zoom for xp
	IfWinExist, ahk_class ZoomitClass
	{
		sendinput {Down}
	}
} else {
	; only enable zoompad when modifier is a mouse button
	if (chkMod>4)
	{	
		if zoomPad ; if zoompad is NOT disabled
		{
			IfWinNotActive, AeroZoom Panel ;if current win is not the panel (zooming over the panel does not require zoompad)
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
	
	if numPadSubBit
		sendinput #{NumpadSub}
	else
		SendInput #{-}
	IfWinExist, AeroZoom Panel
	{
		Gosub, ReadValueUpdatePanel
	}
}
return

; Run,"%windir%\system32\reg.exe" add HKCU\Software\Microsoft\ScreenMagnifier /v Magnification /t REG_DWORD /d 0x64 /f,,Min

; Help
#!q::
goto, Instruction
return

; New snip

#!s::
Goto, SnipScreen
return

#!w::
Goto, SnipWin
return

#!r::
Goto, SnipRect
return

#!f::
Goto, SnipFree
return

; Pause hotkeys

#!h::
goto, PauseScriptViaHotkey
return

; Suspend hotkeys (disabled as no way to turn it back on after turning it off)
;#!+h::
;goto, SuspendScript
;return

; Kill magnifier
#+k::
GoSub, CloseMagnifier
return

; Reset magnifier
#+r::
; dontHideMag = 1 ; dont hide magnifier window for keyboard shortcuts
goto, default

; Restart AeroZoom (this is a secret feature)
; #!+r::
; goto, RestartAZ

; Reset all settings (this is a secret feature)
; #!+^r::
; CheckboxRestoreDefault=1
; goto, 3ButtonOK

; Quit AeroZoom (this is a secret feature)
; #!+q::
; goto, ExitAZ


; Reset zoom
#+-::
; dontHideMag = 1 ; dont hide magnifier window for keyboard shortcuts
goto, resetZoom

#+NumpadSub::
; dontHideMag = 1
goto, resetZoom

+MButton::
if paused
	return
if disableZoomResetHotkey
	return
IfWinExist, ahk_class MagnifierClass ; if zoomit is working, enhance (stop) it instead
{
	Gosub, ZoomPad
	sendinput ^4 ; Side-note: WinActivates unzooms Live Zoom too
	return
}
IfWinExist, ahk_class ZoomitClass
{
	; Gosub, ZoomPad ; no need to use zoompad if under zoomit still zoom mode
	sendinput ^1
	return
}
if (OSver>=6.1) {
	; dontHideMag = 0
	Gosub, ZoomPad
	goto, resetZoom
}

return

;; for Middle mode only:
;~MButton & ~RButton::
;if paused
;	return
;if disableZoomResetHotkey
;	return
;IfWinExist, ahk_class MagnifierClass ; if zoomit is working, enhance (stop) it instead
;{
;	sendinput ^4 ; Side-note: WinActivates unzooms Live Zoom too
;	return
;}
;IfWinExist, ahk_class ZoomitClass
;{
;	sendinput ^1
;	return
;}
;if (OSver>=6.1) {
;	goto, resetZoom
;}

;return

resetZoom:
IfWinExist, ahk_class MagnifierClass ; if zoomit is working, enhance (stop) it instead
{
	sendinput ^4
	return
}
IfWinExist, ahk_class ZoomitClass
{
	sendinput {esc}
	return
}
MagExists=
Process, Exist, magnify.exe
If errorlevel
{
	MagExists=1 ; only run magnifier later if exists
	Gosub, MagWinBeforeRestore
}
GoSub, CloseMagnifier
GuiControl,, Magnification, 1
If (OSver>=6.1)
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
sleep, %delayButton%
If MagExists
	Run,"%windir%\system32\magnify.exe",,Min
MagExists=
Gosub, MagWinRestore
return

~MButton:: ; in MButton ahk, this is changed to ~MButton & ~LButton::
if not holdMiddle ; in MButton ahk, this is removed
	return ; in MButton ahk, this is removed
if not paused {
	MouseGetPos, oldX, oldY, ; in MButton ahk, this is removed
	sleep %stillZoomDelay% ; in MButton ahk, this is removed
	if GetKeyState("MButton") ; in MButton ahk, this is removed
	{
		MouseGetPos, newX, newY,  ; in MButton ahk, this is removed
		if Abs(newX - oldX) > 100 || Abs(newY - oldY) > 100  ; in MButton ahk, this is removed
			return  ; in MButton ahk, this is removed
		RegRead,MButtonMsg,HKCU,Software\wandersick\AeroZoom,MButtonMsg
		if errorlevel
		{
			If not profileInUse
				Msgbox,262208,This message will only be shown once,You've just triggered the Middle button for the first time!`n`nHolding Middle button for a specified time ('0.7s' by default) can launch a specified task. And if the screen is magnified, the same button will trigger a Full Screen Preview instead (for Windows 7 or above only).`n`nTo customize the action, go to 'Tool > Custom Hotkeys > Settings > Holding Middle'.`n`nTo enable/disable this function quickly in order to avoid mis-triggering, go to 'Tool > Custom Hotkeys > Enable Holding Middle'.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, MButtonMsg, 1
		}	
		Process, Exist, ZoomIt.exe
		If (errorlevel AND !DisableZoomItMiddle)
		{
			RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
			If not disablePreviewFullScreen {
				if (MagnificationRaw<>0x64) ; if magnificationRaw is NOT 100 (0x64, i.e. zoomed out), then preview full screen
					goto, ViewPreview
			}
			if not zoomItGuidance
				Gosub, ZoomItGuidance
			;process, close, zoompad.exe ; although this shouldn't be required here
			process, close, osd.exe ; prevent osd from showing in 'picture'
			WinHide, AeroZoom Panel
			sendinput ^1
			WinWait, ahk_class ZoomitClass,,5
			WinWaitClose, ahk_class ZoomitClass
			WinShow, AeroZoom Panel
		} else {
			RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
			If not disablePreviewFullScreen {
				if (MagnificationRaw<>0x64) ; if magnificationRaw is NOT 100 (0x64, i.e. zoomed out), then preview full screen
					goto, ViewPreview
			}
			if (MiddleButtonAction=1) {
				Gosub, SnippingTool
			} else if (MiddleButtonAction=2) {
				GoSub, KillMagnifierHK
			} else if (MiddleButtonAction=3) {
				Gosub, ColorHK
			} else if (MiddleButtonAction=4) {
				Gosub, MouseHK
			} else if (MiddleButtonAction=5) {
				Gosub, KeyboardHK
			} else if (MiddleButtonAction=6) {
				Gosub, TextHK
			} else if (MiddleButtonAction=7) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewType
			} else if (MiddleButtonAction=8) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewLiveZoom
			} else if (MiddleButtonAction=9) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewStillZoom
			} else if (MiddleButtonAction=10) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewDraw
			} else if (MiddleButtonAction=11) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewBreakTimer
			} else if (MiddleButtonAction=12) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewBlackBoard
			} else if (MiddleButtonAction=13) {
				Process, Exist, zoomit.exe
				If not errorlevel
				{
					Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
					return
				}
				IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
					goto, zoomit
				if not zoomItGuidance
					Gosub, ZoomItGuidance
				goto, ViewWhiteBoard
			} else if (MiddleButtonAction=14) {
				goto, notepad
			} else if (MiddleButtonAction=15) {
				goto, wordpad
			} else if (MiddleButtonAction=16) {
				goto, mscalc
			} else if (MiddleButtonAction=17) {
				gosub, mspaint
			} else if (MiddleButtonAction=18) {
				goto, Google
			} else if (MiddleButtonAction=19) {
				goto, GoogleHighlight
			} else if (MiddleButtonAction=20) {
				goto, GoogleClipboard
			} else if (MiddleButtonAction=21) {
				goto, SpeakIt
			} else if (MiddleButtonAction=22) {
				goto, SpeakHighlight
			} else if (MiddleButtonAction=23) {
				goto, SpeakClipboard
			} else if (MiddleButtonAction=24) {
				goto, MonitorOff
			} else if (MiddleButtonAction=25) {
				goto, OpenTray
			} else if (MiddleButtonAction=26) {
				goto, AlwaysOnTop
			} else if (MiddleButtonAction=27) {
				goto, WebTimer
			} else if (MiddleButtonAction=28) {
				goto, TimerTab
			} else if (MiddleButtonAction=29) {
				goto, ZoomFaster
			} else if (MiddleButtonAction=30) {
				goto, ZoomSlower
			} else if (MiddleButtonAction=31) {
				hotkeyMod=MButton
				goto, ElasticZoom
			} else if (MiddleButtonAction=32) {				
				hotkeyMod=MButton
				goto, ElasticStillZoom
			} else if (MiddleButtonAction=33) {				
				goto, SnipFree
			} else if (MiddleButtonAction=34) {				
				goto, SnipRect
			} else if (MiddleButtonAction=35) {				
				goto, SnipWin
			} else if (MiddleButtonAction=36) {				
				goto, SnipScreen
			} else if (MiddleButtonAction=37) {				
				Gosub, ShowMagnifierHK ; show hide magnifier
			} else if (MiddleButtonAction=38) {				
				goto, showHidePanel
			} else if (MiddleButtonAction=39) {				
				goto, resetZoom
			} else if (MiddleButtonAction=40) {				
				goto, Default
			} else if (MiddleButtonAction=41) {
				Run, %CustomMiddlePath% ; all of these SHOULD NOT BE double-quoted in order to allow users to run commands such as: cmd /k dir (if quotes, it would be "cmd /k /dir" which is wrong.
			} else {
				return ; this is unneeded
			}
		}
	}
}
return

; --
; Custom Hotkey (Part 2) Start
; --

;; -------- X1 and X2 START

~XButton2 & ~LButton::
if not ForwardBack
	return
if (BackLeftAction=37) { ; 37 = None for X1/X2
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (BackLeftAction<>34 AND BackLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (BackLeftAction=1) { 
		Gosub, SnippingTool
	} else if (BackLeftAction=2) { 
		GoSub, KillMagnifierHK
	} else if (BackLeftAction=3) { 
		Gosub, ColorHK
	} else if (BackLeftAction=4) { 
		Gosub, MouseHK
	} else if (BackLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (BackLeftAction=6) { 
		Gosub, TextHK
	} else if (BackLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (BackLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (BackLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (BackLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (BackLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (BackLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (BackLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (BackLeftAction=14) { 
		goto, notepad
	} else if (BackLeftAction=15) { 
		goto, wordpad
	} else if (BackLeftAction=16) { 
		goto, mscalc
	} else if (BackLeftAction=17) { 
		gosub, mspaint
	} else if (BackLeftAction=18) { 
		goto, GoogleClipboard
	} else if (BackLeftAction=19) { 
		goto, SpeakClipboard
	} else if (BackLeftAction=20) { 
		goto, MonitorOff
	} else if (BackLeftAction=21) { 
		goto, OpenTray
	} else if (BackLeftAction=22) { 
		goto, AlwaysOnTop
	} else if (BackLeftAction=23) { 
		goto, WebTimer
	} else if (BackLeftAction=24) { 
		goto, TimerTab
	} else if (BackLeftAction=25) { 
		goto, ZoomFaster
	} else if (BackLeftAction=26) { 
		goto, ZoomSlower
	} else if (BackLeftAction=27) {
		hotkeyMod=XButton2
		goto, ElasticZoom
	} else if (BackLeftAction=28) {	
		hotkeyMod=XButton2
		goto, ElasticStillZoom
	} else if (BackLeftAction=29) {				
		goto, SnipFree
	} else if (BackLeftAction=30) {				
		goto, SnipRect
	} else if (BackLeftAction=31) {				
		goto, SnipWin
	} else if (BackLeftAction=32) {				
		goto, SnipScreen
	} else if (BackLeftAction=33) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (BackLeftAction=34) {				
		goto, showHidePanel
	} else if (BackLeftAction=35) { 
		sendinput ^!{Space}
	} else if (BackLeftAction=36) { 
		Run, %CustomBackLeftPath% ; CustomForwardLeftPath
	} else {
		return ; this is unneeded
	}
}
return


~XButton2 & ~RButton::
if not ForwardBack
	return
if (BackRightAction=37) { ; 37 = None for X1/X2
	return
}
if paused
	return
if (BackRightAction<>34 AND BackRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (BackRightAction=1) { 
	Gosub, SnippingTool
} else if (BackRightAction=2) { 
	GoSub, KillMagnifierHK
} else if (BackRightAction=3) { 
	Gosub, ColorHK
} else if (BackRightAction=4) { 
	Gosub, MouseHK
} else if (BackRightAction=5) { 
	Gosub, KeyboardHK
} else if (BackRightAction=6) { 
	Gosub, TextHK
} else if (BackRightAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (BackRightAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (BackRightAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (BackRightAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (BackRightAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (BackRightAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (BackRightAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (BackRightAction=14) { 
	goto, notepad
} else if (BackRightAction=15) { 
	goto, wordpad
} else if (BackRightAction=16) { 
	goto, mscalc
} else if (BackRightAction=17) { 
	gosub, mspaint
} else if (BackRightAction=18) { 
	goto, GoogleClipboard
} else if (BackRightAction=19) { 
	goto, SpeakClipboard
} else if (BackRightAction=20) { 
	goto, MonitorOff
} else if (BackRightAction=21) { 
	goto, OpenTray
} else if (BackRightAction=22) { 
	goto, AlwaysOnTop
} else if (BackRightAction=23) { 
	goto, WebTimer
} else if (BackRightAction=24) { 
	goto, TimerTab
} else if (BackRightAction=25) { 
	goto, ZoomFaster
} else if (BackRightAction=26) { 
	goto, ZoomSlower
} else if (BackRightAction=27) {
	hotkeyMod=XButton2
	goto, ElasticZoom
} else if (BackRightAction=28) {				
	hotkeyMod=XButton2
	goto, ElasticStillZoom
} else if (BackRightAction=29) {				
	goto, SnipFree
} else if (BackRightAction=30) {				
	goto, SnipRect
} else if (BackRightAction=31) {				
	goto, SnipWin
} else if (BackRightAction=32) {				
	goto, SnipScreen
} else if (BackRightAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (BackRightAction=34) {				
	goto, showHidePanel
} else if (BackRightAction=35) { 
	sendinput ^!{Space}
} else if (BackRightAction=36) {
	Run, %CustomBackRightPath% ; CustomForwardRightPath
} else {
	return ; this is unneeded
}
return

~XButton1 & ~LButton::
if not ForwardBack
	return
if (ForwardLeftAction=37) { ; 37 = None for X1/X2
	return
}
if not paused {
	if (ForwardLeftAction<>34 AND ForwardLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (ForwardLeftAction=1) { 
		Gosub, SnippingTool
	} else if (ForwardLeftAction=2) {
		GoSub, KillMagnifierHK
	} else if (ForwardLeftAction=3) { 
		Gosub, ColorHK
	} else if (ForwardLeftAction=4) { 
		Gosub, MouseHK
	} else if (ForwardLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (ForwardLeftAction=6) { 
		Gosub, TextHK
	} else if (ForwardLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (ForwardLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (ForwardLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (ForwardLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (ForwardLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (ForwardLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (ForwardLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (ForwardLeftAction=14) { 
		goto, notepad
	} else if (ForwardLeftAction=15) { 
		goto, wordpad
	} else if (ForwardLeftAction=16) { 
		goto, mscalc
	} else if (ForwardLeftAction=17) { 
		gosub, mspaint
	} else if (ForwardLeftAction=18) { 
		goto, GoogleClipboard
	} else if (ForwardLeftAction=19) { 
		goto, SpeakClipboard
	} else if (ForwardLeftAction=20) { 
		goto, MonitorOff
	} else if (ForwardLeftAction=21) { 
		goto, OpenTray
	} else if (ForwardLeftAction=22) { 
		goto, AlwaysOnTop
	} else if (ForwardLeftAction=23) { 
		goto, WebTimer
	} else if (ForwardLeftAction=24) { 
		goto, TimerTab
	} else if (ForwardLeftAction=25) { 
		goto, ZoomFaster
	} else if (ForwardLeftAction=26) { 
		goto, ZoomSlower	
	} else if (ForwardLeftAction=27) {
		hotkeyMod=XButton1
		goto, ElasticZoom
	} else if (ForwardLeftAction=28) {				
		hotkeyMod=XButton1
		goto, ElasticStillZoom
	} else if (ForwardLeftAction=29) {				
		goto, SnipFree
	} else if (ForwardLeftAction=30) {				
		goto, SnipRect
	} else if (ForwardLeftAction=31) {				
		goto, SnipWin
	} else if (ForwardLeftAction=32) {				
		goto, SnipScreen
	} else if (ForwardLeftAction=33) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (ForwardLeftAction=34) {				
		goto, showHidePanel
	} else if (ForwardLeftAction=35) { 
		sendinput ^!{Space}
	} else if (ForwardLeftAction=36) { 
		Run, %CustomForwardLeftPath% ; CustomBackLeftPath
	} else {
		return ; this is unneeded
	}
}
return

;;~XButton1 & ~MButton:: ; this resets the zoom increment only
;if paused
;	return
;
;Gosub, ZoomPad
;
;; check if a last magnifier window is available and record its status
;; so that after it restores it will remain hidden/minimized/normal
;
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
;GoSub, KillMagnifierHK
;GuiControl,, ZoomInc, 3
;RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
;sleep, %delayButton%
;Run,"%windir%\system32\magnify.exe",,Min
;
;If (OSver>6) {
;	WinWait, ahk_class MagUIClass,,3 
;}
;
;; Hide or minimize or normalize magnifier window
;If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
;	if (hideOrMin=1) {
;		WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
;		if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
;			WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
;	} else if (hideOrMin=2) {
;		WinMinimize, ahk_class MagUIClass
;	}
;} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
;	WinMinimize, ahk_class MagUIClass
;	if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
;		WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
;} else if (hideOrMinLast=2) {
;	WinMinimize, ahk_class MagUIClass
;}
;return

~XButton1 & ~RButton:: ; show magnifier
if not ForwardBack
	return
if (ForwardRightAction=37) { ; 37 = None for X1/X2
	return
}
if paused
	return
if (ForwardRightAction<>34 AND ForwardRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (ForwardRightAction=1) { 
	Gosub, SnippingTool
} else if (ForwardRightAction=2) { 
	GoSub, KillMagnifierHK
} else if (ForwardRightAction=3) { 
	Gosub, ColorHK
} else if (ForwardRightAction=4) { 
	Gosub, MouseHK
} else if (ForwardRightAction=5) { 
	Gosub, KeyboardHK
} else if (ForwardRightAction=6) { 
	Gosub, TextHK
} else if (ForwardRightAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (ForwardRightAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (ForwardRightAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (ForwardRightAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (ForwardRightAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (ForwardRightAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (ForwardRightAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (ForwardRightAction=14) { 
	goto, notepad
} else if (ForwardRightAction=15) { 
	goto, wordpad
} else if (ForwardRightAction=16) { 
	goto, mscalc
} else if (ForwardRightAction=17) { 
	gosub, mspaint
} else if (ForwardRightAction=18) { 
	goto, GoogleClipboard
} else if (ForwardRightAction=19) { 
	goto, SpeakClipboard
} else if (ForwardRightAction=20) { 
	goto, MonitorOff
} else if (ForwardRightAction=21) { 
	goto, OpenTray
} else if (ForwardRightAction=22) { 
	goto, AlwaysOnTop
} else if (ForwardRightAction=23) { 
	goto, WebTimer
} else if (ForwardRightAction=24) { 
	goto, TimerTab
} else if (ForwardRightAction=25) { 
	goto, ZoomFaster
} else if (ForwardRightAction=26) { 
	goto, ZoomSlower
} else if (ForwardRightAction=27) {
	hotkeyMod=XButton1
	goto, ElasticZoom
} else if (ForwardRightAction=28) {				
	hotkeyMod=XButton1
	goto, ElasticStillZoom
} else if (ForwardRightAction=29) {				
	goto, SnipFree
} else if (ForwardRightAction=30) {				
	goto, SnipRect
} else if (ForwardRightAction=31) {				
	goto, SnipWin
} else if (ForwardRightAction=32) {				
	goto, SnipScreen
} else if (ForwardRightAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (ForwardRightAction=34) {				
	goto, showHidePanel
} else if (ForwardRightAction=35) { 
	sendinput ^!{Space}
} else if (ForwardRightAction=36) { 
	Run, %CustomForwardRightPath% ; CustomBackRightPath
} else {
	return ; this is unneeded
}
return

~XButton2 & ~Wheelup::
if not ForwardBack
	return
if (BackWupAction=37) { ; 37 = None for X1/X2
	return
}
if paused
	return
if (BackWupAction<>34 AND BackWupAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (BackWupAction=1) { 
	Gosub, SnippingTool
} else if (BackWupAction=2) { 
	GoSub, KillMagnifierHK
} else if (BackWupAction=3) { 
	Gosub, ColorHK
} else if (BackWupAction=4) { 
	Gosub, MouseHK
} else if (BackWupAction=5) { 
	Gosub, KeyboardHK
} else if (BackWupAction=6) { 
	Gosub, TextHK
} else if (BackWupAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (BackWupAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (BackWupAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (BackWupAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (BackWupAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (BackWupAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (BackWupAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (BackWupAction=14) { 
	goto, notepad
} else if (BackWupAction=15) { 
	goto, wordpad
} else if (BackWupAction=16) { 
	goto, mscalc
} else if (BackWupAction=17) { 
	gosub, mspaint
} else if (BackWupAction=18) { 
	goto, GoogleClipboard
} else if (BackWupAction=19) { 
	goto, SpeakClipboard
} else if (BackWupAction=20) { 
	goto, MonitorOff
} else if (BackWupAction=21) { 
	goto, OpenTray
} else if (BackWupAction=22) { 
	goto, AlwaysOnTop
} else if (BackWupAction=23) { 
	goto, WebTimer
} else if (BackWupAction=24) { 
	goto, TimerTab
} else if (BackWupAction=25) { 
	goto, ZoomFaster
} else if (BackWupAction=26) { 
	goto, ZoomSlower
} else if (BackWupAction=27) {
	hotkeyMod=XButton2
	goto, ElasticZoom
} else if (BackWupAction=28) {				
	hotkeyMod=XButton2
	goto, ElasticStillZoom
} else if (BackWupAction=29) {				
	goto, SnipFree
} else if (BackWupAction=30) {				
	goto, SnipRect
} else if (BackWupAction=31) {				
	goto, SnipWin
} else if (BackWupAction=32) {				
	goto, SnipScreen
} else if (BackWupAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (BackWupAction=34) {				
	goto, showHidePanel	
} else if (BackWupAction=35) { 
	sendinput ^!{Space}
} else if (BackWupAction=36) { 
	Run, %CustomBackWupPath%
} else {
	return ; this is unneeded
}
return


~XButton2 & ~Wheeldown::
if not ForwardBack
	return
if (BackWdownAction=37) { ; 37 = None for X1/X2
	return
}
if paused
	return
if (BackWdownAction<>34 AND BackWdownAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (BackWdownAction=1) { 
	Gosub, SnippingTool
} else if (BackWdownAction=2) { 
	GoSub, KillMagnifierHK
} else if (BackWdownAction=3) { 
	Gosub, ColorHK
} else if (BackWdownAction=4) { 
	Gosub, MouseHK
} else if (BackWdownAction=5) { 
	Gosub, KeyboardHK
} else if (BackWdownAction=6) { 
	Gosub, TextHK
} else if (BackWdownAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (BackWdownAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (BackWdownAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (BackWdownAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (BackWdownAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (BackWdownAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (BackWdownAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (BackWdownAction=14) { 
	goto, notepad
} else if (BackWdownAction=15) { 
	goto, wordpad
} else if (BackWdownAction=16) { 
	goto, mscalc
} else if (BackWdownAction=17) { 
	gosub, mspaint
} else if (BackWdownAction=18) { 
	goto, GoogleClipboard
} else if (BackWdownAction=19) { 
	goto, SpeakClipboard
} else if (BackWdownAction=20) { 
	goto, MonitorOff
} else if (BackWdownAction=21) { 
	goto, OpenTray
} else if (BackWdownAction=22) { 
	goto, AlwaysOnTop
} else if (BackWdownAction=23) { 
	goto, WebTimer
} else if (BackWdownAction=24) { 
	goto, TimerTab
} else if (BackWdownAction=25) { 
	goto, ZoomFaster
} else if (BackWdownAction=26) { 
	goto, ZoomSlower
} else if (BackWdownAction=27) {
	hotkeyMod=XButton2
	goto, ElasticZoom
} else if (BackWdownAction=28) {				
	hotkeyMod=XButton2
	goto, ElasticStillZoom
} else if (BackWdownAction=29) {				
	goto, SnipFree
} else if (BackWdownAction=30) {				
	goto, SnipRect
} else if (BackWdownAction=31) {				
	goto, SnipWin
} else if (BackWdownAction=32) {				
	goto, SnipScreen
} else if (BackWdownAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (BackWdownAction=34) {				
	goto, showHidePanel
} else if (BackWdownAction=35) { 
	sendinput ^!{Space}
} else if (BackWdownAction=36) { 
	Run, %CustomBackWdownPath%
} else {
	return ; this is unneeded
}
return

~XButton1 & ~Wheelup::
if not ForwardBack
	return
if (ForwardWupAction=37) { ; 37 = None for X1/X2
	return
}
if paused
	return
if (ForwardWupAction<>34 AND ForwardWupAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (ForwardWupAction=1) { 
	Gosub, SnippingTool
} else if (ForwardWupAction=2) { 
	GoSub, KillMagnifierHK
} else if (ForwardWupAction=3) { 
	Gosub, ColorHK
} else if (ForwardWupAction=4) { 
	Gosub, MouseHK
} else if (ForwardWupAction=5) { 
	Gosub, KeyboardHK
} else if (ForwardWupAction=6) { 
	Gosub, TextHK
} else if (ForwardWupAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (ForwardWupAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (ForwardWupAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (ForwardWupAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (ForwardWupAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (ForwardWupAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (ForwardWupAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (ForwardWupAction=14) { 
	goto, notepad
} else if (ForwardWupAction=15) { 
	goto, wordpad
} else if (ForwardWupAction=16) { 
	goto, mscalc
} else if (ForwardWupAction=17) { 
	gosub, mspaint
} else if (ForwardWupAction=18) { 
	goto, GoogleClipboard
} else if (ForwardWupAction=19) { 
	goto, SpeakClipboard
} else if (ForwardWupAction=20) { 
	goto, MonitorOff
} else if (ForwardWupAction=21) { 
	goto, OpenTray
} else if (ForwardWupAction=22) { 
	goto, AlwaysOnTop
} else if (ForwardWupAction=23) { 
	goto, WebTimer
} else if (ForwardWupAction=24) { 
	goto, TimerTab
} else if (ForwardWupAction=25) { 
	goto, ZoomFaster
} else if (ForwardWupAction=26) { 
	goto, ZoomSlower
} else if (ForwardWupAction=27) {
	hotkeyMod=XButton1
	goto, ElasticZoom
} else if (ForwardWupAction=28) {				
	hotkeyMod=XButton1
	goto, ElasticStillZoom
} else if (ForwardWupAction=29) {				
	goto, SnipFree
} else if (ForwardWupAction=30) {				
	goto, SnipRect
} else if (ForwardWupAction=31) {				
	goto, SnipWin
} else if (ForwardWupAction=32) {				
	goto, SnipScreen
} else if (ForwardWupAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (ForwardWupAction=34) {				
	goto, showHidePanel
} else if (ForwardWupAction=35) { 
	sendinput ^!{Space}
} else if (ForwardWupAction=36) { 
	Run, %CustomForwardWupPath%
} else {
	return ; this is unneeded
}
return

~XButton1 & ~Wheeldown::
if not ForwardBack
	return
if (ForwardWdownAction=37) { ; 37 = None for X1/X2
	return
}
if paused
	return
if (ForwardWdownAction<>34 AND ForwardWdownAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (ForwardWdownAction=1) { 
	Gosub, SnippingTool
} else if (ForwardWdownAction=2) { 
	GoSub, KillMagnifierHK
} else if (ForwardWdownAction=3) { 
	Gosub, ColorHK
} else if (ForwardWdownAction=4) { 
	Gosub, MouseHK
} else if (ForwardWdownAction=5) { 
	Gosub, KeyboardHK
} else if (ForwardWdownAction=6) { 
	Gosub, TextHK
} else if (ForwardWdownAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (ForwardWdownAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (ForwardWdownAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (ForwardWdownAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (ForwardWdownAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (ForwardWdownAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (ForwardWdownAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (ForwardWdownAction=14) { 
	goto, notepad
} else if (ForwardWdownAction=15) { 
	goto, wordpad
} else if (ForwardWdownAction=16) { 
	goto, mscalc
} else if (ForwardWdownAction=17) { 
	gosub, mspaint
} else if (ForwardWdownAction=18) { 
	goto, GoogleClipboard
} else if (ForwardWdownAction=19) { 
	goto, SpeakClipboard
} else if (ForwardWdownAction=20) { 
	goto, MonitorOff
} else if (ForwardWdownAction=21) { 
	goto, OpenTray
} else if (ForwardWdownAction=22) { 
	goto, AlwaysOnTop
} else if (ForwardWdownAction=23) { 
	goto, WebTimer
} else if (ForwardWdownAction=24) { 
	goto, TimerTab
} else if (ForwardWdownAction=25) { 
	goto, ZoomFaster
} else if (ForwardWdownAction=26) { 
	goto, ZoomSlower
} else if (ForwardWdownAction=27) {
	hotkeyMod=XButton1
	goto, ElasticZoom
} else if (ForwardWdownAction=28) {				
	hotkeyMod=XButton1
	goto, ElasticStillZoom
} else if (ForwardWdownAction=29) {				
	goto, SnipFree
} else if (ForwardWdownAction=30) {				
	goto, SnipRect
} else if (ForwardWdownAction=31) {				
	goto, SnipWin
} else if (ForwardWdownAction=32) {				
	goto, SnipScreen
} else if (ForwardWdownAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (ForwardWdownAction=34) {				
	goto, showHidePanel
} else if (ForwardWdownAction=35) { 
	sendinput ^!{Space}
} else if (ForwardWdownAction=36) {
 	Run, %CustomForwardWdownPath%
} else {
	return ; this is unneeded
}
return

;; -------- X1 and X2 END

;; Customize Key START

~^LButton::
if not CtrlAltShiftWin
	return
if (CtrlLeftAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (CtrlLeftAction<>38 AND CtrlLeftAction<>26 AND CtrlLeftAction<>18 AND CtrlLeftAction<>19 AND CtrlLeftAction<>21 AND CtrlLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (CtrlLeftAction=1) { 
		Gosub, SnippingTool
	} else if (CtrlLeftAction=2) { 
		GoSub, KillMagnifierHK
	} else if (CtrlLeftAction=3) { 
		Gosub, ColorHK
	} else if (CtrlLeftAction=4) { 
		Gosub, MouseHK
	} else if (CtrlLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (CtrlLeftAction=6) { 
		Gosub, TextHK
	} else if (CtrlLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (CtrlLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (CtrlLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (CtrlLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (CtrlLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (CtrlLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (CtrlLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (CtrlLeftAction=14) { 
		goto, notepad
	} else if (CtrlLeftAction=15) { 
		goto, wordpad
	} else if (CtrlLeftAction=16) { 
		goto, mscalc
	} else if (CtrlLeftAction=17) { 
		gosub, mspaint
	} else if (CtrlLeftAction=18) {
		goto, Google
	} else if (CtrlLeftAction=19) {
		goto, GoogleHighlight
	} else if (CtrlLeftAction=20) {
		goto, GoogleClipboard
	} else if (CtrlLeftAction=21) {
		goto, SpeakIt
	} else if (CtrlLeftAction=22) {
		goto, SpeakHighlight
	} else if (CtrlLeftAction=23) {
		goto, SpeakClipboard
	} else if (CtrlLeftAction=24) {
		goto, MonitorOff
	} else if (CtrlLeftAction=25) {
		goto, OpenTray
	} else if (CtrlLeftAction=26) {
		goto, AlwaysOnTop
	} else if (CtrlLeftAction=27) {
		goto, WebTimer
	} else if (CtrlLeftAction=28) {
		goto, TimerTab
	} else if (CtrlLeftAction=29) {
		goto, ZoomFaster
	} else if (CtrlLeftAction=30) {
		goto, ZoomSlower
	} else if (CtrlLeftAction=31) {
		hotkeyMod=Ctrl
		goto, ElasticZoom
	} else if (CtrlLeftAction=32) {				
		hotkeyMod=Ctrl
		goto, ElasticStillZoom
	} else if (CtrlLeftAction=33) {				
		goto, SnipFree
	} else if (CtrlLeftAction=34) {				
		goto, SnipRect
	} else if (CtrlLeftAction=35) {				
		goto, SnipWin
	} else if (CtrlLeftAction=36) {				
		goto, SnipScreen
	} else if (CtrlLeftAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (CtrlLeftAction=38) {				
		goto, showHidePanel
	} else if (CtrlLeftAction=39) {
		sendinput ^!{Space}
	} else if (CtrlLeftAction=40) {
		Run, %CustomCtrlLeftPath%
	} else {
		return ; this is unneeded
	}
}
return

~^RButton::
if not CtrlAltShiftWin
	return
if (CtrlRightAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (CtrlRightAction<>38 AND CtrlRightAction<>26 AND CtrlRightAction<>18 AND CtrlRightAction<>19 AND CtrlRightAction<>21 AND CtrlRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (CtrlRightAction=1) { 
		Gosub, SnippingTool
	} else if (CtrlRightAction=2) { 
		GoSub, KillMagnifierHK
	} else if (CtrlRightAction=3) { 
		Gosub, ColorHK
	} else if (CtrlRightAction=4) { 
		Gosub, MouseHK
	} else if (CtrlRightAction=5) { 
		Gosub, KeyboardHK
	} else if (CtrlRightAction=6) { 
		Gosub, TextHK
	} else if (CtrlRightAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (CtrlRightAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (CtrlRightAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (CtrlRightAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (CtrlRightAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (CtrlRightAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (CtrlRightAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (CtrlRightAction=14) { 
		goto, notepad
	} else if (CtrlRightAction=15) { 
		goto, wordpad
	} else if (CtrlRightAction=16) { 
		goto, mscalc
	} else if (CtrlRightAction=17) { 
		gosub, mspaint
	} else if (CtrlRightAction=18) {
		goto, Google
	} else if (CtrlRightAction=19) {
		goto, GoogleHighlight
	} else if (CtrlRightAction=20) {
		goto, GoogleClipboard
	} else if (CtrlRightAction=21) {
		goto, SpeakIt
	} else if (CtrlRightAction=22) {
		goto, SpeakHighlight
	} else if (CtrlRightAction=23) {
		goto, SpeakClipboard
	} else if (CtrlRightAction=24) {
		goto, MonitorOff
	} else if (CtrlRightAction=25) {
		goto, OpenTray
	} else if (CtrlRightAction=26) {
		goto, AlwaysOnTop
	} else if (CtrlRightAction=27) {
		goto, WebTimer
	} else if (CtrlRightAction=28) {
		goto, TimerTab
	} else if (CtrlRightAction=29) {
		goto, ZoomFaster
	} else if (CtrlRightAction=30) {
		goto, ZoomSlower
	} else if (CtrlRightAction=31) {
		hotkeyMod=Ctrl
		goto, ElasticZoom
	} else if (CtrlRightAction=32) {				
		hotkeyMod=Ctrl
		goto, ElasticStillZoom
	} else if (CtrlRightAction=33) {				
		goto, SnipFree
	} else if (CtrlRightAction=34) {				
		goto, SnipRect
	} else if (CtrlRightAction=35) {				
		goto, SnipWin
	} else if (CtrlRightAction=36) {				
		goto, SnipScreen
	} else if (CtrlRightAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (CtrlRightAction=38) {				
		goto, showHidePanel
	} else if (CtrlRightAction=39) {
		sendinput ^!{Space}
	} else if (CtrlRightAction=40) {
		Run, %CustomCtrlRightPath%
	} else {
		return ; this is unneeded
	}
}
return

~!LButton::
if not CtrlAltShiftWin
	return
if (AltLeftAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (AltLeftAction<>38 AND AltLeftAction<>26 AND AltLeftAction<>18 AND AltLeftAction<>19 AND AltLeftAction<>21 AND AltLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (AltLeftAction=1) { 
		Gosub, SnippingTool
	} else if (AltLeftAction=2) { 
		GoSub, KillMagnifierHK
	} else if (AltLeftAction=3) { 
		Gosub, ColorHK
	} else if (AltLeftAction=4) { 
		Gosub, MouseHK
	} else if (AltLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (AltLeftAction=6) { 
		Gosub, TextHK
	} else if (AltLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (AltLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (AltLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (AltLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (AltLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (AltLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (AltLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (AltLeftAction=14) { 
		goto, notepad
	} else if (AltLeftAction=15) { 
		goto, wordpad
	} else if (AltLeftAction=16) { 
		goto, mscalc
	} else if (AltLeftAction=17) { 
		gosub, mspaint
	} else if (AltLeftAction=18) {
		goto, Google
	} else if (AltLeftAction=19) {
		goto, GoogleHighlight
	} else if (AltLeftAction=20) {
		goto, GoogleClipboard
	} else if (AltLeftAction=21) {
		goto, SpeakIt
	} else if (AltLeftAction=22) {
		goto, SpeakHighlight
	} else if (AltLeftAction=23) {
		goto, SpeakClipboard
	} else if (AltLeftAction=24) {
		goto, MonitorOff
	} else if (AltLeftAction=25) {
		goto, OpenTray
	} else if (AltLeftAction=26) {
		goto, AlwaysOnTop
	} else if (AltLeftAction=27) {
		goto, WebTimer
	} else if (AltLeftAction=28) {
		goto, TimerTab
	} else if (AltLeftAction=29) {
		goto, ZoomFaster
	} else if (AltLeftAction=30) {
		goto, ZoomSlower
	} else if (AltLeftAction=31) {
		hotkeyMod=Alt
		goto, ElasticZoom
	} else if (AltLeftAction=32) {				
		hotkeyMod=Alt
		goto, ElasticStillZoom
	} else if (AltLeftAction=33) {				
		goto, SnipFree
	} else if (AltLeftAction=34) {				
		goto, SnipRect
	} else if (AltLeftAction=35) {				
		goto, SnipWin
	} else if (AltLeftAction=36) {				
		goto, SnipScreen
	} else if (AltLeftAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (AltLeftAction=38) {				
		goto, showHidePanel		
	} else if (AltLeftAction=39) {
		sendinput ^!{Space}
	} else if (AltLeftAction=40) {
		Run, %CustomAltLeftPath%
	} else {
		return ; this is unneeded
	}
}
return

~!RButton::
if not CtrlAltShiftWin
	return
if (AltRightAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (AltRightAction<>38 AND AltRightAction<>26 AND AltRightAction<>18 AND AltRightAction<>19 AND AltRightAction<>21 AND AltRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (AltRightAction=1) { 
		Gosub, SnippingTool
	} else if (AltRightAction=2) { 
		GoSub, KillMagnifierHK
	} else if (AltRightAction=3) { 
		Gosub, ColorHK
	} else if (AltRightAction=4) { 
		Gosub, MouseHK
	} else if (AltRightAction=5) { 
		Gosub, KeyboardHK
	} else if (AltRightAction=6) { 
		Gosub, TextHK
	} else if (AltRightAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (AltRightAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (AltRightAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (AltRightAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (AltRightAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (AltRightAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (AltRightAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (AltRightAction=14) { 
		goto, notepad
	} else if (AltRightAction=15) { 
		goto, wordpad
	} else if (AltRightAction=16) { 
		goto, mscalc
	} else if (AltRightAction=17) { 
		gosub, mspaint
	} else if (AltRightAction=18) {
		goto, Google
	} else if (AltRightAction=19) {
		goto, GoogleHighlight
	} else if (AltRightAction=20) {
		goto, GoogleClipboard
	} else if (AltRightAction=21) {
		goto, SpeakIt
	} else if (AltRightAction=22) {
		goto, SpeakHighlight
	} else if (AltRightAction=23) {
		goto, SpeakClipboard
	} else if (AltRightAction=24) {
		goto, MonitorOff
	} else if (AltRightAction=25) {
		goto, OpenTray
	} else if (AltRightAction=26) {
		goto, AlwaysOnTop
	} else if (AltRightAction=27) {
		goto, WebTimer
	} else if (AltRightAction=28) {
		goto, TimerTab
	} else if (AltRightAction=29) {
		goto, ZoomFaster
	} else if (AltRightAction=30) {
		goto, ZoomSlower
	} else if (AltRightAction=31) {
		hotkeyMod=Alt
		goto, ElasticZoom
	} else if (AltRightAction=32) {				
		hotkeyMod=Alt
		goto, ElasticStillZoom
	} else if (AltRightAction=33) {				
		goto, SnipFree
	} else if (AltRightAction=34) {				
		goto, SnipRect
	} else if (AltRightAction=35) {				
		goto, SnipWin
	} else if (AltRightAction=36) {				
		goto, SnipScreen
	} else if (AltRightAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (AltRightAction=38) {				
		goto, showHidePanel
	} else if (AltRightAction=39) {
		sendinput ^!{Space}
	} else if (AltRightAction=40) {
		Run, %CustomAltRightPath%
	} else {
		return ; this is unneeded
	}
}
return

~+LButton::
if not CtrlAltShiftWin
	return
if (ShiftLeftAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (ShiftLeftAction<>38 AND ShiftLeftAction<>26 AND ShiftLeftAction<>18 AND ShiftLeftAction<>19 AND ShiftLeftAction<>21 AND ShiftLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (ShiftLeftAction=1) { 
		Gosub, SnippingTool
	} else if (ShiftLeftAction=2) { 
		GoSub, KillMagnifierHK
	} else if (ShiftLeftAction=3) { 
		Gosub, ColorHK
	} else if (ShiftLeftAction=4) { 
		Gosub, MouseHK
	} else if (ShiftLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (ShiftLeftAction=6) { 
		Gosub, TextHK
	} else if (ShiftLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (ShiftLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (ShiftLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (ShiftLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (ShiftLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (ShiftLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (ShiftLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (ShiftLeftAction=14) { 
		goto, notepad
	} else if (ShiftLeftAction=15) { 
		goto, wordpad
	} else if (ShiftLeftAction=16) { 
		goto, mscalc
	} else if (ShiftLeftAction=17) { 
		gosub, mspaint
	} else if (ShiftLeftAction=18) {
		goto, Google
	} else if (ShiftLeftAction=19) {
		goto, GoogleHighlight
	} else if (ShiftLeftAction=20) {
		goto, GoogleClipboard
	} else if (ShiftLeftAction=21) {
		goto, SpeakIt
	} else if (ShiftLeftAction=22) {
		goto, SpeakHighlight
	} else if (ShiftLeftAction=23) {
		goto, SpeakClipboard
	} else if (ShiftLeftAction=24) {
		goto, MonitorOff
	} else if (ShiftLeftAction=25) {
		goto, OpenTray
	} else if (ShiftLeftAction=26) {
		goto, AlwaysOnTop
	} else if (ShiftLeftAction=27) {
		goto, WebTimer
	} else if (ShiftLeftAction=28) {
		goto, TimerTab
	} else if (ShiftLeftAction=29) {
		goto, ZoomFaster
	} else if (ShiftLeftAction=30) {
		goto, ZoomSlower
	} else if (ShiftLeftAction=31) {
		hotkeyMod=Shift
		goto, ElasticZoom
	} else if (ShiftLeftAction=32) {				
		hotkeyMod=Shift
		goto, ElasticStillZoom
	} else if (ShiftLeftAction=33) {				
		goto, SnipFree
	} else if (ShiftLeftAction=34) {				
		goto, SnipRect
	} else if (ShiftLeftAction=35) {				
		goto, SnipWin
	} else if (ShiftLeftAction=36) {				
		goto, SnipScreen
	} else if (ShiftLeftAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (ShiftLeftAction=38) {				
		goto, showHidePanel
	} else if (ShiftLeftAction=39) {
		sendinput ^!{Space}
	} else if (ShiftLeftAction=40) {
		Run, %CustomShiftLeftPath%
	} else {
		return ; this is unneeded
	}
}
return

~+RButton::
if not CtrlAltShiftWin
	return
if (ShiftRightAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (ShiftRightAction<>38 AND ShiftRightAction<>26 AND ShiftRightAction<>18 AND ShiftRightAction<>19 AND ShiftRightAction<>21 AND ShiftRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (ShiftRightAction=1) { 
		Gosub, SnippingTool
	} else if (ShiftRightAction=2) { 
		GoSub, KillMagnifierHK
	} else if (ShiftRightAction=3) { 
		Gosub, ColorHK
	} else if (ShiftRightAction=4) { 
		Gosub, MouseHK
	} else if (ShiftRightAction=5) { 
		Gosub, KeyboardHK
	} else if (ShiftRightAction=6) { 
		Gosub, TextHK
	} else if (ShiftRightAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (ShiftRightAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (ShiftRightAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (ShiftRightAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (ShiftRightAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (ShiftRightAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (ShiftRightAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (ShiftRightAction=14) { 
		goto, notepad
	} else if (ShiftRightAction=15) { 
		goto, wordpad
	} else if (ShiftRightAction=16) { 
		goto, mscalc
	} else if (ShiftRightAction=17) { 
		gosub, mspaint
	} else if (ShiftRightAction=18) {
		goto, Google
	} else if (ShiftRightAction=19) {
		goto, GoogleHighlight
	} else if (ShiftRightAction=20) {
		goto, GoogleClipboard
	} else if (ShiftRightAction=21) {
		goto, SpeakIt
	} else if (ShiftRightAction=22) {
		goto, SpeakHighlight
	} else if (ShiftRightAction=23) {
		goto, SpeakClipboard
	} else if (ShiftRightAction=24) {
		goto, MonitorOff
	} else if (ShiftRightAction=25) {
		goto, OpenTray
	} else if (ShiftRightAction=26) {
		goto, AlwaysOnTop
	} else if (ShiftRightAction=27) {
		goto, WebTimer
	} else if (ShiftRightAction=28) {
		goto, TimerTab
	} else if (ShiftRightAction=29) {
		goto, ZoomFaster
	} else if (ShiftRightAction=30) {
		goto, ZoomSlower
	} else if (ShiftRightAction=31) {
		hotkeyMod=Shift
		goto, ElasticZoom
	} else if (ShiftRightAction=32) {				
		hotkeyMod=Shift
		goto, ElasticStillZoom
	} else if (ShiftRightAction=33) {				
		goto, SnipFree
	} else if (ShiftRightAction=34) {				
		goto, SnipRect
	} else if (ShiftRightAction=35) {				
		goto, SnipWin
	} else if (ShiftRightAction=36) {				
		goto, SnipScreen
	} else if (ShiftRightAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (ShiftRightAction=38) {				
		goto, showHidePanel
	} else if (ShiftRightAction=39) {
		sendinput ^!{Space}
	} else if (ShiftRightAction=40) {
		Run, %CustomShiftRightPath%
	} else {
		return ; this is unneeded
	}
}
return

~#LButton::
if not CtrlAltShiftWin
	return
if (WinLeftAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (WinLeftAction<>38 AND WinLeftAction<>26 AND WinLeftAction<>18 AND WinLeftAction<>19 AND WinLeftAction<>21 AND WinLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (WinLeftAction=1) { 
		Gosub, SnippingTool
	} else if (WinLeftAction=2) { 
		GoSub, KillMagnifierHK
	} else if (WinLeftAction=3) { 
		Gosub, ColorHK
	} else if (WinLeftAction=4) { 
		Gosub, MouseHK
	} else if (WinLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (WinLeftAction=6) { 
		Gosub, TextHK
	} else if (WinLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (WinLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (WinLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (WinLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (WinLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (WinLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (WinLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (WinLeftAction=14) { 
		goto, notepad
	} else if (WinLeftAction=15) { 
		goto, wordpad
	} else if (WinLeftAction=16) { 
		goto, mscalc
	} else if (WinLeftAction=17) { 
		gosub, mspaint
	} else if (WinLeftAction=18) {
		goto, Google
	} else if (WinLeftAction=19) {
		goto, GoogleHighlight
	} else if (WinLeftAction=20) {
		goto, GoogleClipboard
	} else if (WinLeftAction=21) {
		goto, SpeakIt
	} else if (WinLeftAction=22) {
		goto, SpeakHighlight
	} else if (WinLeftAction=23) {
		goto, SpeakClipboard
	} else if (WinLeftAction=24) {
		goto, MonitorOff
	} else if (WinLeftAction=25) {
		goto, OpenTray
	} else if (WinLeftAction=26) {
		goto, AlwaysOnTop
	} else if (WinLeftAction=27) {
		goto, WebTimer
	} else if (WinLeftAction=28) {
		goto, TimerTab
	} else if (WinLeftAction=29) {
		goto, ZoomFaster
	} else if (WinLeftAction=30) {
		goto, ZoomSlower
	} else if (WinLeftAction=31) {
		hotkeyMod=LWin ; generic Win is unsupported
		goto, ElasticZoom
	} else if (WinLeftAction=32) {				
		hotkeyMod=LWin
		goto, ElasticStillZoom
	} else if (WinLeftAction=33) {				
		goto, SnipFree
	} else if (WinLeftAction=34) {				
		goto, SnipRect
	} else if (WinLeftAction=35) {				
		goto, SnipWin
	} else if (WinLeftAction=36) {				
		goto, SnipScreen
	} else if (WinLeftAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (WinLeftAction=38) {				
		goto, showHidePanel
	} else if (WinLeftAction=39) {
		sendinput ^!{Space}
	} else if (WinLeftAction=40) {
		Run, %CustomWinLeftPath%
	} else {
		return ; this is unneeded
	}
}
return

~#RButton::
if not CtrlAltShiftWin
	return
if (WinRightAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (WinRightAction<>38 AND WinRightAction<>26 AND WinRightAction<>18 AND WinRightAction<>19 AND WinRightAction<>21 AND WinRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (WinRightAction=1) { 
		Gosub, SnippingTool
	} else if (WinRightAction=2) { 
		GoSub, KillMagnifierHK
	} else if (WinRightAction=3) { 
		Gosub, ColorHK
	} else if (WinRightAction=4) { 
		Gosub, MouseHK
	} else if (WinRightAction=5) { 
		Gosub, KeyboardHK
	} else if (WinRightAction=6) { 
		Gosub, TextHK
	} else if (WinRightAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (WinRightAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (WinRightAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (WinRightAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (WinRightAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (WinRightAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (WinRightAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (WinRightAction=14) { 
		goto, notepad
	} else if (WinRightAction=15) { 
		goto, wordpad
	} else if (WinRightAction=16) { 
		goto, mscalc
	} else if (WinRightAction=17) { 
		gosub, mspaint
	} else if (WinRightAction=18) {
		goto, Google
	} else if (WinRightAction=19) {
		goto, GoogleHighlight
	} else if (WinRightAction=20) {
		goto, GoogleClipboard
	} else if (WinRightAction=21) {
		goto, SpeakIt
	} else if (WinRightAction=22) {
		goto, SpeakHighlight
	} else if (WinRightAction=23) {
		goto, SpeakClipboard
	} else if (WinRightAction=24) {
		goto, MonitorOff
	} else if (WinRightAction=25) {
		goto, OpenTray
	} else if (WinRightAction=26) {
		goto, AlwaysOnTop
	} else if (WinRightAction=27) {
		goto, WebTimer
	} else if (WinRightAction=28) {
		goto, TimerTab
	} else if (WinRightAction=29) {
		goto, ZoomFaster
	} else if (WinRightAction=30) {
		goto, ZoomSlower
	} else if (WinRightAction=31) {
		hotkeyMod=LWin
		goto, ElasticZoom
	} else if (WinRightAction=32) {				
		hotkeyMod=LWin
		goto, ElasticStillZoom
	} else if (WinRightAction=33) {				
		goto, SnipFree
	} else if (WinRightAction=34) {				
		goto, SnipRect
	} else if (WinRightAction=35) {				
		goto, SnipWin
	} else if (WinRightAction=36) {				
		goto, SnipScreen
	} else if (WinRightAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (WinRightAction=38) {				
		goto, showHidePanel
	} else if (WinRightAction=39) {
		sendinput ^!{Space}
	} else if (WinRightAction=40) {
		Run, %CustomWinRightPath%
	} else {
		return ; this is unneeded
	}
}
return

;; Customize Keys END

;; Customize Key WHEEL START

~^WheelUp::
if not CtrlAltShiftWin
	return
if (CtrlWupAction=39) { ; 39 = None for Key Wheel
	return
}
if not paused {
	if (CtrlWupAction=1) { 
		Gosub, SnippingTool
	} else if (CtrlWupAction=2) { 
		GoSub, KillMagnifierHK
	} else if (CtrlWupAction=3) { 
		Gosub, ColorHK
	} else if (CtrlWupAction=4) { 
		Gosub, MouseHK
	} else if (CtrlWupAction=5) { 
		Gosub, KeyboardHK
	} else if (CtrlWupAction=6) { 
		Gosub, TextHK
	} else if (CtrlWupAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (CtrlWupAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (CtrlWupAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (CtrlWupAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (CtrlWupAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (CtrlWupAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (CtrlWupAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (CtrlWupAction=14) { 
		goto, notepad
	} else if (CtrlWupAction=15) { 
		goto, wordpad
	} else if (CtrlWupAction=16) { 
		goto, mscalc
	} else if (CtrlWupAction=17) { 
		gosub, mspaint
	} else if (CtrlWupAction=18) {
		goto, GoogleHighlight
	} else if (CtrlWupAction=19) {
		goto, GoogleClipboard
	} else if (CtrlWupAction=20) {
		goto, SpeakHighlight
	} else if (CtrlWupAction=21) {
		goto, SpeakClipboard
	} else if (CtrlWupAction=22) {
		goto, MonitorOff
	} else if (CtrlWupAction=23) {
		goto, OpenTray
	} else if (CtrlWupAction=24) {
		goto, AlwaysOnTop
	} else if (CtrlWupAction=25) {
		goto, WebTimer
	} else if (CtrlWupAction=26) {
		goto, TimerTab
	} else if (CtrlWupAction=27) {
		goto, ZoomFaster
	} else if (CtrlWupAction=28) {
		goto, ZoomSlower
	} else if (CtrlWupAction=29) {
		hotkeyMod=Ctrl
		goto, ElasticZoom
	} else if (CtrlWupAction=30) {				
		hotkeyMod=Ctrl
		goto, ElasticStillZoom
	} else if (CtrlWupAction=31) {				
		goto, SnipFree
	} else if (CtrlWupAction=32) {				
		goto, SnipRect
	} else if (CtrlWupAction=33) {				
		goto, SnipWin
	} else if (CtrlWupAction=34) {				
		goto, SnipScreen
	} else if (CtrlWupAction=35) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (CtrlWupAction=36) {				
		goto, showHidePanel	
	} else if (CtrlWupAction=37) {
		sendinput ^!{Space}
	} else if (CtrlWupAction=38) {
		Run, %CustomCtrlWupPath%
	} else {
		return ; this is unneeded
	}
}
return


~^WheelDown::
if not CtrlAltShiftWin
	return
if (CtrlWdownAction=39) { ; 39 = None for Key Wheel
	return
}
if not paused {
	if (CtrlWdownAction=1) { 
		Gosub, SnippingTool
	} else if (CtrlWdownAction=2) { 
		GoSub, KillMagnifierHK
	} else if (CtrlWdownAction=3) { 
		Gosub, ColorHK
	} else if (CtrlWdownAction=4) { 
		Gosub, MouseHK
	} else if (CtrlWdownAction=5) { 
		Gosub, KeyboardHK
	} else if (CtrlWdownAction=6) { 
		Gosub, TextHK
	} else if (CtrlWdownAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (CtrlWdownAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (CtrlWdownAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (CtrlWdownAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (CtrlWdownAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (CtrlWdownAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (CtrlWdownAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (CtrlWdownAction=14) { 
		goto, notepad
	} else if (CtrlWdownAction=15) { 
		goto, wordpad
	} else if (CtrlWdownAction=16) { 
		goto, mscalc
	} else if (CtrlWdownAction=17) { 
		gosub, mspaint
	} else if (CtrlWdownAction=18) {
		goto, GoogleHighlight
	} else if (CtrlWdownAction=19) {
		goto, GoogleClipboard
	} else if (CtrlWdownAction=20) {
		goto, SpeakHighlight
	} else if (CtrlWdownAction=21) {
		goto, SpeakClipboard
	} else if (CtrlWdownAction=22) {
		goto, MonitorOff
	} else if (CtrlWdownAction=23) {
		goto, OpenTray
	} else if (CtrlWdownAction=24) {
		goto, AlwaysOnTop
	} else if (CtrlWdownAction=25) {
		goto, WebTimer
	} else if (CtrlWdownAction=26) {
		goto, TimerTab
	} else if (CtrlWdownAction=27) {
		goto, ZoomFaster
	} else if (CtrlWdownAction=28) {
		goto, ZoomSlower
	} else if (CtrlWdownAction=29) {
		hotkeyMod=Ctrl
		goto, ElasticZoom
	} else if (CtrlWdownAction=30) {				
		hotkeyMod=Ctrl
		goto, ElasticStillZoom
	} else if (CtrlWdownAction=31) {				
		goto, SnipFree
	} else if (CtrlWdownAction=32) {				
		goto, SnipRect
	} else if (CtrlWdownAction=33) {				
		goto, SnipWin
	} else if (CtrlWdownAction=34) {				
		goto, SnipScreen
	} else if (CtrlWdownAction=35) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (CtrlWdownAction=36) {				
		goto, showHidePanel	
	} else if (CtrlWdownAction=37) {
		sendinput ^!{Space}
	} else if (CtrlWdownAction=38) {
		Run, %CustomCtrlWdownPath%
	} else {
		return ; this is unneeded
	}
}
return

~!WheelUp::
if not CtrlAltShiftWin
	return
if (AltWupAction=39) { ; 39 = None for Key Wheel
	return
}
if not paused {
	if (AltWupAction=1) { 
		Gosub, SnippingTool
	} else if (AltWupAction=2) { 
		GoSub, KillMagnifierHK
	} else if (AltWupAction=3) { 
		Gosub, ColorHK
	} else if (AltWupAction=4) { 
		Gosub, MouseHK
	} else if (AltWupAction=5) { 
		Gosub, KeyboardHK
	} else if (AltWupAction=6) { 
		Gosub, TextHK
	} else if (AltWupAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (AltWupAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (AltWupAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (AltWupAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (AltWupAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (AltWupAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (AltWupAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (AltWupAction=14) { 
		goto, notepad
	} else if (AltWupAction=15) { 
		goto, wordpad
	} else if (AltWupAction=16) { 
		goto, mscalc
	} else if (AltWupAction=17) { 
		gosub, mspaint
	} else if (AltWupAction=18) {
		goto, GoogleHighlight
	} else if (AltWupAction=19) {
		goto, GoogleClipboard
	} else if (AltWupAction=20) {
		goto, SpeakHighlight
	} else if (AltWupAction=21) {
		goto, SpeakClipboard
	} else if (AltWupAction=22) {
		goto, MonitorOff
	} else if (AltWupAction=23) {
		goto, OpenTray
	} else if (AltWupAction=24) {
		goto, AlwaysOnTop
	} else if (AltWupAction=25) {
		goto, WebTimer
	} else if (AltWupAction=26) {
		goto, TimerTab
	} else if (AltWupAction=27) {
		goto, ZoomFaster
	} else if (AltWupAction=28) {
		goto, ZoomSlower
	} else if (AltWupAction=29) {
		hotkeyMod=Alt
		goto, ElasticZoom
	} else if (AltWupAction=30) {				
		hotkeyMod=Alt
		goto, ElasticStillZoom
	} else if (AltWupAction=31) {
		goto, SnipFree
	} else if (AltWupAction=32) {				
		goto, SnipRect
	} else if (AltWupAction=33) {				
		goto, SnipWin
	} else if (AltWupAction=34) {				
		goto, SnipScreen
	} else if (AltWupAction=35) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (AltWupAction=36) {				
		goto, showHidePanel		
	} else if (AltWupAction=37) {
		sendinput ^!{Space}
	} else if (AltWupAction=38) {
		Run, %CustomAltWupPath%
	} else {
		return ; this is unneeded
	}
}
return


~!WheelDown::
if not CtrlAltShiftWin
	return
if (AltWdownAction=39) { ; 39 = None for Key Wheel
	return
}
if not paused {
	if (AltWdownAction=1) { 
		Gosub, SnippingTool
	} else if (AltWdownAction=2) { 
		GoSub, KillMagnifierHK
	} else if (AltWdownAction=3) { 
		Gosub, ColorHK
	} else if (AltWdownAction=4) { 
		Gosub, MouseHK
	} else if (AltWdownAction=5) { 
		Gosub, KeyboardHK
	} else if (AltWdownAction=6) { 
		Gosub, TextHK
	} else if (AltWdownAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (AltWdownAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (AltWdownAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (AltWdownAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (AltWdownAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (AltWdownAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (AltWdownAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (AltWdownAction=14) { 
		goto, notepad
	} else if (AltWdownAction=15) { 
		goto, wordpad
	} else if (AltWdownAction=16) { 
		goto, mscalc
	} else if (AltWdownAction=17) { 
		gosub, mspaint
	} else if (AltWdownAction=18) {
		goto, GoogleHighlight
	} else if (AltWdownAction=19) {
		goto, GoogleClipboard
	} else if (AltWdownAction=20) {
		goto, SpeakHighlight
	} else if (AltWdownAction=21) {
		goto, SpeakClipboard
	} else if (AltWdownAction=22) {
		goto, MonitorOff
	} else if (AltWdownAction=23) {
		goto, OpenTray
	} else if (AltWdownAction=24) {
		goto, AlwaysOnTop
	} else if (AltWdownAction=25) {
		goto, WebTimer
	} else if (AltWdownAction=26) {
		goto, TimerTab
	} else if (AltWdownAction=27) {
		goto, ZoomFaster
	} else if (AltWdownAction=28) {
		goto, ZoomSlower
	} else if (AltWdownAction=29) {
		hotkeyMod=Alt
		goto, ElasticZoom
	} else if (AltWdownAction=30) {				
		hotkeyMod=Alt
		goto, ElasticStillZoom
	} else if (AltWdownAction=31) {				
		goto, SnipFree
	} else if (AltWdownAction=32) {				
		goto, SnipRect
	} else if (AltWdownAction=33) {				
		goto, SnipWin
	} else if (AltWdownAction=34) {				
		goto, SnipScreen
	} else if (AltWdownAction=35) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (AltWdownAction=36) {				
		goto, showHidePanel	
	} else if (AltWdownAction=37) {
		sendinput ^!{Space}
	} else if (AltWdownAction=38) {
		Run, %CustomAltWdownPath%
	} else {
		return ; this is unneeded
	}
}
return

~#WheelUp::
if not CtrlAltShiftWin
	return
if (WinWupAction=39) { ; 39 = None for Key Wheel
	return
}
if not paused {
	if (WinWupAction=1) { 
		Gosub, SnippingTool
	} else if (WinWupAction=2) { 
		GoSub, KillMagnifierHK
	} else if (WinWupAction=3) { 
		Gosub, ColorHK
	} else if (WinWupAction=4) { 
		Gosub, MouseHK
	} else if (WinWupAction=5) { 
		Gosub, KeyboardHK
	} else if (WinWupAction=6) { 
		Gosub, TextHK
	} else if (WinWupAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (WinWupAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (WinWupAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (WinWupAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (WinWupAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (WinWupAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (WinWupAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (WinWupAction=14) { 
		goto, notepad
	} else if (WinWupAction=15) { 
		goto, wordpad
	} else if (WinWupAction=16) { 
		goto, mscalc
	} else if (WinWupAction=17) { 
		gosub, mspaint
	} else if (WinWupAction=18) {
		goto, GoogleHighlight
	} else if (WinWupAction=19) {
		goto, GoogleClipboard
	} else if (WinWupAction=20) {
		goto, SpeakHighlight
	} else if (WinWupAction=21) {
		goto, SpeakClipboard
	} else if (WinWupAction=22) {
		goto, MonitorOff
	} else if (WinWupAction=23) {
		goto, OpenTray
	} else if (WinWupAction=24) {
		goto, AlwaysOnTop
	} else if (WinWupAction=25) {
		goto, WebTimer
	} else if (WinWupAction=26) {
		goto, TimerTab
	} else if (WinWupAction=27) {
		goto, ZoomFaster
	} else if (WinWupAction=28) {
		goto, ZoomSlower
	} else if (WinWupAction=29) {
		hotkeyMod=LWin
		goto, ElasticZoom
	} else if (WinWupAction=30) {				
		hotkeyMod=LWin
		goto, ElasticStillZoom
	} else if (WinWupAction=31) {				
		goto, SnipFree
	} else if (WinWupAction=32) {				
		goto, SnipRect
	} else if (WinWupAction=33) {				
		goto, SnipWin
	} else if (WinWupAction=34) {				
		goto, SnipScreen
	} else if (WinWupAction=35) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (WinWupAction=36) {				
		goto, showHidePanel
	} else if (WinWupAction=37) {
		sendinput ^!{Space}
	} else if (WinWupAction=38) {
		Run, %CustomWinWupPath%
	} else {
		return ; this is unneeded
	}
}
return


~#WheelDown::
if not CtrlAltShiftWin
	return
if (WinWdownAction=39) { ; 39 = None for Key Wheel
	return
}
if not paused {
	if (WinWdownAction=1) { 
		Gosub, SnippingTool
	} else if (WinWdownAction=2) { 
		GoSub, KillMagnifierHK
	} else if (WinWdownAction=3) { 
		Gosub, ColorHK
	} else if (WinWdownAction=4) { 
		Gosub, MouseHK
	} else if (WinWdownAction=5) { 
		Gosub, KeyboardHK
	} else if (WinWdownAction=6) { 
		Gosub, TextHK
	} else if (WinWdownAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (WinWdownAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (WinWdownAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (WinWdownAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (WinWdownAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (WinWdownAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (WinWdownAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (WinWdownAction=14) { 
		goto, notepad
	} else if (WinWdownAction=15) { 
		goto, wordpad
	} else if (WinWdownAction=16) { 
		goto, mscalc
	} else if (WinWdownAction=17) { 
		gosub, mspaint
	} else if (WinWdownAction=18) {
		goto, GoogleHighlight
	} else if (WinWdownAction=19) {
		goto, GoogleClipboard
	} else if (WinWdownAction=20) {
		goto, SpeakHighlight
	} else if (WinWdownAction=21) {
		goto, SpeakClipboard
	} else if (WinWdownAction=22) {
		goto, MonitorOff
	} else if (WinWdownAction=23) {
		goto, OpenTray
	} else if (WinWdownAction=24) {
		goto, AlwaysOnTop
	} else if (WinWdownAction=25) {
		goto, WebTimer
	} else if (WinWdownAction=26) {
		goto, TimerTab
	} else if (WinWdownAction=27) {
		goto, ZoomFaster
	} else if (WinWdownAction=28) {
		goto, ZoomSlower
	} else if (WinWdownAction=29) {
		hotkeyMod=LWin
		goto, ElasticZoom
	} else if (WinWdownAction=30) {				
		hotkeyMod=LWin
		goto, ElasticStillZoom
	} else if (WinWdownAction=31) {				
		goto, SnipFree
	} else if (WinWdownAction=32) {				
		goto, SnipRect
	} else if (WinWdownAction=33) {				
		goto, SnipWin
	} else if (WinWdownAction=34) {				
		goto, SnipScreen
	} else if (WinWdownAction=35) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (WinWdownAction=36) {				
		goto, showHidePanel	
	} else if (WinWdownAction=37) {
		sendinput ^!{Space}
	} else if (WinWdownAction=38) {
		Run, %CustomWinWdownPath%
	} else {
		return ; this is unneeded
	}
}
return

;; Customize Key WHEEL END

;; Customize Left/Right - Start

~LButton & ~MButton::
if not LeftRight
	return
if (LeftMiddleAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (LeftMiddleAction<>38 AND LeftMiddleAction<>26 AND LeftMiddleAction<>18 AND LeftMiddleAction<>19 AND LeftMiddleAction<>21 AND LeftMiddleAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (LeftMiddleAction=1) { 
		Gosub, SnippingTool
	} else if (LeftMiddleAction=2) { 
		GoSub, KillMagnifierHK
	} else if (LeftMiddleAction=3) { 
		Gosub, ColorHK
	} else if (LeftMiddleAction=4) { 
		Gosub, MouseHK
	} else if (LeftMiddleAction=5) { 
		Gosub, KeyboardHK
	} else if (LeftMiddleAction=6) { 
		Gosub, TextHK
	} else if (LeftMiddleAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (LeftMiddleAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (LeftMiddleAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (LeftMiddleAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (LeftMiddleAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (LeftMiddleAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (LeftMiddleAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (LeftMiddleAction=14) { 
		goto, notepad
	} else if (LeftMiddleAction=15) { 
		goto, wordpad
	} else if (LeftMiddleAction=16) { 
		goto, mscalc
	} else if (LeftMiddleAction=17) { 
		gosub, mspaint
	} else if (LeftMiddleAction=18) {
		goto, Google
	} else if (LeftMiddleAction=19) {
		goto, GoogleHighlight
	} else if (LeftMiddleAction=20) {
		goto, GoogleClipboard
	} else if (LeftMiddleAction=21) {
		goto, SpeakIt
	} else if (LeftMiddleAction=22) {
		goto, SpeakHighlight
	} else if (LeftMiddleAction=23) {
		goto, SpeakClipboard
	} else if (LeftMiddleAction=24) {
		goto, MonitorOff
	} else if (LeftMiddleAction=25) {
		goto, OpenTray
	} else if (LeftMiddleAction=26) {
		goto, AlwaysOnTop
	} else if (LeftMiddleAction=27) {
		goto, WebTimer
	} else if (LeftMiddleAction=28) {
		goto, TimerTab
	} else if (LeftMiddleAction=29) {
		goto, ZoomFaster
	} else if (LeftMiddleAction=30) {
		goto, ZoomSlower
	} else if (LeftMiddleAction=31) {
		hotkeyMod=Left
		goto, ElasticZoom
	} else if (LeftMiddleAction=32) {				
		hotkeyMod=Left
		goto, ElasticStillZoom
	} else if (LeftMiddleAction=33) {				
		goto, SnipFree
	} else if (LeftMiddleAction=34) {				
		goto, SnipRect
	} else if (LeftMiddleAction=35) {				
		goto, SnipWin
	} else if (LeftMiddleAction=36) {				
		goto, SnipScreen
	} else if (LeftMiddleAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (LeftMiddleAction=38) {				
		goto, showHidePanel
	} else if (LeftMiddleAction=39) {
		sendinput ^!{Space}
	} else if (LeftMiddleAction=40) {
		Run, %CustomLeftMiddlePath%
	} else {
		return ; this is unneeded
	}
}
return

; Note the below is "~LButton & RButton::" instead of "~LButton & ~RButton::" (with the later ~) although the latter permits other apps to access the hotkey, it would not disable the right click menu which makes AeroZoom panel annoying to use.

~LButton & RButton::
if not LeftRight {
	goto, showHidePanel
	return
}
if (LeftRightAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (LeftRightAction<>38 AND LeftRightAction<>26 AND LeftRightAction<>18 AND LeftRightAction<>19 AND LeftRightAction<>21 AND LeftRightAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (LeftRightAction=1) { 
		Gosub, SnippingTool
	} else if (LeftRightAction=2) { 
		GoSub, KillMagnifierHK
	} else if (LeftRightAction=3) { 
		Gosub, ColorHK
	} else if (LeftRightAction=4) { 
		Gosub, MouseHK
	} else if (LeftRightAction=5) { 
		Gosub, KeyboardHK
	} else if (LeftRightAction=6) { 
		Gosub, TextHK
	} else if (LeftRightAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (LeftRightAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (LeftRightAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (LeftRightAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (LeftRightAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (LeftRightAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (LeftRightAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (LeftRightAction=14) { 
		goto, notepad
	} else if (LeftRightAction=15) { 
		goto, wordpad
	} else if (LeftRightAction=16) { 
		goto, mscalc
	} else if (LeftRightAction=17) { 
		gosub, mspaint
	} else if (LeftRightAction=18) {
		goto, Google
	} else if (LeftRightAction=19) {
		goto, GoogleHighlight
	} else if (LeftRightAction=20) {
		goto, GoogleClipboard
	} else if (LeftRightAction=21) {
		goto, SpeakIt
	} else if (LeftRightAction=22) {
		goto, SpeakHighlight
	} else if (LeftRightAction=23) {
		goto, SpeakClipboard
	} else if (LeftRightAction=24) {
		goto, MonitorOff
	} else if (LeftRightAction=25) {
		goto, OpenTray
	} else if (LeftRightAction=26) {
		goto, AlwaysOnTop
	} else if (LeftRightAction=27) {
		goto, WebTimer
	} else if (LeftRightAction=28) {
		goto, TimerTab
	} else if (LeftRightAction=29) {
		goto, ZoomFaster
	} else if (LeftRightAction=30) {
		goto, ZoomSlower
	} else if (LeftRightAction=31) {
		hotkeyMod=Left
		goto, ElasticZoom
	} else if (LeftRightAction=32) {				
		hotkeyMod=Left
		goto, ElasticStillZoom
	} else if (LeftRightAction=33) {				
		goto, SnipFree
	} else if (LeftRightAction=34) {				
		goto, SnipRect
	} else if (LeftRightAction=35) {				
		goto, SnipWin
	} else if (LeftRightAction=36) {				
		goto, SnipScreen
	} else if (LeftRightAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (LeftRightAction=38) {				
		goto, showHidePanel
	} else if (LeftRightAction=39) {
		sendinput ^!{Space}
	} else if (LeftRightAction=40) {
		Run, %CustomLeftRightPath%
	} else {
		return ; this is unneeded
	}
}
return

~RButton & LButton::
if not LeftRight {
	goto, showHidePanel
	return
}
if (RightLeftAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (RightLeftAction<>38 AND RightLeftAction<>26 AND RightLeftAction<>18 AND RightLeftAction<>19 AND RightLeftAction<>21 AND RightLeftAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (RightLeftAction=1) { 
		Gosub, SnippingTool
	} else if (RightLeftAction=2) { 
		GoSub, KillMagnifierHK
	} else if (RightLeftAction=3) { 
		Gosub, ColorHK
	} else if (RightLeftAction=4) { 
		Gosub, MouseHK
	} else if (RightLeftAction=5) { 
		Gosub, KeyboardHK
	} else if (RightLeftAction=6) { 
		Gosub, TextHK
	} else if (RightLeftAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (RightLeftAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (RightLeftAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (RightLeftAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (RightLeftAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (RightLeftAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (RightLeftAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (RightLeftAction=14) { 
		goto, notepad
	} else if (RightLeftAction=15) { 
		goto, wordpad
	} else if (RightLeftAction=16) { 
		goto, mscalc
	} else if (RightLeftAction=17) { 
		gosub, mspaint
	} else if (RightLeftAction=18) {
		goto, Google
	} else if (RightLeftAction=19) {
		goto, GoogleHighlight
	} else if (RightLeftAction=20) {
		goto, GoogleClipboard
	} else if (RightLeftAction=21) {
		goto, SpeakIt
	} else if (RightLeftAction=22) {
		goto, SpeakHighlight
	} else if (RightLeftAction=23) {
		goto, SpeakClipboard
	} else if (RightLeftAction=24) {
		goto, MonitorOff
	} else if (RightLeftAction=25) {
		goto, OpenTray
	} else if (RightLeftAction=26) {
		goto, AlwaysOnTop
	} else if (RightLeftAction=27) {
		goto, WebTimer
	} else if (RightLeftAction=28) {
		goto, TimerTab
	} else if (RightLeftAction=29) {
		goto, ZoomFaster
	} else if (RightLeftAction=30) {
		goto, ZoomSlower
	} else if (RightLeftAction=31) {
		hotkeyMod=Right
		goto, ElasticZoom
	} else if (RightLeftAction=32) {				
		hotkeyMod=Right
		goto, ElasticStillZoom
	} else if (RightLeftAction=33) {				
		goto, SnipFree
	} else if (RightLeftAction=34) {				
		goto, SnipRect
	} else if (RightLeftAction=35) {				
		goto, SnipWin
	} else if (RightLeftAction=36) {				
		goto, SnipScreen
	} else if (RightLeftAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (RightLeftAction=38) {				
		goto, showHidePanel	
	} else if (RightLeftAction=39) {
		sendinput ^!{Space}
	} else if (RightLeftAction=40) {
		Run, %CustomRightLeftPath%
	} else {
		return ; this is unneeded
	}
}
return

~RButton & ~MButton::
if not LeftRight
	return
if (RightMiddleAction=41) { ; 41 = None
	return
}
if not paused {
	; *** specially launching zoompad (to prevent back/forward misclikcks) before snipping but be sure to exit it before launching snipping tool
	if (RightMiddleAction<>38 AND RightMiddleAction<>26 AND RightMiddleAction<>18 AND RightMiddleAction<>19 AND RightMiddleAction<>21 AND RightMiddleAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel), speak and google (except 2 clipboard versions) and 'always on top' 
		Gosub, ZoomPad
		if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
			padStayTimeTemp:=padStayTime*2
			Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
		}
	}
	if (RightMiddleAction=1) { 
		Gosub, SnippingTool
	} else if (RightMiddleAction=2) { 
		GoSub, KillMagnifierHK
	} else if (RightMiddleAction=3) { 
		Gosub, ColorHK
	} else if (RightMiddleAction=4) { 
		Gosub, MouseHK
	} else if (RightMiddleAction=5) { 
		Gosub, KeyboardHK
	} else if (RightMiddleAction=6) { 
		Gosub, TextHK
	} else if (RightMiddleAction=7) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewType
	} else if (RightMiddleAction=8) {
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewLiveZoom
	} else if (RightMiddleAction=9) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewStillZoom
	} else if (RightMiddleAction=10) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewDraw
	} else if (RightMiddleAction=11) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBreakTimer
	} else if (RightMiddleAction=12) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewBlackBoard
	} else if (RightMiddleAction=13) { 
		Process, Exist, zoomit.exe
		If not errorlevel
		{
			Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
			return
		}
		IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
			goto, zoomit
		if not zoomItGuidance
			Gosub, ZoomItGuidance
		goto, ViewWhiteBoard
	} else if (RightMiddleAction=14) { 
		goto, notepad
	} else if (RightMiddleAction=15) { 
		goto, wordpad
	} else if (RightMiddleAction=16) { 
		goto, mscalc
	} else if (RightMiddleAction=17) { 
		gosub, mspaint
	} else if (RightMiddleAction=18) {
		goto, Google
	} else if (RightMiddleAction=19) {
		goto, GoogleHighlight
	} else if (RightMiddleAction=20) {
		goto, GoogleClipboard
	} else if (RightMiddleAction=21) {
		goto, SpeakIt
	} else if (RightMiddleAction=22) {
		goto, SpeakHighlight
	} else if (RightMiddleAction=23) {
		goto, SpeakClipboard
	} else if (RightMiddleAction=24) {
		goto, MonitorOff
	} else if (RightMiddleAction=25) {
		goto, OpenTray
	} else if (RightMiddleAction=26) {
		goto, AlwaysOnTop
	} else if (RightMiddleAction=27) {
		goto, WebTimer
	} else if (RightMiddleAction=28) {
		goto, TimerTab
	} else if (RightMiddleAction=29) {
		goto, ZoomFaster
	} else if (RightMiddleAction=30) {
		goto, ZoomSlower
	} else if (RightMiddleAction=31) {
		hotkeyMod=Right
		goto, ElasticZoom
	} else if (RightMiddleAction=32) {				
		hotkeyMod=Right
		goto, ElasticStillZoom
	} else if (RightMiddleAction=33) {				
		goto, SnipFree
	} else if (RightMiddleAction=34) {				
		goto, SnipRect
	} else if (RightMiddleAction=35) {				
		goto, SnipWin
	} else if (RightMiddleAction=36) {				
		goto, SnipScreen
	} else if (RightMiddleAction=37) {				
		Gosub, ShowMagnifierHK ; show hide magnifier
	} else if (RightMiddleAction=38) {				
		goto, showHidePanel
	} else if (RightMiddleAction=39) {
		sendinput ^!{Space}
	} else if (RightMiddleAction=40) {
		Run, %CustomRightMiddlePath%
	} else {
		return ; this is unneeded
	}
}
return

;; Customize Left/Right - END

;; Customize Left/Right Wheelup/down - START


~LButton & ~Wheelup::
if not LeftRight
	return
if (LeftWupAction=37) { ; 37 = None
	return
}
if paused
	return
if (LeftWupAction<>34 AND LeftWupAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (LeftWupAction=1) { 
	Gosub, SnippingTool
} else if (LeftWupAction=2) { 
	GoSub, KillMagnifierHK
} else if (LeftWupAction=3) { 
	Gosub, ColorHK
} else if (LeftWupAction=4) { 
	Gosub, MouseHK
} else if (LeftWupAction=5) { 
	Gosub, KeyboardHK
} else if (LeftWupAction=6) { 
	Gosub, TextHK
} else if (LeftWupAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (LeftWupAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (LeftWupAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (LeftWupAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (LeftWupAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (LeftWupAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (LeftWupAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (LeftWupAction=14) { 
	goto, notepad
} else if (LeftWupAction=15) { 
	goto, wordpad
} else if (LeftWupAction=16) { 
	goto, mscalc
} else if (LeftWupAction=17) { 
	gosub, mspaint
} else if (LeftWupAction=18) { 
	goto, GoogleClipboard
} else if (LeftWupAction=19) { 
	goto, SpeakClipboard
} else if (LeftWupAction=20) { 
	goto, MonitorOff
} else if (LeftWupAction=21) { 
	goto, OpenTray
} else if (LeftWupAction=22) { 
	goto, AlwaysOnTop
} else if (LeftWupAction=23) { 
	goto, WebTimer
} else if (LeftWupAction=24) { 
	goto, TimerTab
} else if (LeftWupAction=25) { 
	goto, ZoomFaster
} else if (LeftWupAction=26) { 
	goto, ZoomSlower
} else if (LeftWupAction=27) {
	hotkeyMod=LButton
	goto, ElasticZoom
} else if (LeftWupAction=28) {				
	hotkeyMod=LButton
	goto, ElasticStillZoom
} else if (LeftWupAction=29) {				
	goto, SnipFree
} else if (LeftWupAction=30) {				
	goto, SnipRect
} else if (LeftWupAction=31) {				
	goto, SnipWin
} else if (LeftWupAction=32) {				
	goto, SnipScreen
} else if (LeftWupAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (LeftWupAction=34) {				
	goto, showHidePanel
} else if (LeftWupAction=35) { 
	sendinput ^!{Space}
} else if (LeftWupAction=36) { 
	Run, %CustomLeftWupPath%
} else {
	return ; this is unneeded
}
return


~LButton & ~Wheeldown::
if not LeftRight
	return
if (LeftWdownAction=37) { ; 37 = None
	return
}
if paused
	return
if (LeftWdownAction<>34 AND LeftWdownAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (LeftWdownAction=1) { 
	Gosub, SnippingTool
} else if (LeftWdownAction=2) { 
	GoSub, KillMagnifierHK
} else if (LeftWdownAction=3) { 
	Gosub, ColorHK
} else if (LeftWdownAction=4) { 
	Gosub, MouseHK
} else if (LeftWdownAction=5) { 
	Gosub, KeyboardHK
} else if (LeftWdownAction=6) { 
	Gosub, TextHK
} else if (LeftWdownAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (LeftWdownAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (LeftWdownAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (LeftWdownAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (LeftWdownAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (LeftWdownAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (LeftWdownAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (LeftWdownAction=14) { 
	goto, notepad
} else if (LeftWdownAction=15) { 
	goto, wordpad
} else if (LeftWdownAction=16) { 
	goto, mscalc
} else if (LeftWdownAction=17) { 
	gosub, mspaint
} else if (LeftWdownAction=18) { 
	goto, GoogleClipboard
} else if (LeftWdownAction=19) { 
	goto, SpeakClipboard
} else if (LeftWdownAction=20) { 
	goto, MonitorOff
} else if (LeftWdownAction=21) { 
	goto, OpenTray
} else if (LeftWdownAction=22) { 
	goto, AlwaysOnTop
} else if (LeftWdownAction=23) { 
	goto, WebTimer
} else if (LeftWdownAction=24) { 
	goto, TimerTab
} else if (LeftWdownAction=25) { 
	goto, ZoomFaster
} else if (LeftWdownAction=26) { 
	goto, ZoomSlower
} else if (LeftWdownAction=27) {
	hotkeyMod=LButton
	goto, ElasticZoom
} else if (LeftWdownAction=28) {				
	hotkeyMod=LButton
	goto, ElasticStillZoom
} else if (LeftWdownAction=29) {				
	goto, SnipFree
} else if (LeftWdownAction=30) {				
	goto, SnipRect
} else if (LeftWdownAction=31) {				
	goto, SnipWin
} else if (LeftWdownAction=32) {				
	goto, SnipScreen
} else if (LeftWdownAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (LeftWdownAction=34) {				
	goto, showHidePanel
} else if (LeftWdownAction=35) { 
	sendinput ^!{Space}
} else if (LeftWdownAction=36) { 
	Run, %CustomLeftWdownPath%
} else {
	return ; this is unneeded
}
return


~RButton & ~Wheelup::
if not LeftRight
	return
if (RightWupAction=37) { ; 37 = None
	return
}
if paused
	return
if (RightWupAction<>34 AND RightWupAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (RightWupAction=1) { 
	Gosub, SnippingTool
} else if (RightWupAction=2) { 
	GoSub, KillMagnifierHK
} else if (RightWupAction=3) { 
	Gosub, ColorHK
} else if (RightWupAction=4) { 
	Gosub, MouseHK
} else if (RightWupAction=5) { 
	Gosub, KeyboardHK
} else if (RightWupAction=6) { 
	Gosub, TextHK
} else if (RightWupAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (RightWupAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (RightWupAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (RightWupAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (RightWupAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (RightWupAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (RightWupAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (RightWupAction=14) { 
	goto, notepad
} else if (RightWupAction=15) { 
	goto, wordpad
} else if (RightWupAction=16) { 
	goto, mscalc
} else if (RightWupAction=17) { 
	gosub, mspaint
} else if (RightWupAction=18) { 
	goto, GoogleClipboard
} else if (RightWupAction=19) { 
	goto, SpeakClipboard
} else if (RightWupAction=20) { 
	goto, MonitorOff
} else if (RightWupAction=21) { 
	goto, OpenTray
} else if (RightWupAction=22) { 
	goto, AlwaysOnTop
} else if (RightWupAction=23) { 
	goto, WebTimer
} else if (RightWupAction=24) { 
	goto, TimerTab
} else if (RightWupAction=25) { 
	goto, ZoomFaster
} else if (RightWupAction=26) { 
	goto, ZoomSlower
} else if (RightWupAction=27) {
	hotkeyMod=RButton
	goto, ElasticZoom
} else if (RightWupAction=28) {				
	hotkeyMod=RButton
	goto, ElasticStillZoom
} else if (RightWupAction=29) {				
	goto, SnipFree
} else if (RightWupAction=30) {				
	goto, SnipRect
} else if (RightWupAction=31) {				
	goto, SnipWin
} else if (RightWupAction=32) {				
	goto, SnipScreen
} else if (RightWupAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (RightWupAction=34) {				
	goto, showHidePanel
} else if (RightWupAction=35) { 
	sendinput ^!{Space}
} else if (RightWupAction=36) { 
	Run, %CustomRightWupPath%
} else {
	return ; this is unneeded
}
return

~RButton & ~Wheeldown::
if not LeftRight
	return
if (RightWdownAction=37) { ; 37 = None
	return
}
if paused
	return
if (RightWdownAction<>34 AND RightWdownAction<>22) { ; dont show zoompad for 'show panel' (as zoompad will misalign the panel) and 'always on top' 
	Gosub, ZoomPad
	if (padTrans>1) { ; no need to wait for zoompad if pad is transparent (ie. 1)
		padStayTimeTemp:=padStayTime*2
		Sleep, %padStayTimeTemp% ; after zoompad finishes, wake up
	}
}
if (RightWdownAction=1) { 
	Gosub, SnippingTool
} else if (RightWdownAction=2) { 
	GoSub, KillMagnifierHK
} else if (RightWdownAction=3) { 
	Gosub, ColorHK
} else if (RightWdownAction=4) { 
	Gosub, MouseHK
} else if (RightWdownAction=5) { 
	Gosub, KeyboardHK
} else if (RightWdownAction=6) { 
	Gosub, TextHK
} else if (RightWdownAction=7) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewType
} else if (RightWdownAction=8) {
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewLiveZoom
} else if (RightWdownAction=9) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewStillZoom
} else if (RightWdownAction=10) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewDraw
} else if (RightWdownAction=11) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBreakTimer
} else if (RightWdownAction=12) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewBlackBoard
} else if (RightWdownAction=13) { 
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	if not zoomItGuidance
		Gosub, ZoomItGuidance
	goto, ViewWhiteBoard
} else if (RightWdownAction=14) { 
	goto, notepad
} else if (RightWdownAction=15) { 
	goto, wordpad
} else if (RightWdownAction=16) { 
	goto, mscalc
} else if (RightWdownAction=17) { 
	gosub, mspaint
} else if (RightWdownAction=18) { 
	goto, GoogleClipboard
} else if (RightWdownAction=19) { 
	goto, SpeakClipboard
} else if (RightWdownAction=20) { 
	goto, MonitorOff
} else if (RightWdownAction=21) { 
	goto, OpenTray
} else if (RightWdownAction=22) { 
	goto, AlwaysOnTop
} else if (RightWdownAction=23) { 
	goto, WebTimer
} else if (RightWdownAction=24) { 
	goto, TimerTab
} else if (RightWdownAction=25) { 
	goto, ZoomFaster
} else if (RightWdownAction=26) { 
	goto, ZoomSlower
} else if (RightWdownAction=27) {
	hotkeyMod=RButton
	goto, ElasticZoom
} else if (RightWdownAction=28) {				
	hotkeyMod=RButton
	goto, ElasticStillZoom
} else if (RightWdownAction=29) {				
	goto, SnipFree
} else if (RightWdownAction=30) {				
	goto, SnipRect
} else if (RightWdownAction=31) {				
	goto, SnipWin
} else if (RightWdownAction=32) {				
	goto, SnipScreen
} else if (RightWdownAction=33) {				
	Gosub, ShowMagnifierHK ; show hide magnifier
} else if (RightWdownAction=34) {				
	goto, showHidePanel
} else if (RightWdownAction=35) { 
	sendinput ^!{Space}
} else if (RightWdownAction=36) {
 	Run, %CustomRightWdownPath%
} else {
	return ; this is unneeded
}
return

;; Customize Left/Right Wheelup/down - END

; --
; Custom Hotkey (Part 2) End
; --

; Show/hide magnifier by Win + Ctrl + ESC
#+`::
goto, ShowMagnifierHK

; Show/hide panel by Win + Shift + ESC
#+ESC::
IfWinExist, AeroZoom Panel
{
	Gui, Destroy
	Menu, Tray, Uncheck, &Show Panel`t[Win+Shift+ESC]
	return
}
;Gui, Destroy
goto, lastPos

; Show/hide panel by tray (center it)
showPanel:
centerPanel = 1
IfWinExist, AeroZoom Panel
{
	Gui, Destroy
	Menu, Tray, Uncheck, &Show Panel`t[Win+Shift+ESC]
	return
}
;Gui, Destroy
goto, lastPos

; Normal way to launch AeroZoom panel (Right-handed)
; ~LButton & RButton::
; goto, showHidePanel

; Normal way to launch AeroZoom panel (Left-handed)
; ~RButton & LButton::
; goto, showHidePanel

showHidePanel:
IfWinExist, AeroZoom Panel
{
	Gui, Destroy
	Menu, Tray, Uncheck, &Show Panel`t[Win+Shift+ESC]
	return
}
goto, lastPos
return


lastPos:

Gui, Destroy ; ensure running Gui is impossible (otherwise strange errors)
Menu, Tray, Check, &Show Panel`t[Win+Shift+ESC]	
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

RegRead,customTypeMsg,HKCU,Software\wandersick\AeroZoom,customTypeMsg
if errorlevel ; if the key is never created, i.e. first-run
{
	customTypeMsg=T&ype ; default value
}
RegRead,customCalcMsg,HKCU,Software\wandersick\AeroZoom,customCalcMsg
if errorlevel ; if the key is never created, i.e. first-run
{
	customCalcMsg=&Calc ; default value
}
RegRead,legacyKill,HKCU,Software\wandersick\AeroZoom,legacyKill
if errorlevel
{
	legacyKill=1 ; 1 = Yes 2 = No (Use Paint)
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, legacyKill, 1
}
if (legacyKill=2) AND !(SnippingToolExists) 
{
	legacyKill=1 ; ensure settings imported work across windows versions
}
;RegRead,legacyKillPrev,HKCU,Software\wandersick\AeroZoom,legacyKill
;if errorlevel
;	legacyKillPrev=1 ; Prev is for Advanced Options
RegRead,keepSnip,HKCU,Software\wandersick\AeroZoom,keepSnip
if errorlevel
	keepSnip=2 ; 1 = Yes 2 = No
RegRead,keepSnipPrev,HKCU,Software\wandersick\AeroZoom,keepSnip
if errorlevel
	keepSnipPrev=2 ; Prev is for Advanced Options
	
startUpChk=1
Gosub, updateMouseTextKB

; ----------------------------------------------------- Left Button Assignment END

; Adds Buttons ; enable ToolWindow to co-exist with AeroShake
Gui, +ToolWindow -MaximizeBox ; Use this instead of disabling Minimize button on Title bar as 'WinMinimize, AeroZoom Panel' requires this to work. (now no longer necessary)

; slider 1: zoom increment

; ----------------------------------------------------- Zoom Increment 2 of 3 (Add to GUI)
; Add a slider for Zoom Increment, the preset level is %zoominc% which was retrieved from registry
; Variable (user-selected increment) is to be stored in ZoomInc(vZoomInc)
; SliderX(gSliderX) is the subroutine to be performened

Gui, Add, Slider, TickInterval1 Range1-6 x12 y3 w120 h24 vZoomInc gSliderX, %zoominc%

If (SwitchSlider<>1 OR zoomitPanel) {
	GuiControl, Disable, ZoomInc
	GuiControl, Hide, ZoomInc
}
; ----------------------------------------------------- Zoom Increment 2 of 3 END

; slider 2: magnification

Gosub, ReadValueUpdatePanel
if (ZoomInc=1) {
	Gui, Add, Slider, x12 y3 w120 h24 Range1-61 vMagnification gSliderMag, %Magnification%
} else if (ZoomInc=2) {
	Gui, Add, Slider, x12 y3 w120 h24 Range1-31 vMagnification gSliderMag, %Magnification%
} else if (ZoomInc=3) {
	Gui, Add, Slider, x12 y3 w120 h24 Range1-16 vMagnification gSliderMag, %Magnification%
} else if (ZoomInc=4) {
	Gui, Add, Slider, x12 y3 w120 h24 Range1-11 vMagnification gSliderMag, %Magnification%
} else if (ZoomInc=5) {
	Gui, Add, Slider, x12 y3 w120 h24 Range1-9 vMagnification gSliderMag, %Magnification%
} else if (ZoomInc=6) {
	Gui, Add, Slider, x12 y3 w120 h24 Range1-5 vMagnification gSliderMag, %Magnification%
}

If (SwitchSlider<>2 OR zoomitPanel) {
	GuiControl, Disable, Magnification
	GuiControl, Hide, Magnification
}

; slider 3: snipping tool snipmode

Gui, Add, Slider, x12 y3 w120 h24 TickInterval1 Range1-4 vSnipMode gSnipBarUpdate, %SnipMode%

If (SwitchSlider<>3 OR zoomitPanel) {
	GuiControl, Disable, SnipMode
	GuiControl, Hide, SnipMode
}

; slider 4: unknown (for xp and vista w/o snipping tool)

If NirCmd
	SnipSlider=2
Else
	SnipSlider=1
	
Gui, Add, Slider, x12 y3 w120 h24 Range1-2 vSnipSlider gCaptureDiskOSD, %SnipSlider%

If (SwitchSlider<>4 OR zoomitPanel) {
	GuiControl, Disable, SnipSlider
	GuiControl, Hide, SnipSlider
}

; slider 5: zoomit color adjustment

Gui, Add, Slider, TickInterval1 Range1-6 x12 y3 w120 h24 vZoomItColor gZoomItColorPreview, %ZoomItColor%
if not zoomitPanel
{
	GuiControl, Disable, ZoomItColor
	GuiControl, Hide, ZoomItColor
}

ZoomInc_TT := "Zoom rate: 25 / 50 / 100 / 150 / 200 / 400"
Magnification_TT := "Magnification: Slide to zoom in/out"
SnipSlider_TT := "Save screen shots to Desktop: (1) Enable / (2) Disable"
SnipMode_TT := "Snip Mode: (1) Free-form / (2) Rectangular / (3) Window / (4) Screen" ; also shared by AeroSnip Options
ZoomItColor_TT := "Pen color: (1) Red / (2) Green / (3) Blue / (4) Yellow / (5) Pink / (6) Orange"

Gui, Add, Text, x0 y0 h452 w16 gUiMove vTxt1, 
if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
	Txt1_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
Else
	Txt1_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
Gui, Add, Text, x125 y0 h452 w16 gUiMove vTxt2, 
if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
	Txt2_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
Else
	Txt2_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
; Gui, Add, Text, x0 y417 h22 w16 gUiMove vTxt3, 
; Txt3_TT := Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
if SwitchMiniMode
{
	Gui, Add, Text, x0 y313 h11 w140 gUiMove vTxt4, 
	if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
		Txt4_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
	Else
		Txt4_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
} else {
	Gui, Add, Text, x0 y397 h5 w140 gUiMove vTxt4, 
	if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
		Txt4_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
	Else
		Txt4_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
}
Gui, Font, s8, Arial
if not (!A_IsAdmin AND EnableLUA AND OSver>6 AND !zoomitPanel) {
	if (OSver>=6.1) OR (OSver<6.1 AND zoomitPanel) {
		Gui, Add, Button, x15 y27 w110 h43 gColor vColor, Color &Inversion
		Color_TT := "Turn on/off color inversion [Win+Alt+I]"
		Gui, Add, Button, x15 y70 w110 h43 gMouse vMouse, &Mouse %MouseCurrent% > %MouseNext%
		Mouse_TT := "Follow the mouse pointer [Win+Alt+M]"
		Gui, Add, Button, x15 y113 w110 h43 gKeyboard vKeyboard, &Keyboard %KeyboardCurrent% > %KeyboardNext%
		Keyboard_TT := "Follow the keyboard focus [Win+Alt+K]"
		Gui, Add, Button, x15 y156 w110 h43 gText vText, Te&xt %TextCurrent% > %TextNext%
		Text_TT := "Have magnifier follow the text insertion point [Win+Alt+T]"
	}
}
;WinGet, chkMin, MinMax, ahk_class MagUIClass
;if (chkMin<0) { ; if magnifier win is minimized, i.e. chkmin = -1
	if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) {
		Gui, Add, Button, x15 y28 w54 h28 gShowMagnifier vShowMagnifier, &Run
		ShowMagnifier_TT := "Run magnifier (if closed)"
	} else {
		if (OSver<6.1 AND !zoomitPanel) {
			Gui, Add, Button, x15 y28 w54 h28 gShowMagnifier vShowMagnifier, &Mag
			ShowMagnifier_TT := "Show/hide magnifier [Win+Shift+``]"
		} else {
			Gui, Add, Button, x15 y201 w54 h28 gShowMagnifier vShowMagnifier, &Mag
			ShowMagnifier_TT := "Show/hide magnifier [Win+Shift+``]"
		}
	}
;} else {
;	Gui, Add, Button, x15 y201 w54 h28 gShowMagnifier vShowMagnifier, &Hide
;}

if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) {
		Gui, Add, Button, x71 y28 w54 h28 gKillMagnifier vKillMagnifier, &Paint
		KillMagnifier_TT := "Create and edit drawings"
} else {
	if (legacyKill=1) {
		If (OSver<6.1 AND !zoomitPanel) {
			Gui, Add, Button, x71 y28 w54 h28 gKillMagnifier vKillMagnifier, Kil&l
			KillMagnifier_TT := "Kill magnifier process [Win+Shift+K]"
		} else {
			Gui, Add, Button, x71 y201 w54 h28 gKillMagnifier vKillMagnifier, Kil&l
			KillMagnifier_TT := "Kill magnifier process [Win+Shift+K]"
		}
	} else {
		If (OSver<6.1 AND !zoomitPanel) {
			Gui, Add, Button, x71 y28 w54 h28 gKillMagnifier vKillMagnifier, &Paint
			KillMagnifier_TT := "Create and edit drawings"
		} else {
			Gui, Add, Button, x71 y201 w54 h28 gKillMagnifier vKillMagnifier, &Paint
			KillMagnifier_TT := "Create and edit drawings"
		}
	}
}

if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) OR (OSver<6.1 AND !zoomitPanel) {
	Gui, Add, Button, x15 y58 w54 h28 gDefault vDefault, &Reset
	Gui, Add, Button, x71 y58 w54 h28 gCalc vCalc, %customCalcMsg%
} else {
	Gui, Add, Button, x15 y231 w54 h28 gDefault vDefault, &Reset
	Gui, Add, Button, x71 y231 w54 h28 gCalc vCalc, %customCalcMsg%
}
Default_TT := "Reset magnifier [Win+Shift+R]"

if not customCalcPath
{
	if (customCalcMsg = "&Calc" OR customCalcMsg = "Calc" OR customCalcMsg = "C&alc" OR customCalcMsg = "Ca&lc" OR customCalcMsg = "Cal&c")
	{
		Calc_TT := "Show calculator" ; show tooltip only if the button is for launching the caluculator, not user-defined
	}
}
if (!A_IsAdmin AND EnableLUA AND OSver>=6.1 AND !zoomitPanel) OR (OSver=6 AND !zoomitPanel) { ;win7 limited or vista;
	If (SnippingToolExists OR (OSver>=6.1 AND (EditionID="Starter" OR EditionID="HomeBasic"))) { ; for win7 starter/hb under limited acc+uac, although snipping tool is unavailable, snip cant change to paint as the kill button has alrdy changed to paint
		Gui, Add, Button, x15 y88 w54 h28 gDraw vDraw, &Snip
		Gui, Add, Button, x71 y88 w54 h28 gType vType, %customTypeMsg%
	} else { ; the below is for vista starter/hb w/o snipping tool
		Gui, Add, Button, x15 y88 w54 h28 gDraw vDraw, &Paint
		Gui, Add, Button, x71 y88 w54 h28 gType vType, %customTypeMsg%
	}
} else if (OSver<6 AND !zoomitPanel) { ; xp
	Gui, Add, Button, x15 y88 w54 h28 gDraw vDraw, &Paint
	Gui, Add, Button, x71 y88 w54 h28 gType vType, %customTypeMsg%
} else { ; if normal
	If SnippingToolExists {
		Gui, Add, Button, x15 y261 w54 h28 gDraw vDraw, &Snip
		Gui, Add, Button, x71 y261 w54 h28 gType vType, %customTypeMsg%
	} else {
		Gui, Add, Button, x15 y261 w54 h28 gDraw vDraw, &Paint
		Gui, Add, Button, x71 y261 w54 h28 gType vType, %customTypeMsg%
	}
}

if (OSver<6 OR EditionID="HomeBasic" OR EditionID="Starter") {
	Draw_TT := "Create and edit drawings"
}
Draw_TT := "Copy a portion of screen for annotation [Win+Alt+F/R/W/S]"


if not customEdPath
{
	if (customTypeMsg = "T&ype" OR customTypeMsg = "Type" OR customTypeMsg = "&Type" OR customTypeMsg = "Ty&pe" OR customTypeMsg = "Typ&e")
	{
		Type_TT := "Input text"
	}
}
; Gui, Add, Button, x71 y214 w54 h28 gHide, &__

Gui, Font, s8, Tahoma
; ----------------------------------------------------- Radio Button 2 of 3 (Add to GUI)
; %chk*% checks last time's value remembered in the registry
if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) OR (OSver<6.1 AND !zoomitPanel) {
	Gui, Font, CDefault, ; to word around a weird bug where all radio texts become red
	Gui, Add, Radio, x22 y144 w38 h20 %chkCtrl% -Wrap vchkMod gModifier, Ctrl
	Gui, Add, Radio, x22 y164 w35 h20 %chkAlt% -Wrap gModifier, Alt
	Gui, Add, Radio, x22 y184 w42 h20 %chkShift% -Wrap gModifier, Shift
	Gui, Add, Radio, x22 y204 w38 h20 %chkWin% -Wrap gModifier, Win
	Gui, Add, Radio, x72 y144 w39 h20 %chkMouseL% -Wrap gModifier, Left
	Gui, Add, Radio, x72 y164 w53 h20 %chkMouseR% -Wrap gModifier, Right
	Gui, Add, Radio, x72 y184 w57 h20 %chkMouseM% -Wrap gModifier, Middle
	Gui, Add, Radio, x72 y204 w26 h20 %chkMouseX1% -Wrap gModifier, F
	Gui, Add, Radio, x100 y204 w26 h20 %chkMouseX2% -Wrap gModifier, B
} else {
	if not SwitchMiniMode
	{
		Gui, Font, CDefault, ; to word around a weird bug where all radio texts become red
		Gui, Add, Radio, %chkCtrl% -Wrap x22 y317 w38 h20 vchkMod gModifier, Ctrl
		Gui, Add, Radio, %chkAlt% -Wrap x22 y337 w35 h20 gModifier, Alt
		Gui, Add, Radio, %chkShift% -Wrap x22 y357 w42 h20 gModifier, Shift
		Gui, Add, Radio, %chkWin% -Wrap x22 y377 w38 h20 gModifier, Win
		Gui, Add, Radio, %chkMouseL% -Wrap x72 y317 w39 h20 gModifier, Left
		Gui, Add, Radio, %chkMouseR% -Wrap x72 y337 w53 h20 gModifier, Right
		Gui, Add, Radio, %chkMouseM% -Wrap x72 y357 w57 h20 gModifier, Middle
		Gui, Add, Radio, %chkMouseX1% -Wrap x72 y377 w26 h20 gModifier, F
		Gui, Add, Radio, %chkMouseX2% -Wrap x100 y377 w26 h20 gModifier, B
		; chkMod_TT := "Modifier keys: Ctrl/Alt/Shift/Winkey; mouse buttons: Left/Right/Middle/Forward/Back"
	}
}
; ----------------------------------------------------- Radio Button 2 of 3 END
Gui, Font, s8, Arial
if paused {
	Gui, Font, s8 Bold, Arial
}
if (paused=1) {
	pausedText = &ms
} else if (paused=2) {
	pausedText = &all
} else {
	pausedText = &off
}

if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) OR (OSver<6.1 AND !zoomitPanel) {
	Gui, Add, Button, x15 y118 w33 h22 gPauseScriptViaButton vPauseScript, %pausedText%
	Gui, Font, s8 Norm, Arial
	if zoomitPanel {
		Gui, Font, s8 Bold, Arial
	}
	Gui, Add, Button, x49 y118 w42 h22 gZoomItPanelViaButton vZoomItButton, &zoom
	Gui, Font, s8 Norm, Arial
	Gui, Add, Button, x92 y118 w33 h22 gBye vBye, &quit
} else {
	Gui, Add, Button, x15 y291 w33 h22 gPauseScriptViaButton vPauseScript, %pausedText%
	Gui, Font, s8 Norm, Arial
	if zoomitPanel {
		Gui, Font, s8 Bold, Arial
	}
	Gui, Add, Button, x49 y291 w42 h22 gZoomItPanelViaButton vZoomItButton, &zoom
	Gui, Font, s8 Norm, Arial
	Gui, Add, Button, x92 y291 w33 h22 gBye vBye, &quit
}
PauseScript_TT := "Turn off mouse/all hotkeys"
;Hide_TT := "Hide/show this panel [Win+Shift+Esc]"
ZoomItButton_TT := "ZoomIt/Windows Magnifier Panel Switch"
Bye_TT := "Quit AeroZoom [Q]"

; Adds Texts
Gui, Font, s10, Tahoma
Gui, Font, c666666
if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) OR (OSver<6.1 AND !zoomitPanel) {
	Gui, Add, Text, x27 y229 w100 h42 vTxt gUiMove, A e r o Z o o m ; v%verAZ%
} else {
	if SwitchMiniMode
	{
		Gui, Add, Text, x27 y324 w100 h42 vTxt gUiMove, A e r o Z o o m ; v%verAZ%
	} else {
		Gui, Add, Text, x27 y402 w100 h42 vTxt gUiMove, A e r o Z o o m ; v%verAZ%
	}
}

	if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
		Txt_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
	Else
		Txt_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
Gui, Font, norm

; Adds Menus
Menu, AboutMenu, Add, Disable Startup &Tips, startupTips
If profileInUse
	Menu, AboutMenu, Disable, Disable Startup &Tips
Menu, AboutMenu, Add, Disable First-Use &Guide, firstUseGuide
If profileInUse
	Menu, AboutMenu, Disable, Disable First-Use &Guide
If not menuInit
	Menu, AboutMenu, Add ; separator
Menu, AboutMenu, Add, &Quick Instructions, Instruction
If not menuInit
	Menu, AboutMenu, Add ; separator
Menu, AboutMenu, Add, &About, HelpAbout
Menu, AboutMenu, Add, &Update, CheckUpdate
If not menuInit
	Menu, AboutMenu, Add ; separator
if registered
	Menu, AboutMenu, Add, &Registration, Donate
; Menu, AboutMenu, Add, &Email a Bug, EmailBugs ; Cancelled due to not universally supported
if not registered
	Menu, AboutMenu, Add, Donate $1, Donate
Menu, AboutMenu, Add, AeroZoom &Web, VisitWeb
Menu, AboutMenu, Add, User Experience &Survey, UserExperienceSurvey

Menu, SnipMenu, Add, Free-form`tWin+Alt+F, SnipFree
Menu, SnipMenu, Add, Rectangular`tWin+Alt+R, SnipRect
Menu, SnipMenu, Add, Window`tWin+Alt+W, SnipWin
Menu, SnipMenu, Add, Screen`tWin+Alt+S, SnipScreen
If not menuInit
	Menu, SnipMenu, Add ; separator
Menu, SnipMenu, Add, AeroSnip Options, CaptureOptions
; Menu, SnipMenu, Add, Snipping Tool Options, SnippingToolOptions

Menu, ZoomitMenu, Add, Still Zoom`tCtrl+1, ViewStillZoom
If (OSver>=6)
	Menu, ZoomitMenu, Add, Live Zoom`tCtrl+4, ViewLiveZoom
Menu, ZoomitMenu, Add, Draw`tCtrl+2, ViewDraw
Menu, ZoomitMenu, Add, Type`tCtrl+2`, T, ViewType
Menu, ZoomitMenu, Add, Break Timer`tCtrl+3, ViewBreakTimer
If not menuInit
	Menu, ZoomitMenu, Add ; separator
Menu, ZoomitMenu, Add, Black Board`tCtrl+2`, K, ViewBlackBoard
Menu, ZoomitMenu, Add, White Board`tCtrl+2`, W, ViewWhiteBoard
If not menuInit
	Menu, ZoomitMenu, Add ; separator
Menu, ZoomitMenu, Add, View Hotkeys`tWin+Alt+Q`, Z, ZoomItInstButton
If not menuInit
	Menu, ZoomitMenu, Add ; separator
Menu, ZoomitMenu, Add, ZoomIt Options, ZoomItOptions

If (OSver>=6) {
	Menu, ViewsMenu, Add, &AeroSnip, :SnipMenu
}
Menu, ViewsMenu, Add, Sysinternals &ZoomIt, :ZoomitMenu
If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
	If not menuInit
		Menu, ViewsMenu, Add ; separator
	Menu, ViewsMenu, Add, &Full Screen`tCtrl+Alt+F, ViewFullScreen
	Menu, ViewsMenu, Add, &Lens`tCtrl+Alt+L, ViewLens
	Menu, ViewsMenu, Add, &Docked`tCtrl+Alt+D, ViewDocked
	If not menuInit
		Menu, ViewsMenu, Add ; separator
	Menu, ViewsMenu, Add, &Preview Full Screen`tCtrl+Alt+Space, ViewPreview
	If not menuInit
		Menu, ViewsMenu, Add ; separator
}
Menu, ViewsMenu, Add, &Windows Magnifier`tWin+Shift+``, ShowMagnifierHK
; Menu, ViewsMenu, Add  ; empty horizontal line (messes up)
; Menu, ViewsMenu, Add  ; empty horizontal line (messes up)

Menu, Configuration, Add, &Import Settings, ImportConfig
Menu, Configuration, Add, &Export Settings, ExportConfig
If not menuInit
	Menu, Configuration, Add ; separator
Menu, Configuration, Add, &Save Config on Exit, ConfigBackup

Menu, FileMenu, Add, &Config File, :Configuration


Menu, QuickProfileSwitch, Add, 1. %profileName1%, QuickProfile1
Menu, QuickProfileSwitch, Add, 2. %profileName2%, QuickProfile2
Menu, QuickProfileSwitch, Add, 3. %profileName3%, QuickProfile3
Menu, QuickProfileSwitch, Add, 4. %profileName4%, QuickProfile4
Menu, QuickProfileSwitch, Add, 5. %profileName5%, QuickProfile5

If not menuInit
	Menu, QuickProfileSwitch, Add ; separator
Menu, QuickProfileSwitch, Add, Disable Quick Profiles, QuickProfileDisable


if (profileInUse=1) {
	Menu, QuickProfileSwitch, Check, 1. %profileName1%
} else if (profileInUse=2) {
	Menu, QuickProfileSwitch, Check, 2. %profileName2%
} else if (profileInUse=3) {
	Menu, QuickProfileSwitch, Check, 3. %profileName3%
} else if (profileInUse=4) {
	Menu, QuickProfileSwitch, Check, 4. %profileName4%
} else if (profileInUse=5) {
	Menu, QuickProfileSwitch, Check, 5. %profileName5%
} else {
	Menu, QuickProfileSwitch, Check, Disable Quick Profiles
	Menu, QuickProfileSwitch, Disable, Disable Quick Profiles
}

Menu, QuickProfileSave, Add, 1. %profileName1%, QuickProfileSave1
Menu, QuickProfileSave, Add, 2. %profileName2%, QuickProfileSave2
Menu, QuickProfileSave, Add, 3. %profileName3%, QuickProfileSave3
Menu, QuickProfileSave, Add, 4. %profileName4%, QuickProfileSave4
Menu, QuickProfileSave, Add, 5. %profileName5%, QuickProfileSave5

Menu, QuickProfileSwitch, Add, Save Current Profile to..., :QuickProfileSave

Menu, QuickProfileRename, Add, 1. %profileName1%, QuickProfileRename1
Menu, QuickProfileRename, Add, 2. %profileName2%, QuickProfileRename2
Menu, QuickProfileRename, Add, 3. %profileName3%, QuickProfileRename3
Menu, QuickProfileRename, Add, 4. %profileName4%, QuickProfileRename4
Menu, QuickProfileRename, Add, 5. %profileName5%, QuickProfileRename5

Menu, QuickProfileSwitch, Add, Rename Profile, :QuickProfileRename

If not menuInit
	Menu, QuickProfileSwitch, Add ; separator
if profileInUse {
	profileInUseDisplay = %profileInUse%
} else {
	profileInUseDisplay = None
}
Menu, QuickProfileSwitch, Add, &Restore Default Settings [Profile: %profileInUseDisplay%], RestoreDefaultSettings

Menu, FileMenu, Add, Quick Profile &Switch, :QuickProfileSwitch
If not menuInit
	Menu, FileMenu, Add ; separator
if (OSver>=6.1) {
		If not (!A_IsAdmin AND EnableLUA)
			Menu, FileMenu, Add, Switch to &Zoom Rate Slider, SwitchSlider
		Menu, FileMenu, Add, Switch to &Magnify Slider, SwitchSlider
	if not zoomitPanel {
		if (SwitchSlider=1) {
			Menu, FileMenu, Check, Switch to &Zoom Rate Slider
		} else if (SwitchSlider=2) {
			Menu, FileMenu, Check, Switch to &Magnify Slider
		}
	}
}

if (OSver>=6) {
	If SnippingToolExists
	{
		Menu, FileMenu, Add, Switch to &AeroSnip Slider, SwitchSlider
		if not zoomitPanel {
			if (SwitchSlider=3) {
				Menu, FileMenu, Check, Switch to &AeroSnip Slider
			}
		}
	}
}

if (OSver<6.1 AND !SnippingToolExists) {
	Menu, FileMenu, Add, Switch to Save-Capture Slider, SwitchSlider
	if not zoomitPanel {
		if (SwitchSlider=4) {
			Menu, FileMenu, Check, Switch to Save-Capture Slider
		}
	}
}

if (!A_IsAdmin AND EnableLUA AND OSver>6.0)
{
	If not menuInit
		Menu, FileMenu, Add ; separator
	Menu, FileMenu, Add, Switch to &Full Functionality Mode, RunAsAdmin
	Menu, FileMenu, Add, Switch off &User Account Control, RunUACoff
}

If not menuInit
	Menu, FileMenu, Add ; separator

if not zoomitPanel {
	Menu, FileMenu, Add, Go to ZoomIt &Panel, ZoomItPanel
} else {
	Menu, FileMenu, Add, Go to Windows Magnifier &Panel, ZoomItPanel
}

if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA)) {
	if SwitchMiniMode
	{
		Menu, FileMenu, Add, &Go to Full View, SwitchMiniMode
	} else {
		Menu, FileMenu, Add, &Go to Mini View, SwitchMiniMode
	}
}

; Menu, FileMenu, Add, &Hide/Show Magnifier`tM, ShowMagnifier
; Menu, FileMenu, Add, &Hide/Show Magnifier`tWin+Shift+``, ShowMagnifier
If not menuInit
	Menu, FileMenu, Add ; separator
If (OSver>=6.0) {
	Menu, FileMenu, Add, &Run on Startup, RunOnStartup
}
Menu, FileMenu, Add, &Install as Current User, Install
If not menuInit
	Menu, FileMenu, Add ; separator
Menu, FileMenu, Add, &Hide Panel`tESC, HideAZ
Menu, FileMenu, Add, &Restart, RestartAZ
Menu, FileMenu, Add, &Quit`tQ, ExitAZ


; MySubmenus
IfExist, %windir%\System32\calc.exe
	Menu, MySubmenu, Add, Calculator, WinCalc
IfExist, %windir%\System32\calc1.exe
	Menu, MySubmenu, Add, Calculator (Alternative), WinCalc1

IfExist, %windir%\System32\cttune.exe
Menu, MySubmenu, Add, ClearType Text Tuner, ctTune
	
IfExist, %windir%\System32\cmd.exe
	Menu, MySubmenu, Add, Command Prompt, WinCMD

If not A_IsAdmin {
	if (OSver>5.9) {
		IfExist, %windir%\System32\cmd.exe
			If not menuInit
				Menu, MySubmenu, Add ; separator
			Menu, MySubmenu, Add, Command Prompt (Admin), WinCmdAdmin
			If not menuInit
				Menu, MySubmenu, Add ; separator
	}
}

IfExist, %windir%\system32\NetProj.exe
	Menu, MySubmenu, Add, Connect to a Network Projector, WinNetworkProjector
	
IfExist, %windir%\system32\displayswitch.exe
	Menu, MySubmenu, Add, Connect to a Projector, WinProjector
	
IfExist, %windir%\System32\control.exe
	Menu, MySubmenu, Add, Control Panel, WinControl
	
if (OSver>5.9) {
	Menu, MySubmenu, Add, Ease of Access Center, easeOfAccess
}

IfExist, %CommonProgramFiles%\Microsoft Shared\Ink\mip.exe
	Menu, MySubmenu, Add, Math Input Panel, WinMath

IfExist, %windir%\system32\narrator.exe
	Menu, MySubmenu, Add, Narrator, WinNarrator
	
IfExist, C:\Windows\System32\notepad.exe
	Menu, MySubmenu, Add, Notepad, WinNote

IfExist, %windir%\System32\osk.exe
	Menu, MySubmenu, Add, On-Screen Keyboard, WinKB

IfExist, %windir%\System32\mspaint.exe
	Menu, MySubmenu, Add, Paint, WinPaint

IfExist, %windir%\System32\psr.exe
	Menu, MySubmenu, Add, Problem Steps Recorder, WinPSR

IfExist, %windir%\system32\rundll32.exe
	Menu, MySubmenu, Add, Run, WinRun



	
IfExist, %SystemRoot%\system32\SoundRecorder.exe
	Menu, MySubmenu, Add, Sound Recorder, WinSound

IfExist, %windir%\system32\StikyNot.exe
	Menu, MySubmenu, Add, Sticky Notes, WinSticky

IfExist, %windir%\System32\taskmgr.exe
	Menu, MySubmenu, Add, Task Manager, WinTask

IfExist, %CommonProgramFiles%\Microsoft Shared\Ink\TabTip.exe
	Menu, MySubmenu, Add, Tablet PC Input Panel, WinTabletInput
	
IfExist, %ProgramFiles%\Windows Journal\Journal.exe
	Menu, MySubmenu, Add, Windows Journel, WinJournel

IfExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
	Menu, MySubmenu, Add, WordPad, WinWord
	
IfNotExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe ; for vista's file virtualization
{
	IfExist, C:\Program Files\Windows NT\Accessories\wordpad.exe
		Menu, MySubmenu, Add, WordPad, WinWord
}
	
IfExist, %windir%\Speech\Common\sapisvr.exe
	Menu, MySubmenu, Add, Windows Speech Recognition, WinSpeech

	If not menuInit
		Menu, MySubMenu, Add ; separator
	Menu, MySubmenu, Add, Lock, LockPC
	Menu, MySubmenu, Add, Sleep, SleepPC
	Menu, MySubmenu, Add, Hibernate, HibernatePC
	Menu, MySubmenu, Add, Reboot, RebootPC
Menu, MySubmenu, Add, Shut down, ShutDownPC



Menu, OptionsMenu, Add, &AeroSnip Options, CaptureOptions

;Menu, OptionsMenu, Add, Snipping Tool, SnippingToolOptions
;Menu, OptionsMenu, Add, ZoomIt Options, zoomitOptions
Menu, OptionsMenu, Add, Advanced Options, AdvancedOptions

If not menuInit
	Menu, OptionsMenu, Add ; separator
Menu, OptionsMenu, Add, Legacy: Click-n-Go Buttons, ClicknGo
If !(OSver<6) AND !(EditionID="HomeBasic" OR EditionID="Starter") AND !(!A_IsAdmin AND EnableLUA AND OSver>6.0) { ; if not xp (Snip Button becomes Paint) AND not vista/win7 home basic/start (Snip button becomes Paint) AND not win7 limited user with UAC on (Kill button is already Paint) ** beware the last case does not contain Kill button while the prev 2 contain
	Menu, OptionsMenu, Add, Legacy: Change Kill to Paint, TogglePaintKill
	If (legacyKill=2)
		Menu, OptionsMenu, Check, Legacy: Change Kill to Paint
	Else
		Menu, OptionsMenu, Uncheck, Legacy: Change Kill to Paint
}
If not menuInit
	Menu, OptionsMenu, Add ; separator
Menu, OptionsMenu, Add, Workaround: Prefer NumpadAdd to +, PreferNumpadAdd
Menu, OptionsMenu, Add, Workaround: Prefer NumpadSub to -, PreferNumpadSub
if (OSver>=6.1)
	Menu, OptionsMenu, Add, Experiment: Center Zoom, MouseCenteredZoomMenu

Menu, MiscToolsMenu, Add, Aero Timer (Web), WebTimer
Menu, MiscToolsMenu, Add, Timer Tab (Web), TimerTab
If not menuInit
	Menu, MiscToolsMenu, Add ; separator
IfExist, %systemdrive%\ChMac\ChMac.bat
	Menu, MiscToolsMenu, Add, ChMac, ChMac
IfExist, %systemdrive%\Cmd Dict\Cmd Dict.bat
	Menu, MiscToolsMenu, Add, Cmd Dict, CmdDict1
IfExist, %systemdrive%\Cmd Dict\Portable.cmd
	Menu, MiscToolsMenu, Add, Cmd Dict, CmdDict2
IfExist, %systemdrive%\ECPP\CommandPromptPortable.exe
	Menu, MiscToolsMenu, Add, ECPP, ECPP1
IfExist, %systemdrive%\ECPP\ECPP.exe
	Menu, MiscToolsMenu, Add, ECPP, ECPP2
Menu, MiscToolsMenu, Add, Eject Disc, OpenTray
Menu, MiscToolsMenu, Add, Monitor Off, MonitorOff
Menu, MiscToolsMenu, Add, Search Clipboard, GoogleClipboard
Menu, MiscToolsMenu, Add, Speak Clipboard, SpeakClipboard
IfExist, %systemdrive%\Total Malware Scanner\Total Malware Scanner.bat
	Menu, MiscToolsMenu, Add, Total Malware Scanner, TMS1
IfExist, %systemdrive%\Total Malware Scanner\Total Malware Scanner.exe
	Menu, MiscToolsMenu, Add, Total Malware Scanner, TMS2

Menu, CustomizeMenu, Add, &Holding Middle, CustomizeMiddle
Menu, CustomizeMenu, Add, &Ctrl/Alt/Shift/Win, CustomizeKeys
Menu, CustomizeMenu, Add, &Forward/Back, CustomizeForwardBack
Menu, CustomizeMenu, Add, &Left/Right, CustomizeLeftRight

Menu, CustomHkMenu, Add, &Settings, :CustomizeMenu
If not menuInit
	Menu, CustomHkMenu, Add ; separator

Menu, CustomHkMenu, Add, &Enable Holding Middle, HoldMiddle
Menu, CustomHkMenu, Add, &Enable Ctrl/Alt/Shift/Win, CtrlAltShiftWin
Menu, CustomHkMenu, Add, &Enable Forward/Back, ForwardBack
Menu, CustomHkMenu, Add, &Enable Left/Right, LeftRight

Menu, ToolboxMenu, Add, &Windows Tools, :MySubmenu
Menu, ToolboxMenu, Add, &Misc Tools, :MiscToolsMenu
If not menuInit
	Menu, ToolboxMenu, Add ; separator

Menu, ToolboxMenu, Add, &Custom Hotkeys, :CustomHkMenu
If not menuInit
	Menu, ToolboxMenu, Add ; separator

Menu, ToolboxMenu, Add, &Preferences (for Experts), :OptionsMenu
If not menuInit
	Menu, ToolboxMenu, Add ; separator

; Menu, ToolboxMenu, Add, &Hold Middle Button to Trigger, HoldMiddle

Menu, ToolboxMenu, Add, &Save Captures, NirCmd
Menu, ToolboxMenu, Add, &Misclick-Preventing Pad, UseZoomPad
Menu, ToolboxMenu, Add, &Type with Notepad, UseNotepad
Menu, ToolboxMenu, Add, &Elastic Zoom, ToggleElasticZoom
Menu, ToolboxMenu, Add, &Always on Top, OnTop
If not menuInit
	Menu, ToolboxMenu, Add ; separator


Menu, ToolboxMenu, Add, &Use ZoomIt as Magnifier, ZoomIt
If (OSver>=6.0) {
	Menu, ToolboxMenu, Add, &Wheel with ZoomIt (Live), ZoomItLive
	Menu, ToolboxMenu, Add, &Wheel with ZoomIt (Still), ZoomitStill
}

Process, Exist, zoomit.exe
If (errorlevel=0) {
	Menu, ViewsMenu, Disable, Sysinternals &ZoomIt
} else {
	Menu, ViewsMenu, Enable, Sysinternals &ZoomIt
}

If (EditionID="HomeBasic" OR EditionID="Starter") {
	Menu, ViewsMenu, Disable, &AeroSnip
}

; Check Click 'n Go bit
RegRead,clickGoBit,HKCU,Software\wandersick\AeroZoom,clickGoBit
if clickGoBit ; if  Click 'n Go bit exists and is not 0
{
	Menu, OptionsMenu, Check, Legacy: Click-n-Go Buttons
	; uses Gui Hide (ie Cancel) instead of Gui Destroy since v3.2b for slightly better performance (cancelled)
	guiDestroy=Destroy
} else { ; else if Click 'n Go bit exists and is 0
	Menu, OptionsMenu, Uncheck, Legacy: Click-n-Go Buttons
	guiDestroy=
}

; Check Mouse-Centered Zoom bit
if (OSver>=6.1) {
	RegRead,mouseCenteredZoomBit,HKCU,Software\wandersick\AeroZoom,mouseCenteredZoomBit
	if mouseCenteredZoomBit ; if Mouse-Centered Zoom bit exists and is not 0
	{
		Menu, OptionsMenu, Check, Experiment: Center Zoom
		; uses Gui Hide (ie Cancel) instead of Gui Destroy since v3.2b for slightly better performance (cancelled)
		guiDestroy=Destroy
	} else { ; else if Mouse-Centered Zoom bit exists and is 0
		Menu, OptionsMenu, Uncheck, Experiment: Center Zoom
		guiDestroy=
	}
}

; Check numPadAddBit and numPadSubBit
; for Windows 10, #+ and #- seem to work better than #{NumpadAdd} and #{NumpadSub}. e.g. avoid - character being generated during zoomout (also for older Windows versions)
RegRead,numPadAddBit,HKCU,Software\wandersick\AeroZoom,numPadAddBit
if numPadAddBit 
{
	Menu, OptionsMenu, Check, Workaround: Prefer NumpadAdd to +
	guiDestroy=Destroy
} else { 
	Menu, OptionsMenu, Uncheck, Workaround: Prefer NumpadAdd to +
	guiDestroy=
}

RegRead,numPadSubBit,HKCU,Software\wandersick\AeroZoom,numPadSubBit
if numPadSubBit 
{
	Menu, OptionsMenu, Check, Workaround: Prefer NumpadSub to -
	guiDestroy=Destroy
} else { 
	Menu, OptionsMenu, Uncheck, Workaround: Prefer NumpadSub to -
	guiDestroy=
}

; Check Always on Top bit
RegRead,onTopBit,HKCU,Software\wandersick\AeroZoom,onTopBit
if errorlevel ; if the key is never created, i.e. first-run
{
	onTopBit=1 ; Always on Top by default
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, onTopBit, 1
}
if onTopBit ; if onTop bit exists and is not 0
{
	Menu, ToolboxMenu, Check, &Always on Top
	onTop=+AlwaysOnTop
} else { ; else if onTop bit exists and is 0
	Menu, ToolboxMenu, Uncheck, &Always on Top
	onTop=-AlwaysOnTop
}
; Set Always On Top
Gui, %onTop%

; Create the menu bar by attaching the sub-menus to it:
Menu, MyBar, Add, &Az, :FileMenu
Menu, MyBar, Add, &Go, :ViewsMenu
Menu, MyBar, Add, &Tool, :ToolboxMenu
Menu, MyBar, Add, &?, :AboutMenu
	
; for separator not to run twice, thrice... (otherwise it appears twice, thrice... in the menu)
menuInit = 1	
	
; update view menu
StartupMagMode=1
Gosub, ReadValueUpdateMenu

; Check if notepad is preferred
if (notepad=1) {
	Menu, ToolboxMenu, Check, &Type with Notepad
}

if (NirCmd=1) {
	Menu, ToolboxMenu, Check, &Save Captures
}

if (EnableAutoBackup=1) {
	Menu, Configuration, Check, &Save Config on Exit
}

If not profileInUse
{
	RegRead,TipDisabled,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,TipDisabled
	if (TipDisabled=1) {
		Menu, AboutMenu, Check, Disable Startup &Tips
	} else {
		Menu, AboutMenu, Uncheck, Disable Startup &Tips
	}
}

if not profileInUse
{
	RegRead,GuideDisabled,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,GuideDisabled
	if (GuideDisabled=1) {
		Menu, AboutMenu, Check, Disable First-Use &Guide
	} else {
		Menu, AboutMenu, Uncheck, Disable First-Use &Guide
	}
}

;if (chkMod=7) { ; if MButton ahk, disable the menu item
;	Menu, ToolboxMenu, Disable, &Hold Middle Button to Trigger
;	Menu, ToolboxMenu, Disable, &Customize Holding Middle
;}

;if (chkMod<8) { ; if not X1 or X2 ahk, disable the menu item
;	Menu, ToolboxMenu, Disable, &Customize Back/Forward
;}

;if (chkMod>4) { ; if not keys ahk, disable the menu item
;	Menu, ToolboxMenu, Disable, &Customize Alt/Ctrl/Shift/Win
;}

RegRead,holdMiddle,HKCU,Software\wandersick\AeroZoom,holdMiddle
If (holdMiddle=1) {
	Menu, CustomHkMenu, Check, &Enable Holding Middle
} Else {
	Menu, CustomHkMenu, Uncheck, &Enable Holding Middle
}

RegRead,CtrlAltShiftWin,HKCU,Software\wandersick\AeroZoom,CtrlAltShiftWin
If (CtrlAltShiftWin=1) {
	Menu, CustomHkMenu, Check, &Enable Ctrl/Alt/Shift/Win
} Else {
	Menu, CustomHkMenu, Uncheck, &Enable Ctrl/Alt/Shift/Win
}

RegRead,ForwardBack,HKCU,Software\wandersick\AeroZoom,ForwardBack
If (ForwardBack=1) {
	Menu, CustomHkMenu, Check, &Enable Forward/Back
} Else {
	Menu, CustomHkMenu, Uncheck, &Enable Forward/Back
}

RegRead,LeftRight,HKCU,Software\wandersick\AeroZoom,LeftRight
If (LeftRight=1) {
	Menu, CustomHkMenu, Check, &Enable Left/Right
} Else {
	Menu, CustomHkMenu, Uncheck, &Enable Left/Right
}


; Check if zoompad is preferred
if (zoomPad=1) {
	Menu, ToolboxMenu, Check, &Misclick-Preventing Pad
}

if (elasticZoom=1) {
	Menu, ToolboxMenu, Check, &Elastic Zoom
}

; Check if AeroZoom is set to run in Startup in the current user startup folder
;IfExist, %A_Startup%\*AeroZoom*.*
;{
;	Menu, FileMenu, Check, &Run on Startup
;}

; Below causes a huge delay in calling the AZ Panel. so now uses Reg key instead
;RunWait, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min ; check if task exist
;if (errorlevel=4) {
	;Menu, FileMenu, Check, &Run on Startup
;}

RegRead,RunOnStartup,HKCU,Software\wandersick\AeroZoom,RunOnStartup
If (RunOnStartup=1) {
	Menu, FileMenu, Check, &Run on Startup
}

; Check if AeroZoom is installed on this computer
IfExist, %localappdata%\wandersick\AeroZoom\AeroZoom.exe
	Menu, FileMenu, Check, &Install as Current User
IfExist, %programfiles%\wandersick\AeroZoom\AeroZoom.exe
	Menu, FileMenu, Check, &Install as Current User
IfExist, %programfiles% (x86)\wandersick\AeroZoom\AeroZoom.exe
	Menu, FileMenu, Check, &Install as Current User

; Check if zoomit.exe is running or zoomit was perferred

if (zoomit=1) {
	Menu, ToolboxMenu, Check, &Use ZoomIt as Magnifier
}

if zoomitPanel {
	if not (KeepSnip=1) { ; if KeepSnip is not checked in the Advanced Options (1 = Yes; 2 = No)
		GuiControl,, Color, Zoom (&Still)
		Color_TT := "ZoomIt: Still zoom [Ctrl+1]"
		GuiControl,, Mouse, Zoom (&Live)
		Mouse_TT := "ZoomIt: Live zoom [Ctrl+2]"
		GuiControl,, Keyboard, Board (&White)
		Keyboard_TT := "ZoomIt: White board [Ctrl+2, W]"
		GuiControl,, Text, Board (&Black)
		Text_TT := "ZoomIt: Black board [Ctrl+2, K]"
		GuiControl,, Calc, &Help
		Calc_TT := "ZoomIt: Hotkey list [Win+Alt+Q, Z]"
		GuiControl,, ShowMagnifier, O&ption
		ShowMagnifier_TT := "ZoomIt: ZoomIt Options"
		GuiControl,, KillMagnifier, Tim&er
		KillMagnifier_TT := "ZoomIt: Break timer [Ctrl+3]"
		GuiControl,, Draw, &Draw ; Change text 'Snip' to 'Draw'	
		Draw_TT := "ZoomIt: Draw [Ctrl+2]"
		GuiControl,, Type, T&ype ; required if user customized it
		Type_TT := "ZoomIt: Type [Ctrl+2, T]"
	}
}

if (zoomitLive) AND (OSver>=6.0) {
	Menu, ToolboxMenu, Check, &Wheel with ZoomIt (Live)
}

if (zoomitStill) AND (OSver>=6.0) {
	Menu, ToolboxMenu, Check, &Wheel with ZoomIt (Still)
}

; if (OSver<6.1) OR !(EditionID="HomeBasic" OR EditionID="Starter")
if (OSver=6) {
	Menu, ToolboxMenu, Disable, &Wheel with ZoomIt (Live)
}

if (OSver<6) OR (OSver=6 AND !SnippingToolExists)
{
	if not zoomitPanel
		Menu, FileMenu, Disable, Switch to Save-Capture Slider ; since this is the only one slider
}

if (OSver=6 AND SnippingToolExists)
{
	if not zoomitPanel
		Menu, FileMenu, Disable, Switch to &AeroSnip Slider ; since this is the only one slider
}

if not A_IsAdmin
{
	; Menu, Configuration, Disable, &Save Config on Exit
	If (OSver>=6) {
		Menu, FileMenu, Disable, &Run on Startup
	}
}

if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
	Menu, FileMenu, Disable, &Run on Startup
}

; Attach the menu bar to the window:
Gui, Menu, MyBar



hIcon32 := DllCall("LoadImage", uint, 0
    , str, "AeroZoom.ico"  ; Icon filename (this file may contain multiple icons).
    , uint, 1  ; Type of image: IMAGE_ICON
    , int, 32, int, 32  ; Desired width and height of image (helps LoadImage decide which icon is best).
    , uint, 0x10)  ; Flags: LR_LOADFROMFILE
Gui +LastFound
SendMessage, 0x80, 1, hIcon32  ; 0x80 is WM_SETICON; and 1 means ICON_BIG (vs. 0 for ICON_SMALL).


; IMPORTANT: Set Title, Window Size and Position
; Gui, Show, h452 w140 x%xPos2% y%yPos2%, `r

if (!A_IsAdmin AND EnableLUA AND OSver>6.0 AND !zoomitPanel) OR (OSver<6.1 AND !zoomitPanel) {
	if centerPanel
	{
		Gui, Show, h263 w140, AeroZoom Panel
		centerPanel=
	} else {
		Gui, Show, h263 w140 x%xPos2% y%yPos2%, AeroZoom Panel
	}
} else {
	if SwitchMiniMode
	{
		if centerPanel
		{
			Gui, Show, h358 w140, AeroZoom Panel
			centerPanel=
		} else {
			Gui, Show, h358 w140 x%xPos2% y%yPos2%, AeroZoom Panel
		}
	} else {
		if centerPanel
		{
			Gui, Show, h436 w140, AeroZoom Panel
			centerPanel=
		} else {
			Gui, Show, h436 w140 x%xPos2% y%yPos2%, AeroZoom Panel
		}
	}
}
OnMessage(0x200, "WM_MOUSEMOVE")

WinSet, Transparent, %panelTrans%, AeroZoom Panel

If (OSver>6.0) {
	; go to subroutines to update the GUI
	Gosub, ReadValueUpdatePanel
}

Loop 6

OnMessage(0x200, "WM_MOUSEMOVE")


if (OSver>6) {
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
	SetTimer, updateMouseTextKB, 500 ; monitor registry for value changes
}

; check double-click on panel
OnMessage(0x203, "WM_LBUTTONDBLCLK")
; double-click on panel - START
WM_LBUTTONDBLCLK()
{
	MouseGetPos,,,,OutputVarControl ; only activate it if users clicks on one of the borders (in order to prevent zoomit from being toggled by double-clicking on button or undesired areas)
	If (OutputVarControl="Static1" OR OutputVarControl="Static2" OR OutputVarControl="Static4")
		gosub, ZoomItPanelViaButton
}
; double-click on panel - END

; check double-middle-click on panel (this is a secret feature)
OnMessage(0x209, "WM_MBUTTONDBLCLK")
; double-middle-click on panel - START
WM_MBUTTONDBLCLK()
{
	gosub, RestartAZ
}
; double-middle-click on panel - END


; check single-click on tray icon - START
; http://www.autohotkey.com/community/viewtopic.php?t=36960 ; thanks to Serenity

OnMessage(0x404, "AHK_NOTIFYICON") ; WM_USER + 4
Return

AHK_NOTIFYICON(wParam, lParam)
{
   Global clickType

   If lParam = 0x201 ; WM_LBUTTONUP
   {
      clickType = 1
      SetTimer, clickChk, -250
      Return 0 
   }
   Else If lParam = 0x203 ; WM_LBUTTONDBLCLK   
   {
      clickType = 2
      Return 0
   }
}

clickChk:
If clickType = 1
{
   gosub, PauseScriptViaTray
}
Else If clickType = 2
{
   gosub, showPanel
}
Return

; check single-click on tray icon - END

ShowMagnifier:
if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If not errorlevel {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	IfWinExist, ZoomIt - Sysinternals: www.sysinternals.com
		WinClose
	Else
		Gosub, zoomitOptions
	Gui, %guiDestroy%
	return
}
Process, Exist, magnify.exe
if errorlevel ; if running, return PID
{
	If (OSver>=6.1) {
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { 
			WinShow, ahk_class MagUIClass
			WinRestore, ahk_class MagUIClass ; the old way WinRestore Magnifier may not work for non-english systems
			; GuiControl,, S&how, &Hide
		} else { ; if magnifier win is normal, chkmin=0; if minimized, chkmin=-1; if maximized, chkmin=1 (not possible for magnifier); if quit, chkmin= (cleared)
			if (hideOrMin=1) {
				WinMinimize, ahk_class MagUIClass
				if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
					WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
			} else {
				WinMinimize, ahk_class MagUIClass
			}
			; GuiControl,, &Hide, S&how
		}
	} else if (OSver=6.0) {
		IfWinExist, ahk_class NativeHWNDHost
		{
			WinGet, chkMin, MinMax, ahk_class NativeHWNDHost
			If (chkmin=-1)
				WinActivate
			Else
				WinMinimize
		}
		Else
		{
			GoSub, CloseMagnifier
			Run, "%windir%\system32\magnify.exe",,
		}
	} else if (OSver<6) {
		;DetectHiddenText, on ; there is no reliable way to detect magnifier in non-en xp
		IfWinExist, Magnifier Settings
		{
			WinGet, chkMin, MinMax, Magnifier Settings
			If (chkmin=-1)
				WinActivate
			Else
				WinMinimize
		}
		Else
		{
			GoSub, CloseMagnifier
			Run, "%windir%\system32\magnify.exe",,
		}
		;DetectHiddenText, off
	}
} else { ; if not running
	gosub, W7HBCantRun2MagMsg
	Run, "%windir%\system32\magnify.exe",,
	; GuiControl,, S&how, &Hide
}
Gui, %guiDestroy%
return

ShowMagnifierHK: ; for HotKey. Difference from above is this does not shows zoomit options when zoomitpanel is on

Process, Exist, magnify.exe
if errorlevel ; if running, return PID
{
	If (OSver>=6.1) {
		WinGet, chkMin, MinMax, ahk_class MagUIClass
		if (chkMin<0) { 
			WinShow, ahk_class MagUIClass
			WinRestore, ahk_class MagUIClass ; the old way WinRestore Magnifier may not work for non-english systems
			; GuiControl,, S&how, &Hide
		} else { ; if magnifier win is normal, chkmin=0; if minimized, chkmin=-1; if maximized, chkmin=1 (not possible for magnifier); if quit, chkmin= (cleared)
			if (hideOrMin=1) {
				WinMinimize, ahk_class MagUIClass
				if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
					WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
			} else {
				WinMinimize, ahk_class MagUIClass
			}
			; GuiControl,, &Hide, S&how
		}
	} else if (OSver=6.0) {
		IfWinExist, ahk_class NativeHWNDHost
		{
			WinGet, chkMin, MinMax, ahk_class NativeHWNDHost
			If (chkmin=-1)
				WinActivate
			Else
				WinMinimize
		}
		Else
		{
			GoSub, CloseMagnifier
			Run, "%windir%\system32\magnify.exe",,
		}
	} else if (OSver<6) {
		;DetectHiddenText, on ; there is no reliable way to detect magnifier in non-en xp
		IfWinExist, Magnifier Settings
		{
			WinGet, chkMin, MinMax, Magnifier Settings
			If (chkmin=-1)
				WinActivate
			Else
				WinMinimize
		}
		Else
		{
			GoSub, CloseMagnifier
			Run, "%windir%\system32\magnify.exe",,
		}
		;DetectHiddenText, off
	}
} else { ; if not running
	gosub, W7HBCantRun2MagMsg
	Run, "%windir%\system32\magnify.exe",,
	; GuiControl,, S&how, &Hide
}
Gui, %guiDestroy%
return

KillMagnifier:
; if enhanced with ZoomIt, this will be the timer button.
if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	IfWinExist, ahk_class MagnifierClass ; if zoomit is working, stop it
	{
		sendinput ^4
		WinWaitClose, ahk_class MagnifierClass, , 3
	}
	IfWinExist, ahk_class ZoomitClass
	{
		WinActivate ; if Timer mode currently activated, send [esc] to close it
		sendinput {esc}
		;GuiControl,, Paus&e, Tim&er
	} else {
		;GuiControl,, Tim&er, Paus&e
		gosub, ViewBreakTimer
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
	; Run, "%windir%\system32\taskkill.exe" /f /im magnify.exe,,Min
	if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
		gosub, mspaint
		Gui, %guiDestroy%
	} else {
		if (legacyKill=1)
		{
			If (OSver>6 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
				If not killGuidance
				{
					if not GuideDisabled
					{
						Msgbox, 262144, This message will only be shown once, 'Reset' is suggested as a replacement for 'Kill' because of its better zoom performance.`n`n'Kill magnifier' is only useful for stopping Docked and Lens view and to work around a bug of Windows Media Center where the cursor is gone while Magnifier is running.`n`nIf you do happen to use Windows Media Center with AeroZoom, consider enabling holding the middle button to kill magnifier in 'Tool > Preferences > Custom Hotkeys > Middle' so that you can bring the cursor back more easily.
						killGuidance = 1
						RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, killGuidance, 1
					}
				}
			}
			GoSub, CloseMagnifier
			 ; GuiControl,, &Hide, S&how
			Gui, %guiDestroy%
		} else {
			; AZ v2 Runs Paint instead of Kill by default (since clicking Mag/Show button again hides it alrdy)
			; AZ v2.1 Runs Kill again to ease users in some unknown cases (e.g. Windows Media Center)
			gosub, mspaint
			Gui, %guiDestroy%
		}
	}
}
return

KillMagnifierHK:
; Run, "%windir%\system32\taskkill.exe" /f /im magnify.exe,,Min
if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
	gosub, mspaint
	Gui, %guiDestroy%
} else {
	if (legacyKill=1)
	{
		If (OSver>6 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
			If not killGuidance
			{
				if not GuideDisabled
				{
					Msgbox, 262144, This message will only be shown once, 'Reset' is suggested as a replacement for 'Kill' because of its better zoom performance.`n`n'Kill magnifier' is only useful for stopping Docked and Lens view and to work around a bug of Windows Media Center where the cursor is gone while Magnifier is running.`n`nIf you do happen to use Windows Media Center with AeroZoom, consider enabling holding the middle button to kill magnifier in 'Tool > Preferences > Custom Hotkeys > Middle' so that you can bring the cursor back more easily.
					killGuidance = 1
					RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, killGuidance, 1
				}
			}
		}
		GoSub, CloseMagnifier
		 ; GuiControl,, &Hide, S&how
		Gui, %guiDestroy%
	} else {
		; AZ v2 Runs Paint instead of Kill by default (since clicking Mag/Show button again hides it alrdy)
		; AZ v2.1 Runs Kill again to ease users in some unknown cases (e.g. Windows Media Center)
		gosub, mspaint
		Gui, %guiDestroy%
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
IfWinExist, ahk_class MagnifierClass ; if zoomit is working, enhance (stop) it instead
{
	sendinput ^4
	return
}
IfWinExist, ahk_class ZoomitClass
{
	sendinput {esc}
	return
}
if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
	RegRead,limitedacc4,HKCU,Software\wandersick\AeroZoom,limitedacc4
	if errorlevel
	{
		if not GuideDisabled
		{
			msgbox,262208,This message will only be shown once,Before doing a reset under limited mode with UAC in Windows, locate Magnifier first and close it manually before clicking the Reset button. Magnifier will then run automatically.`n`nThe reset hotkey [Win]+[Shift]+[R] works the same way. (Manually close Magnifier first.)
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, limitedacc4, 1
		}
	}
}

; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
MagExists=

;RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Magnify, ShowWarning, 0x0

Process, Exist, magnify.exe
If errorlevel
{
	MagExists=1 ; only run magnifier later if exists
	if (OSver>6) {
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
	}
} else {
	hideOrMinLast= ; if not defined, use default settings
}

GoSub, CloseMagnifier
If (OSver>=6.1) {
	IfWinExist, AeroZoom Panel
	{
		If (SwitchSlider=2)
			GuiControl,, Magnification, 1
		If (SwitchSlider=1)
			GuiControl,, ZoomInc, 3
	}
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
} else If (OSver=6) {
	RegDelete, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier
} else If (OSver<6) {
	RegDelete, HKEY_CURRENT_USER, Software\Microsoft\Magnify
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Magnify, ShowWarning, 0x0
}
sleep, %delayButton%
If MagExists
	Run, "%windir%\system32\magnify.exe",,Min ; run magnifier only if it existed
MagExists=
; GuiControl,, &Hide, S&how
Gui, %guiDestroy%

Gosub, MagWinRestore
return

Calc:
if zoomitPanel {
	Gosub, ZoomItInstButton
	Gui, %guiDestroy%
	return
}
if customCalcCheckbox
{
	if customCalcPath
	{
		Run, %CustomCalcPath%
		Gui, %guiDestroy%
		return
	}
}
gosub, mscalc
Gui, %guiDestroy%
return

Draw:
if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	gosub, viewDraw
} else {
	If (OSver>=6.1 AND (EditionID="Starter" OR EditionID="HomeBasic")) { ; for win7 starter/hb under limited acc+uac, although snipping tool is unavailable, snip cant change to paint as the kill button has alrdy changed to paint
		Gui, %guiDestroy%
		Gosub, SnippingTool
		return
	}
	if (OSver<6 OR EditionID="HomeBasic" OR EditionID="Starter") {
		Gosub, MSPaint
	} else {
		Gosub, SnippingTool
	}
}
Gui, %guiDestroy%
return


; RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, ZoomItTimerTip, 1

Type:
if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	gosub, viewType
	Gui, %guiDestroy%
	return
}
if customEdCheckbox
{
	if customEdPath
	{
		Run, %CustomEdPath%
		Gui, %guiDestroy%
		return
	}
}
if (notepad=1) {
	gosub, notepad
} else {
	gosub, wordpad
}
Gui, %guiDestroy%
return

Color:
if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	gosub, ViewStillZoom
	Gui, %guiDestroy%
	return
}
Process, Exist, magnify.exe
if errorlevel 
	magRunning = 1
else
	magRunning =

; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
if (OSver>6) {
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
}
	
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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

Gosub, MagWinRestore
Return

ColorHK:
Process, Exist, magnify.exe
if errorlevel 
	magRunning = 1
else
	magRunning =

; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
if (OSver>6) {
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
}
	
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,Invert
if (magnifierSetting=0x1) {
	if not magRunning ; if mag exe is not running BUT magnifierSetting is set to inverted, that means user's screen color is NOT inverted atm and he wants to INVERT it INSTEAD OF what clicking this button is supposed to do -- turning magnifierSetting to off (which uninverts it), simply run mag exe again would already invert the color.
	{
		goto, ColorSkipHK
	}
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x1
}
sleep, %delayButton%
ColorSkipHK:
Run,"%windir%\system32\magnify.exe",,Min
Gui, %guiDestroy%

Gosub, MagWinRestore
Return

Mouse:
if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	gosub, ViewLiveZoom
	Gui, %guiDestroy%
	return
}

Gosub, MagWinBeforeRestore

if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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


Gosub, MagWinRestore
if not zoomitPanel ; to prevent panel button being updated externally by hotkeys (win+alt+m)
	GuiControl,,Mouse,&Mouse %MouseCurrent% > %MouseNext%
Return

MouseHK:

Gosub, MagWinBeforeRestore
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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


Gosub, MagWinRestore
if not zoomitPanel ; to prevent panel button being updated externally by hotkeys (win+alt+m)
	GuiControl,,Mouse,&Mouse %MouseCurrent% > %MouseNext%
Return

Keyboard:


if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	gosub, ViewWhiteBoard
	Gui, %guiDestroy%
	return
}

RegRead,magnifierSetting,HKCU,Software\Microsoft\ScreenMagnifier,FollowFocus
if (magnifierSetting<>0x1 AND zoompad) {
	RegRead,kbPadMsg,HKCU,Software\wandersick\AeroZoom,kbPadMsg
	if errorlevel
	{
		if not GuideDisabled
		{
			Msgbox, 262208, This message will only be shown once, 'Keyboard (i.e. Follow the keyboard focus)' and 'Misclick-preventing Pad' may cause zoom problems if enabled together.`n`nA workaround is to use 'Text (Follow text insertion point)' instead.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, kbPadMsg, 1
		}
	}
}

Gosub, MagWinBeforeRestore
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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


Gosub, MagWinRestore
if not zoomitPanel ; to prevent panel button being updated externally by hotkeys (win+alt+k)
	GuiControl,,Keyboard,&Keyboard %KeyboardCurrent% > %KeyboardNext%
Return

KeyboardHK:

Gosub, MagWinBeforeRestore
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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


Gosub, MagWinRestore
if not zoomitPanel ; to prevent panel button being updated externally by hotkeys (win+alt+k)
	GuiControl,,Keyboard,&Keyboard %KeyboardCurrent% > %KeyboardNext%
Return

Text:

if zoomitPanel {
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	Process, Exist, zoomit.exe
	If (errorlevel=0) {
		Run, "%A_WorkingDir%\Data\ZoomIt.exe"
		Sleep,1750
	}
	gosub, ViewBlackBoard
	Gui, %guiDestroy%
	return
}

Gosub, MagWinBeforeRestore
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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



Gosub, MagWinRestore
if not zoomitPanel ; to prevent panel button being updated externally by hotkeys (win+alt+t)
	GuiControl,,Text,Te&xt %TextCurrent% > %TextNext%
Return

TextHK:

Gosub, MagWinBeforeRestore
if (OSver>=6.2)
	Big4Buttons=1 ; needed on windows 8 for this function to work
GoSub, CloseMagnifier
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



Gosub, MagWinRestore
if not zoomitPanel ; to prevent panel button being updated externally by hotkeys (win+alt+t)
	GuiControl,,Text,Te&xt %TextCurrent% > %TextNext%
Return

PauseScriptOld:
if not paused {
	paused = 1
	Gui, Font, s8 Bold, Arial
	GuiControl,,PauseScript,&off
	GuiControl, Font, PauseScript
	Menu, Tray, Check, Pause &Mouse Hotkeys`t[Win+Alt+H]
} else {
	paused =
	Gui, Font, s8 Norm, Arial
	GuiControl,,PauseScript,&off
	GuiControl, Font, PauseScript
	Menu, Tray, Uncheck, Pause &Mouse Hotkeys`t[Win+Alt+H]
}
Gui, Font, s10 Norm, Tahoma
Gui, %guiDestroy%
return

; prevent toggling to "Pause All Hotkeys", while selecting "Pause Mouse Hotkeys" from tray.
PauseScriptViaTrayPauseMouseOnly:
PauseScriptViaTrayPauseMouseOnly = 1
goto, PauseScriptViaTray

PauseScriptViaButton:
RegRead,PauseScriptViaButtonInfo,HKCU,Software\wandersick\AeroZoom,PauseScriptViaButtonInfo
if errorlevel
{
	if not GuideDisabled
		Msgbox, 262192, This message will only be shown once, Same as left-clicking the tray icon, this button disables AeroZoom hotkeys (for temporarily switching to apps incompatible with AeroZoom -- hope you don't ever need this.)`n`nIt toggles 3 modes.`n`n1) - OFF - all hotkeys are enabled (default)`n`n2) - MS - only mouse hotkeys are disabled (except Left+Right for bringing back AeroZoom Panel)`n`n3) - ALL - all hotkeys are disabled (WARNING -- the only way to bring back AeroZoom is thru the tray icon)
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, PauseScriptViaButtonInfo, 1

PauseScriptViaTray:
If (OSD=1) {
	If not PauseScriptViaTrayPauseMouseOnly {
		if not paused {
			Run, "%A_WorkingDir%\Data\OSD.exe" Off1
		} else if (paused=1) {
			Run, "%A_WorkingDir%\Data\OSD.exe" Off2
		} else if (paused=2) {
			Run, "%A_WorkingDir%\Data\OSD.exe" Off
		}
	}
}

PauseScript:
if not paused {
	paused = 1
	Gui, Font, s8 Bold, Arial
	GuiControl,,PauseScript,&ms
	GuiControl, Font, PauseScript
	Menu, Tray, Check, Pause &Mouse Hotkeys`t[Win+Alt+H]
	Menu, Tray, Uncheck, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom_Pause.ico, ,1
	Suspend, off
	If (OSD=1)
		Run, "%A_WorkingDir%\Data\OSD.exe" Off1
} else if (paused=1) AND (!PauseScriptViaTrayPauseMouseOnly) {
	paused = 2
	Gui, Font, s8 Bold, Arial
	GuiControl,,PauseScript,&all
	GuiControl, Font, PauseScript
	Menu, Tray, Uncheck, Pause &Mouse Hotkeys`t[Win+Alt+H]
	Menu, Tray, Check, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom_Suspend.ico, ,1
	Suspend, on
	If (OSD=1)	
		Run, "%A_WorkingDir%\Data\OSD.exe" Off2
} else {
	paused =
	Gui, Font, s8 Norm, Arial
	GuiControl,,PauseScript,&off
	GuiControl, Font, PauseScript
	Menu, Tray, Uncheck, Pause &Mouse Hotkeys`t[Win+Alt+H]
	Menu, Tray, Uncheck, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom.ico, ,1
	Suspend, off
	If (OSD=1)
		Run, "%A_WorkingDir%\Data\OSD.exe" Off
}
Gui, Font, s10 Norm, Tahoma
Gui, %guiDestroy%
PauseScriptViaTrayPauseMouseOnly = 
return

PauseScriptViaHotkey:
if not paused {
	paused = 1
	Gui, Font, s8 Bold, Arial
	GuiControl,,PauseScript,&ms
	GuiControl, Font, PauseScript
	Menu, Tray, Check, Pause &Mouse Hotkeys`t[Win+Alt+H]
	Menu, Tray, Uncheck, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom_Pause.ico, ,1
	Suspend, off
	If (OSD=1)
		Run, "%A_WorkingDir%\Data\OSD.exe" Off1
} else {
	paused =
	Gui, Font, s8 Norm, Arial
	GuiControl,,PauseScript,&off
	GuiControl, Font, PauseScript
	Menu, Tray, Uncheck, Pause &Mouse Hotkeys`t[Win+Alt+H]
	Menu, Tray, Uncheck, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Icon, %A_WorkingDir%\Data\AeroZoom.ico, ,1
	Suspend, off
	If (OSD=1)
		Run, "%A_WorkingDir%\Data\OSD.exe" Off
}
Gui, Font, s10 Norm, Tahoma
Gui, %guiDestroy%
return

SuspendScript:
suspend
If A_IsSuspended
{
	Menu, Tray, Check, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Uncheck, Pause &Mouse Hotkeys`t[Win+Alt+H]
	paused = 2
	IfWinExist, AeroZoom Panel
	{
		Gui, Font, s8 Bold, Arial
		GuiControl,,PauseScript,&all
		GuiControl, Font, PauseScript
	}
}
Else
{
	Menu, Tray, Uncheck, &Pause All Hotkeys`t[Click tray icon]
	Menu, Tray, Uncheck, Pause &Mouse Hotkeys`t[Win+Alt+H]
	paused = 
	IfWinExist, AeroZoom Panel
	{
		Gui, Font, s8 Norm, Arial
		GuiControl,,PauseScript,&off
		GuiControl, Font, PauseScript
	}
}
return

;Hide:
HideAZ:
GuiEscape:    ; On ESC press
GuiClose:   ; On "Close" button press
Gui, Destroy
return

Bye:
ExitAZ:
GoSub, CloseMagnifier
GoSub, AutoConfigBackupSaveProfile
ExitApp
return

RestartAZ:
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
Gosub, SaveCurrentProfile
reload
return

Instruction:
if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
	RegRead,limitedAcc3,HKCU,Software\wandersick\AeroZoom,limitedAcc3
	if errorlevel
	{
		if not GuideDisabled
		{
			Msgbox, 262208, This message will only be shown once, You are using the limited functionality mode. Some unavailable hotkeys are not shown.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, limitedAcc3, 1
		}
	}
	goto, InstructionLimited
} else if (OSver<6.1) {
	RegRead,VistaMsg2,HKCU,Software\wandersick\AeroZoom,VistaMsg2
	if errorlevel
	{
		if not GuideDisabled
		{
			Msgbox, 262208, This message will only be shown once, You are using an older version of Windows. Some unavailable hotkeys are not shown.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, VistaMsg2, 1
		}
	}
	goto, InstructionVista ; also for xp
}
IfWinExist, AeroZoom Panel
{
	Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
	Gui, 1:+Disabled  ; Disable main window.
}
Gui, 2:+ToolWindow
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Global Keyboard Shortcuts (Windows)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Elastic zoom live|still`t   [Ctrl] or [Shift] + [Caps Lock]`nFull scr|lens|docked`t   [Ctrl] + [Alt] + [F] / [L] / [D]`nPreview full screen`t   [Ctrl] + [Alt] + [Space]`nZoom rate`t`t   [Win] + [Alt] + [F1 to F6]`nInvert|mouse|key|text`t   [Win] + [Alt] + [I] / [M] / [K] / [T]`n`nZoom in|out`t`t   [Win] + [+ or -]`nReset zoom`t`t   [Win] + [Shift] + [-]`nReset|kill magnifier`t   [Win] + [Shift] + [R] / [K]`nShow|hide magnifier`t   [Win] + [Shift] + [``]`nShow|hide panel`t   [Win] + [Shift] + [Esc]`n`nAeroSnip modes`t   [Win] + [Alt] + [F] / [R] / [W] / [S]`nHotkey-mouse on|off`t   [Win] + [Alt] + [H]`nHotkey-all on|off`t   (Click tray icon)`nQuick help`t`t   [Win] + [Alt] + [Q]
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Modifier (User-defined Mouse Button)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Zoom in|out`t`t   [Modifier] + [Wheel-up/down]`nZoom reset`t`t   [Modifier] + [Middle]`nShow|hide panel`t   [Left] + [Right]`nPreview full screen`t   hold [Middle]  *when zoomed in`nNew snip|custom`t   hold [Middle]  *when zoomed out
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, , Note:`tIn 'middle mode', hold [Mid] + [Right] to reset`n`tzoom, [Mid] + [Left] to snip/preview.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Font, CRed, 
Gui, 2:Add, Text, , Now: %modDisp%
Gui, 1:Font, CDefault, 
Gui, 2:Font, s10, Arial, 
Gui, 2:Font, norm, 
Gui, 2:Add, Button, x184 y455 h30 w56 vExtraInstTemp gExtraInstButton, &Custom
ExtraInstTemp_TT := "Extra Instructions for Back/Forward Mouse Button"
Gui, 2:Add, Button, x240 y455 h30 w56 vZoomItInstTemp gZoomItInstButton, &ZoomIt
ZoomItInstTemp_TT := "ZoomIt Default Hotkeys"
Gui, 2:Add, Button, x296 y455 h30 w56 Default vOKtemp1, &OK
OKtemp1_TT := "Click to close"
Gui, 2:Show, w361 h492 , Quick Instructions
return

InstructionLimited: ; no kill, only run mag (no hide), no reset zoom. 
IfWinExist, AeroZoom Panel
{
	Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
	Gui, 1:+Disabled  ; Disable main window.
}
Gui, 2:+ToolWindow
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Global Keyboard Shortcuts (Limited)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Elastic zoom live|still`t   [Ctrl] or [Shift] + [Caps Lock]`nFull scr|lens|docked`t   [Ctrl] + [Alt] + [F] / [L] / [D]`nPreview full screen`t   [Ctrl] + [Alt] + [Space]`nZoom rate`t`t   [Win] + [Alt] + [F1 to F6]`nInvert|mouse|key|text`t   [Win] + [Alt] + [I] / [M] / [K] / [T]`n`nZoom in|out`t`t   [Win] + [+ or -]`nReset magnifier`t   [Win] + [Shift] + [R]  *close mag first`nRun magnifier`t`t   [Win] + [Shift] + [``]`nShow|hide panel`t   [Win] + [Shift] + [Esc]`n`nAeroSnip modes`t   [Win] + [Alt] + [F] / [R] / [W] / [S]`nHotkey-mouse on|off`t   [Win] + [Alt] + [H]`nHotkey-all on|off`t   (Click tray icon)`nQuick help`t`t   [Win] + [Alt] + [Q]
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Modifier (User-defined Mouse Button)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Zoom in|out`t`t   [Modifier] + [Wheel-up/down]`nShow|hide panel`t   [Left] + [Right]`nPreview full screen`t   hold [Middle]  *when zoomed in`nNew snip|custom`t   hold [Middle]  *when zoomed out
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, , Note:`tIn 'middle mode', hold [Middle] and press [Left]`n`tto snip/preview.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Font, CRed, 
Gui, 2:Add, Text, , Now: %modDisp%
Gui, 1:Font, CDefault, 
Gui, 2:Font, s10, Arial, 
Gui, 2:Font, norm, 
Gui, 2:Add, Button, x184 y425 h30 w56 vExtraInstTemp gExtraInstButton, &Custom
ExtraInstTemp_TT := "Extra Instructions for Back/Forward Mouse Button"
Gui, 2:Add, Button, x240 y425 h30 w56 vZoomItInstTemp gZoomItInstButton, &ZoomIt
ZoomItInstTemp_TT := "ZoomIt Default Hotkeys"
Gui, 2:Add, Button, x296 y425 h30 w56 Default vOKtemp1, &OK
OKtemp1_TT := "Click to close"
Gui, 2:Show, w361 h462 , Quick Instructions
return

InstructionVista: ; also for xp
IfWinExist, AeroZoom Panel
{
	Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
	Gui, 1:+Disabled  ; Disable main window.
}
Gui, 2:+ToolWindow
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Global Keyboard Shortcuts (Vista and XP)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Elastic zoom`t`t   [Ctrl] + [Caps Lock]  *Vista + Aero`nElastic zoom (still)`t   [Shift] + [Caps Lock]`n`nZoom in|out`t`t   [Win] + [+ or -]`nReset zoom`t`t   [Win] + [Shift] + [-]`nReset|kill magnifier`t   [Win] + [Shift] + [R] / [K]`nShow|hide magnifier`t   [Win] + [Shift] + [``]`nShow|hide panel`t   [Win] + [Shift] + [Esc]`n`nAeroSnip modes`t   [Win] + [Alt] + [F] / [R] / [W] / [S]  *Vista`nHotkey-mouse on|off`t   [Win] + [Alt] + [H]`nHotkey-all on|off`t   (Click tray icon)`nQuick help`t`t   [Win] + [Alt] + [Q]
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Add, Text, , Modifier (User-defined Mouse Button)
Gui, 2:Font, s9, Arial, 
Gui, 2:Add, Text, , Zoom in|out`t`t   [Modifier] + [Wheel-up/down]`nReset zoom`t`t   [Modifier] + [Middle]`nShow|hide panel`t   [Left] + [Right]`nNew snip|custom`t   hold [Middle]  *when zoomed out
Gui, 2:Font, s10, Arial, 
Gui, 2:Add, Text, , Note:`tIn 'middle mode', hold [Mid] + [Right] to reset`n`tzoom, [Mid] + [Left] to snip/still-zoom.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Font, CRed, 
Gui, 2:Add, Text, , Now: %modDisp%
Gui, 1:Font, CDefault, 
Gui, 2:Font, s10, Arial, 
Gui, 2:Font, norm, 
Gui, 2:Add, Button, x184 y395 h30 w56 vExtraInstTemp gExtraInstButton, &Custom
ExtraInstTemp_TT := "Extra Instructions for Back/Forward Mouse Button"
Gui, 2:Add, Button, x240 y395 h30 w56 vZoomItInstTemp gZoomItInstButton, &ZoomIt
ZoomItInstTemp_TT := "ZoomIt Default Hotkeys"
Gui, 2:Add, Button, x296 y395 h30 w56 Default vOKtemp1, &OK
OKtemp1_TT := "Click to close"
Gui, 2:Show, w361 h434 , Quick Instructions
return

CheckUpdate:
Gui, 1:Font, CRed, 
GuiControl,1:Font,Txt,
GuiControl,1:,Txt,- Please Wait -
; Gui, 1:-AlwaysOnTop   ; To let the update check popup message show on top after checking, which is done thru batch and VBScript.
; "" (escape char) avoids cmd to interpret folders with reserved char
Run, "%comspec%" /c ""%A_WorkingDir%\Data\_updateCheck.bat"" /quiet, ,Min
WinWait, Update Check,,30
WinSet, AlwaysOnTop, on, Update Check
WinWaitClose, Update Check,,30
;If onTopBit
;	Gui, 1:+AlwaysOnTop
Gui, 1:Font, c666666
GuiControl,1:Font,Txt,
GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
WinActivate
Return

Donate:
if registered
	MsgBox,262144,Licensed to, User: %regName%`n`nLicense: %regType%
else
	Run, http://wandersick.blogspot.com/p/donate.html
return

VisitWeb:
Run, http://wandersick.blogspot.com/p/aerozoom-for-windows-7-magnifier.html
return

UserExperienceSurvey:
Run, http://tinyurl.com/aerozoomsurvey
return

Gmail:
Run, mailto:wandersick+aerozoom@gmail.com
return

Tweet:
Run, www.twitter.com/wandersick
return

HelpAbout:
if (OSver<6.1) OR (EditionID="HomeBasic" OR EditionID="Starter") OR (!A_IsAdmin AND EnableLUA AND OSver>6.0) { ; limited mode means anything that is not win 7 home prem or above
	goto, HelpAboutLimited
}
IfWinExist, AeroZoom Panel
{
	Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
	Gui +Disabled  ; Disable main window.
}
Gui, 2:+ToolWindow
Gui, 2:Font, s12, Arial bold, 
Gui, 2:Add, Text, , AeroZoom %verAZ%
; Gui, 2:Font, norm,
Gui, 2:Font, s10, Tahoma, 
Gui, 2:Add, Text, ,The wheel zoom and presentation kit?`nBetter Magnifier, Snipping Tool and ZoomIt?`nJust thought the idea's neat, so I created It.`n`nAeroZoom is open-source and free.`nCrafted with AutoHotkey by a HKer/Chinese.`n`nJust love life if you enjoy this,`nor donate to me or any cause you please.
Gui, 2:Font, s10, Tahoma,
Gui, 2:Add, Text, ,If you have words for me, bitter or sweet,`nsend wandersick via Gmail or a tweet.
Gui, 2:Font, s10, Tahoma, 
Gui, 2:Font, norm,
; Gui, 2:Add, Button, x34 y254 h30 w60 vDonatetemp2, &Donate
; Donatetemp2_TT := "Donate to support AeroZoom"
Gui, 2:Add, Button, x94 y254 h30 w60 vContacttemp2, &Contact
Contacttemp2_TT := "Methods to contact AeroZoom's creator for support"
Gui, 2:Add, Button, x154 y254 h30 w60 vReadmetemp2, &Readme
Readmetemp2_TT := "View Readme"
Gui, 2:Add, Button, x214 y254 h30 w60 Default vOKtemp2, &OK
OKtemp2_TT := "Click to close"
Gui, 2:Show, w282 h291, About
return

HelpAboutLimited:
Gui, 2:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui +Disabled  ; Disable main window.
Gui, 2:+ToolWindow
Gui, 2:Font, s12, Arial bold, 
Gui, 2:Add, Text, , AeroZoom %verAZ%
; Gui, 2:Font, norm,
Gui, 2:Font, s10, Tahoma, 
Gui, 2:Add, Text, ,The wheel zoom and presentation kit?`nBetter Magnifier, Snipping Tool and ZoomIt?`nJust thought the idea's neat, so I created It.`n`nAeroZoom is open-source and free.`nCrafted with AutoHotkey by a Chinese.`n`nJust love life if you enjoy this,`nor donate to me or any cause you please.
Gui, 2:Font, s10, Tahoma,
Gui, 2:Add, Text, ,If you have words for me, bitter or sweet,`nsend wandersick via Gmail or a tweet.
Gui, 2:Font, s10, Arial bold, 
Gui, 2:Font, CRed, 
Gui, 2:Add, Text, ,AeroZoom is working in limited mode.
Gui, 2:Font, CDefault, 
Gui, 2:Font, s10 Norm, Tahoma
; Gui, 2:Add, Button, x34 y289 h30 w60 vDonatetemp2, &Donate
; Donatetemp2_TT := "Donate to support AeroZoom"
Gui, 2:Add, Button, x94 y289 h30 w60 vContacttemp2, &Contact
Contacttemp2_TT := "Methods to contact AeroZoom's creator"
Gui, 2:Add, Button, x154 y289 h30 w60 vReadmetemp2, &Readme
Readmetemp2_TT := "View Readme"
Gui, 2:Add, Button, x214 y289 h30 w60 Default vOKtemp2, &OK
OKtemp2_TT := "Click to close"
Gui, 2:Show, w282 h325, About
return

ZoomItInstButton:
Msgbox, 262144, Default Hotkeys of Sysinternals ZoomIt, Operation Modes`n - Still-zoom : Ctrl+1 (Works across all Windows versions, including XP)`n - Draw : Ctrl+2`n - Break timer : Ctrl+3`n - Live zoom : Ctrl+4 (Incl. Win 7 Starter/Home Basic and all Vista editions)`n`nStill-zoom`n - Zoom in/out : Wheel up/down or arrow keys`n - Enter draw mode : Left click or press any draw mode key`n - Enter text mode : T`n`nDraw`n - Change color : R (Red) G (Green) B (Blue) Y (Yellow) P (Pink) O (Orange)`n - Undo an edit : Ctrl+Z`n - Erase all : E`n - Black board : K`n - White board : W`n - Straight line : hold Shift and drag`n - Straight arrow : hold Ctrl+Shift and drag`n - Rectangle : hold Ctrl and drag`n - Ellipse : hold Tab and drag`n - Center cursor : Space Bar`n - Undo : Ctrl+Z`n - Print screen : Ctrl+C`n - Save to disk : Ctrl+S`n - Enter zoom mode : Wheel up/down or arrow keys`n - Enter text mode : T`n`nBreak Timer`n - Increase/decrease time : Wheel up/down or arrow keys`n`nTo change the font size in text mode : Wheel up/down or arrow keys`nTo exit a sub mode or ZoomIt : Right click or Esc (Never use Alt+F4)
return

ExtraInstButton:
Msgbox, 262144, Custom Hotkeys (Experimental), Before we begin, do you know what a modifier is?`n`nA modifier is a button like Ctrl, Alt, Shift, Win, that we hold before pressing another button to access another feature. Before AeroZoom 2.0, the modifiers supported were only Left and Right mouse buttons. Now, besides using the new modifiers (Ctrl, Alt, Win, Shift, Back, Forward, Middle) for zoom, AeroZoom also makes more customizable hotkeys out of them. Let's take a look!`n`n1. 'Holding middle button' as a hotkey to automatically switch between 'New snip'/'Preview full screen' (for Windows 7).`n`n2. Sixteen hotkeys made using modifier keys [Ctrl/Alt/Win/Shift] and [Left/Right/Wheel-up/Wheel-down mouse button].`n`n3. Eight hotkeys out of Back and Forward buttons (if your mouse has one).`n`n4. Eight hotkeys out of Left and Right mouse buttons.`n`nBy default, all hotkeys except 'Holding Middle' are disabled. To customize them, go to 'Tool > Preferences > Custom Hotkeys', where built-in functions such as these less-known ones: Speak, Google, Eject CD, Timer, Monitor Off, Always On Top or any command or program can be specified.`n`nNote 1: If you are currently using the modifier for zoom, the relevant hotkeys won't be available for editing (greyed out).`n`nNote 2: If AeroZoom is working in Limited mode (go to '? > About' to see), some internal functions may not work.
return

2ButtonDonate:
Gui 1:-Disabled
Gui, Destroy
Run, http://wandersick.blogspot.com/p/donate.html
return

2ButtonContact:
Gui, 5:+owner2  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui 2:+Disabled  ; Disable parent window.
Gui, 5:+ToolWindow
Gui, 5:Font, s12, Arial bold, 
Gui, 5:Add, Text, , Contact Wandersick
Gui, 5:Font, norm,
Gui, 5:Font, s10, Tahoma
Gui, 5:Add, Text, ,(1) Blog  (2) Email 
Gui, 5:Font, underline
Gui, 5:Add, Text, cBlue gVisitWeb vBlogTemp, http://wandersick.blogspot.com
BlogTemp_TT := "Visit Wandersick's blog"
;Gui, 5:Add, Text, cBlue gTweet vTweetTemp, http://twitter.com/wandersick
;TweetTemp_TT := "Visit Wandersick's Twitter"
Gui, 5:Add, Text, cBlue gGmail vGmailTemp, wandersick@gmail.com
GmailTemp_TT := "Email Wandersick"
Gui, 5:Font, norm
Gui, 5:Add, Text, ,Feel free to send usage questions.
Gui, 5:Add, Button, x213 y169 h30 w60 Default vOKtemp5, &OK
OKtemp5_TT := "Click to close"
Gui, 5:Show, w282 h206 , Support
return

5ButtonOK:  ; This section is used by the "about box" above.
5GuiClose:   ; On "Close" button press
5GuiEscape:   ; On ESC press
Gui, 2:-Disabled  ; Re-enable the parent window (must be done prior to the next step).
Gui, Destroy  ; Destroy the box.
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
RegRead,hideOrMin,HKCU,Software\wandersick\AeroZoom,HideOrMin
if errorlevel
{
	HideOrMin=1
	if (OSver>=6.2)
		HideOrMin=2 ; In Windows 8, Magnifier cannot be closed gracefully when hidden (a graceful close is required for the big 4 buttons and zoominc to work.)
}
; hide (1) or minimize (2) or do neither (3)

; some of the following should be unneeded.

RegRead,keepSnip,HKCU,Software\wandersick\AeroZoom,keepSnip
if errorlevel
{
	keepSnip=2
}

;RegRead,legacyKill,HKCU,Software\wandersick\AeroZoom,legacyKill
;if errorlevel
;{
;	legacyKill=1
;}

; padtrans and padborders are read at the start of script
RegRead,padX,HKCU,Software\wandersick\AeroZoom,padX
if errorlevel
{
	padX=235
}
RegRead,padY,HKCU,Software\wandersick\AeroZoom,padY
if errorlevel
{
	padY=240
}
RegRead,padH,HKCU,Software\wandersick\AeroZoom,padH
if errorlevel
{
	padH=475
}
RegRead,padW,HKCU,Software\wandersick\AeroZoom,padW
if errorlevel
{
	padW=475
}
RegRead,padStayTime,HKCU,Software\wandersick\AeroZoom,padStayTime
if errorlevel
{
	padStayTime=150
}
RegRead,panelX,HKCU,Software\wandersick\AeroZoom,panelX
if errorlevel
{
	panelX=15
}
RegRead,panelY,HKCU,Software\wandersick\AeroZoom,panelY
if errorlevel
{
	panelY=160
}
RegRead,panelTrans,HKCU,Software\wandersick\AeroZoom,panelTrans
if errorlevel
{
	panelTrans=255
}
;Unnecessary
;RegRead,stillZoomDelay,HKCU,Software\wandersick\AeroZoom,stillZoomDelay
;if errorlevel
;{
;	stillZoomDelay=800
;}

RegRead,delayButton,HKCU,Software\wandersick\AeroZoom,delayButton
if errorlevel
{
	delayButton=100
}

RegRead,customEdCheckbox,HKCU,Software\wandersick\AeroZoom,customEdCheckbox
RegRead,customEdPath,HKCU,Software\wandersick\AeroZoom,customEdPath
RegRead,customCalcCheckbox,HKCU,Software\wandersick\AeroZoom,customCalcCheckbox
RegRead,customCalcPath,HKCU,Software\wandersick\AeroZoom,customCalcPath
Gui, 3:+owner1  ; Make the main window (Gui #1) the owner of the "about box" (Gui #2).
Gui, 1:+Disabled
;Gui, 3:-MinimizeBox -MaximizeBox 
Gui, 3:+ToolWindow
Gui, 3:Add, Text, x0 y0 h617 w11 gUiMove vDrag1, 
if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
	Drag1_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
Else
	Drag1_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
Gui, 3:Add, Text, x193 y0 h617 w16 gUiMove vDrag2, 
if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
	Drag2_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
Else
	Drag2_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart
Gui, 3:Add, Text, x0 y0 h12 w210 gUiMove vDrag3, 
if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
	Drag3_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nRight-click for Mini/Full view switch`nDouble-middle-click to restart
Else
	Drag3_TT = Click to drag`nDouble-click for ZoomIt/Magnifier Panel switch`nDouble-middle-click to restart

Gui, 3:Font, s8, Tahoma
Gui, 3:Add, Edit, x132 y320 w50 h20 +Center +Limit3 -Multi +Number -WantTab -WantReturn vPadTransTemp,
PadTransTemp_TT := "Misclick-Preventing Pad: 1-255 (less-more transparent). Default: 1 (For the best performance, do not change this.)"
Gui, 3:Add, UpDown, x164 y320 w18 h20 vPadTrans Range1-255, %padTrans%
PadTrans_TT := "Misclick-Preventing Pad: 1-255 (less-more transparent). Default: 1 (For the best performance, do not change this.)"

Gui, 3:Add, Edit, x72 y320 w50 h20 +Center +Limit3 -Multi +Number -WantTab -WantReturn vPanelTransTemp, 
PanelTransTemp_TT := "AeroZoom Panel: 120 min (more transparent), 255 max (less transparent). Default: 255"
Gui, 3:Add, UpDown, x104 y320 w18 h20 vPanelTrans Range120-255, %panelTrans%
PanelTrans_TT := "AeroZoom Panel: 120 min (more transparent), 255 max (less transparent). Default: 255"

;if CheckboxRestoreDefault ; if Restore Default checkbox was checked
;{
;	Checked=Checked1
;}
;else
;{
;	Checked=Checked0
;}

;Gui, 3:Font, CRed, 
;Gui, 3:Add, CheckBox, %Checked% -Wrap x22 y540 w150 h20 vCheckboxRestoreDefault, &Restore default settings
;Gui, 3:Font, CDefault, 
;CheckboxRestoreDefault_TT := "Restore settings of AeroZoom, Windows Magnifier, ZoomIt and Snipping Tools to their defaults"

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
Gui, 3:Add, CheckBox, %Checked% -Wrap x22 y70 w150 h20 gCustomCalcCheckbox vCustomCalcCheckbox , Define C&alc function
CustomCalcCheckbox_TT := "Specify a program to override the default calculator"
Gui, 3:Add, Edit, %CheckboxDisable% x22 y92 w110 h20 -Multi -WantTab -WantReturn vCustomCalcPath, %customCalcPath%
CustomCalcPath_TT := "Specify a program to override the default calculator"
Gui, 3:Add, Button, %CheckboxDisable% x132 y91 w50 h22 vCustomCalcBrowse g3ButtonBrowse2, &Browse
CustomCalcBrowse_TT := "Browse for an executable"

; Gui, 3:Add, Text, x15 y108 w160 h20 +Left, Manual offset/size adjustment
Gui, 3:Add, Text, x72 y180 w50 h20 +Center, Panel
Gui, 3:Add, Text, x132 y180 w50 h20 +Center, Pad
Gui, 3:Add, Text, x22 y204 w50 h20 , Offset X
Gui, 3:Add, Text, x22 y234 w50 h20 , Offset Y
Gui, 3:Add, Text, x22 y264 w50 h20 , Width
Gui, 3:Add, Text, x22 y294 w50 h20 , Height

Gui, 3:Add, Edit, x72 y200 w50 h20 +Center +Limit6 -Multi -WantTab -WantReturn vPanelXtemp,
PanelXtemp_TT := "AeroZoom Panel: horizontal offset. Default: 15 px"
Gui, 3:Add, UpDown, x104 y200 w18 h20 vPanelX Range-9999-9999, %panelX%
PanelX_TT := "AeroZoom Panel: horizontal offset. Default: 15 px"

Gui, 3:Add, Edit, x72 y230 w50 h20 +Center +Limit6 -Multi -WantTab -WantReturn vPanelYtemp, 
PanelYtemp_TT := "AeroZoom Panel: vertical offset. Default: 160 px"
Gui, 3:Add, UpDown, x104 y230 w18 h20 vPanelY Range-9999-9999, %panelY%
PanelY_TT := "AeroZoom Panel: vertical offset. Default: 160 px"

Gui, 3:Add, Edit, x132 y200 w50 h20 +Center +Limit6 -Multi -WantTab -WantReturn vPadXtemp, 
PadXtemp_TT := "Misclick-Preventing Pad: horizontal offset. Default: 235 px"
Gui, 3:Add, UpDown, x164 y200 w18 h20 vPadX Range-9999-9999, %padX%
PadX_TT := "Misclick-Preventing Pad: horizontal offset. Default: 235 px"

Gui, 3:Add, Edit, x132 y230 w50 h20 +Center +Limit6 -Multi -WantTab -WantReturn vPadYtemp, 
PadYtemp_TT := "Misclick-Preventing Pad: vertical offset. Default: 240 px"
Gui, 3:Add, UpDown, x164 y230 w18 h20 vPadY Range-9999-9999, %padY%
PadY_TT := "Misclick-Preventing Pad: vertical offset. Default: 240 px"

Gui, 3:Add, Edit, x132 y260 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadWtemp, 
PadWtemp_TT := "Misclick-Preventing Pad: horizontal width. Default: 475 px"
Gui, 3:Add, UpDown, x164 y260 w18 h20 vPadW Range0-9999, %padW%
PadW_TT := "Misclick-Preventing Pad: horizontal width. Default: 475 px"

Gui, 3:Add, Edit, x132 y290 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadHtemp, 
PadHtemp_TT := "Misclick-Preventing Pad: vertical height. Default: 475 px"
Gui, 3:Add, UpDown, x164 y290 w18 h20 vPadH Range0-9999, %padH%
PadH_TT := "Misclick-Preventing Pad: vertical height. Default: 475 px"

Gui, 3:Add, Button, x12 y565 w60 h30 vOKtemp3, &OK
OKtemp3_TT := "Save changes"
Gui, 3:Add, Button, x132 y565 w60 h30 vResetTemp, &Reset
ResetTemp_TT := "Restore settings of AeroZoom, Windows Magnifier, ZoomIt and Snipping Tools to their defaults"
Gui, 3:Add, Button, x72 y565 w60 h30 Default vCancelTemp, &Cancel
CancelTemp_TT := "Cancel changes"


Gui, 3:Add, Text, x22 y322 w50 h20 , Transp.
Gui, 3:Add, Text, x72 y120 w50 h20 +Center, Calc
Gui, 3:Add, Text, x132 y120 w50 h20 +Center, Type
Gui, 3:Add, Text, x22 y122 w50 h20 , Label
Gui, 3:Add, Edit, x72 y120 w50 h20 +Center +Limit8 -Multi -WantTab -WantReturn vCustomCalcMsg, %customCalcMsg%
CustomCalcMsg_TT := "Change text label of Calc here (where the character after & is the Alt keyboard shortcut)"
Gui, 3:Add, Edit, x132 y120 w50 h20 +Center +Limit8 -Multi -WantTab -WantReturn vCustomTypeMsg, %customTypeMsg%
CustomTypeMsg_TT := "Change text label of Type here (where the character after & is the Alt keyboard shortcut)"

Gui, 3:Add, GroupBox, x12 y160 w180 h250 , Position / Fine-tuning
Gui, 3:Add, GroupBox, x12 y10 w180 h140 , Buttons

;Gui, 3:Add, Edit, x132 y350 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vStillZoomDelayTemp, 
;StillZoomDelayTemp_TT := "How long holding [Middle] button triggers snip/preview. Default: 800 ms (Require program restart)"
;Gui, 3:Add, UpDown, x164 y350 w18 h20 vStillZoomDelay Range0-9999, %stillZoomDelay%

Gui, 3:Font, CRed, 
Gui, 3:Add, Text, x22 y482 w110 h20 , Operation delay
Gui, 3:Font, CDefault, 
Gui, 3:Add, Edit, x132 y480 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vdelayButtonTemp, 
delayButtonTemp_TT := "Sleep time between each operation. Too low may cause some functions to fail. Default: 100 ms"
Gui, 3:Add, UpDown, x164 y480 w18 h20 vDelayButton Range0-9999, %delayButton%

Gui, 3:Add, Text, x22 y352 w100 h20 , Stay time
Gui, 3:Add, Edit, x132 y350 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vPadStayingTimeTemp, 
PadStayingTimeTemp_TT := "How long the misclick-preventing pad stays. Default: 150 (The larger the longer)"
Gui, 3:Add, UpDown, x164 y350 w18 h20 vPadStayTime Range0-9999, %padStayTime%

Gui, 3:Add, Text, x22 y383 w100 h20 , Borders
Gui, 3:Add, DropDownList, x132 y380 w50 h21 R2 +AltSubmit vPadBorder Choose%PadBorder%, Yes|No
PadBorder_TT := "Frame the misclick-preventing pad? Default: No"

;Gui, 3:Font, Bold s8, Tahoma
Gui, 3:Add, Text, x22 y423 w100 h20, On-screen display
Gui, 3:Add, DropDownList, x132 y420 w50 h20 R2 +AltSubmit vOSD Choose%OSD%, Yes|No
OSD_TT := "Shows on-screen display while using slider. Default: Yes."
;Gui, 3:Font, Norm s8, Tahoma
; Gui, 3:Add, Text, x22 y423 w100 h20, Switch buttons*
; Gui, 3:Add, DropDownList, x132 y420 w50 h20 R2 +AltSubmit vKeepSnip Choose%KeepSnip%, No|Yes
; KeepSnip_TT := "Switch [Snip] and [Kill] to [Draw] and [Timer] buttons when ZoomIt is on. Default: Yes. (*Require program restart)"

;Gui, 3:Add, DropDownList, x132 y450 w50 h20 R2 +AltSubmit vLegacyKill Choose%LegacyKill%, No|Yes
;LegacyKill_TT := "Replace [Kill] with [Paint] ('Switch buttons' must be 'No' if ZoomIt is used.) Default: No. (*Require program restart)"
;Gui, 3:Add, Text, x22 y483 w100 h20 , Paint*

Gui, 3:Add, Text, x22 y453 w100 h20 , Magnifier*
if (OSver>=6.2)
{
	Gui, 3:Add, DropDownList, x132 y450 w50 h20 R3 +AltSubmit vHideOrMin Choose%hideOrMin%, -NA-|Min|Show ; On Windows 8, don't suggest using hide because the command to gracefully exit AZ requires magnifier not to be hidden
	HideOrMin_TT := "Minimize/Show the floating Magnifier window. Default: Minimize (*Require program restart)"
}
Else
{
	Gui, 3:Add, DropDownList, x132 y450 w50 h20 R3 +AltSubmit vHideOrMin Choose%hideOrMin%, Hide|Min|Show
	HideOrMin_TT := "Hide/Minimize/Show the floating Magnifier window. Default: Hide (*Require program restart)"
}

if RunMagOnStart ; if checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}
Gui, 3:Add, CheckBox, %Checked% -Wrap x22 y533 w170 h30 vRunMagOnStart, Run &Magnifier on AZ start
RunMagOnStart_TT := "Run Magnifier as soon as AeroZoom starts (for better performance). Default: Checked"

Gui, 3:Add, Text, x22 y510 w90 h20 , Search engine
Gui, 3:Add, Edit, x112 y510 w70 h20 +Center -Multi -WantTab -WantReturn vGoogleUrl, %GoogleUrl%
GoogleUrl_TT := "Search engine to use, e.g. google.hk, hk.bing.com. Default: google.com"
; Generated using SmartGUI Creator 4.0
Gui, 3:Show, h604 w203, Advanced Options

if (!A_IsAdmin AND EnableLUA AND OSver>6.0) OR (OSver<6.1) ; only apply if non-admin and UAC is on and Win7
{
	GuiControl, 3:Disable, HideOrMin
}

If (OSver<6.1 OR EditionID="Starter" OR EditionID="HomeBasic") {
	GuiControl, 3:Disable, RunMagOnStart
}
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
Msgbox, 262180, AeroZoom Restoration, AeroZoom and Windows Magnifier settings will be restored to their defaults.`n`nEverything will be lost. Are you sure?
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
		If !(OSver<6) {
			Run, "%A_WorkingDir%\Data\AeroZoom_Task.bat" /deltask,"%A_WorkingDir%\",min ; del task
		}
		RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 0
		RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom
		; restore all profiles to their default settings
		Msgbox, 262180, AeroZoom Restoration, Remove other Quick Profiles besides the current one?
		IfMsgBox Yes
		{
			FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile1.reg, %A_WorkingDir%\Data\QuickProfiles\Profile1.reg, 1
			FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile2.reg, %A_WorkingDir%\Data\QuickProfiles\Profile2.reg, 1
			FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile3.reg, %A_WorkingDir%\Data\QuickProfiles\Profile3.reg, 1
			FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile4.reg, %A_WorkingDir%\Data\QuickProfiles\Profile4.reg, 1
			FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile5.reg, %A_WorkingDir%\Data\QuickProfiles\Profile5.reg, 1
		} else {
			FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile%profileInUse%.reg, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg, 1
			Gosub, LoadDefaultRegImportQuickProfile
		}
		GoSub, CloseMagnifier
		If (OSver>6) {
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Magnification, 0x64
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, Invert, 0x0
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowCaret, 0x0
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowFocus, 0x0
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, FollowMouse, 0x1
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, MagnificationMode, 0x2
		} else if (OSver=6) {
			RegDelete, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier
		} else If (OSver<6) {
			RegDelete, HKEY_CURRENT_USER, Software\Microsoft\Magnify
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Magnify, ShowWarning, 0x0
		}
		Process, Close, zoomit.exe
		Process, Close, zoomit64.exe
		If SnippingToolExists
		{
			Msgbox, 262180, AeroZoom Restoration, Restore Snipping Tool settings to defaults?
			IfMsgBox Yes
			{
				Process, Close, SnippingTool.exe
				Sleep, 50
				RegDelete, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool
			}
		}
		IfExist, %A_WorkingDir%\Data\ZoomIt.exe
		{
			Msgbox, 262180, AeroZoom Restoration, Also delete ZoomIt and reset ZoomIt's hotkeys?
			IfMsgBox Yes
			{
				Sleep, 50
				FileDelete, %A_WorkingDir%\Data\ZoomIt.exe
				FileDelete, %A_WorkingDir%\Data\ZoomIt64.exe
				RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, DrawToggleKey
				RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, BreakTimerKey
				RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, ToggleKey
				RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, LiveZoomToggleKey
				RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, EulaAccepted ; force user to reaccept EULA
			}
		}
		IfExist, %A_WorkingDir%\Data\NirCmd.exe
		{
			Msgbox, 262180, AeroZoom Restoration, Also delete NirCmd?
			IfMsgBox Yes
			{
				Sleep, 50
				FileDelete, %A_WorkingDir%\Data\NirCmd.exe
			}
		}
		Msgbox, 262208, Settings Restored, AeroZoom will now quit.
		ExitApp
		; Save last AZ window position before exit so that it shows the GUI after restart
		; WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
		; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		; reload
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
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padTrans, %padTrans%
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padX, %padX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padY, %padY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padH, %padH%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padW, %padW%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padBorder, %padBorder%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, padStayTime, %padStayTime%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, panelX, %panelX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, panelY, %panelY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, panelTrans, %panelTrans%
WinSet, Transparent, %panelTrans%, AeroZoom Panel
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, OSD, %OSD%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RunMagOnStart, %RunMagOnStart%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, GoogleUrl, %GoogleUrl%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customEdCheckbox, %customEdCheckbox%
if customEdPath 
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customEdPath, %customEdPath%
	Type_TT := ""
} else {
	; if user cleared any custom editor path, even when the checkbox is checked, it gets unchecked
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customEdCheckbox
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customEdPath
}
if customEdCheckbox
{
	; If custom editor is selected, deselect UseNotepad
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Notepad
	Menu, ToolboxMenu, Uncheck, &Type with Notepad
	notepad=0
}

RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customCalcCheckbox, %customCalcCheckbox%
if customCalcPath 
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customCalcPath, %customCalcPath%
	Calc_TT := ""
} else {
	; if user cleared any custom editor path, even when the checkbox is checked, it gets unchecked
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customCalcCheckbox
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customCalcPath
}

if (customCalcMsg <> "&Calc")
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customCalcMsg, %customCalcMsg%
	GuiControl,1:,Calc,%customCalcMsg%
}
if (customTypeMsg <> "T&ype")
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customTypeMsg, %customTypeMsg%
	GuiControl,1:,Type,%customTypeMsg%
}
if (hideOrMin<>hideOrMinPrev) { ; note hideOrMinPrev is differernt from hideOrMinLast
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, hideOrMin, %hideOrMin%
	restartRequired=1
}
if (HideOrMin=1)
{	
	if (OSver>=6.2)
	{
		HideOrMin=2 ; In Windows 8, Magnifier cannot be closed gracefully when hidden (a graceful close is required for the big 4 buttons and zoominc to work.)
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, hideOrMin, %hideOrMin%
	}
}

;if (keepSnip<>keepSnipPrev) { 
;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, keepSnip, %keepSnip%
;	restartRequired=1
;}
;if (legacyKill<>legacyKillPrev) { 
;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, legacyKill, %legacyKill%
;	restartRequired=1
;}
;now handled in CustomizeMiddle:
;if (stillZoomDelay <> stillZoomDelayPrev) { ; if value changed
;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, stillZoomDelay, %stillZoomDelay%
;	restartRequired=1
;}

;if (delayButton <> delayButtonPrev) { ; if value changed
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, delayButton, %delayButton%
;	restartRequired=1
;}

if restartRequired {
	Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
	; Save last AZ window position before exit so that it shows the GUI after restart
	WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
	GoSub, CloseMagnifier
	restartRequired=
	Gosub, SaveCurrentProfile
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
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x1
	; Run the user-selected modifier version of AeroZoom
	; chkModRaw<>chkMod to prevent re-running the same instance
	; if (chkModRaw<>chkMod) {
	; v2.1 UPDATE: now cancelled. rerunning the same modifier instance is allowed, to workaround
	; a very rare bug? where zoom stopped working suddenly, by clicking the radio button.
		; Save last AZ window position before exit (restarting AeroZoom is required as changing
		; modifier key means switching executables)
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Ctrl_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Ctrl.exe",,
		ExitApp
	;}
} else if (chkMod=2) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x2
	; if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Alt_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Alt.exe",,
		ExitApp
	;}
} else if (chkMod=3) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x3
	; if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Shift_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Shift.exe",,
		ExitApp
	;}
} else if (chkMod=4) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x4
	; if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_Win_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_Win.exe",,
		ExitApp
	;}
} else if (chkMod=5) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x5
	; if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL_x64.exe",,
		Else		
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL.exe",,
		ExitApp
	;}
} else if (chkMod=6) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x6
	; if (chkModRaw<>chkMod) {
		; Switching to right-handed mode. Hold right+left mouse buttons to bring up panel.
		RegRead,RButton,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,RButton
		if (RButton<>1) {  ; check if message was shown before
			if not GuideDisabled
			{
				Msgbox, 262144, This message will not be shown next time, This is for left-handed users to zoom holding the [Right] mouse button.
				RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RButton, 1
			}
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseR_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseR.exe",,
		ExitApp
	;}
} else if (chkMod=7) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x7
	; if (chkModRaw<>chkMod) {
		RegRead,MButton,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,MButton
		if (MButton<>1) {  ; check if message was shown before
			if not GuideDisabled
			{	
				Msgbox, 262144, This message will not be shown next time, Only one button is required to zoom in this mode.`n`nWhen [Middle] button is pressed and held *down*, scroll up/down to zoom.`n`nTo reset zoom, while holding [Middle], press [Right].`nTo snip/preview full screen (for Windows 7), while holding [Middle], press [Left].`n`nNext time you can read this message by pressing [Win]+[Alt]+[Q] anytime, or at '? > Quick Instructions'
				RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, MButton, 1
			}
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseM_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseM.exe",,
		ExitApp
	;}
} else if (chkMod=8) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x8
	; if (chkModRaw<>chkMod) {
		RegRead,X1,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,X1
		if (X1<>1) {  ; check if message was shown before
			if not GuideDisabled
			{
				Msgbox, 262144, This message will not be shown next time, This is for mouse devices with a [Forward] button.`n`nIf you mouse has a Back or Forward button, AeroZoom creates 8 more hotkeys out of those buttons to do more, e.g. these less known built-in functions: Speak, Google, Eject Disc, Timer, Monitor Off, Always On Top or running any command or program.`n`nCustomize the hotkeys at 'Tool > Preferences > Custom Hotkeys > Forward/Back'.
				RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, X1, 1
			}
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX1_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX1.exe",,
		ExitApp
	;}
} else if (chkMod=9) {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x9
	; if (chkModRaw<>chkMod) {
		RegRead,X2,HKEY_CURRENT_USER,Software\wandersick\AeroZoom,X2
		if (X2<>1) {  ; check if message was shown before
			if not GuideDisabled
			{
				Msgbox, 262144, This message will not be shown next time, This is for mouse devices with a [Back] button.`n`nIf you mouse has a Back or Forward button, AeroZoom creates 8 more hotkeys out of those buttons to do more, e.g. these less known built-in functions: Speak, Google, Eject Disc, Timer, Monitor Off, Always On Top or running any command or program.`n`nCustomize the hotkeys at 'Tool > Preferences > Custom Hotkeys > Forward/Back'.
				RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, X2, 1
			}
		}
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX2_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseX2.exe",,
		ExitApp
	;}
} else {
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x4
	; if (chkModRaw<>chkMod) {
		; Save last AZ window position before exit
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		If ProgramW6432 ; check if OS is x64
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL_x64.exe",,
		Else
			Run,"%A_WorkingDir%\Data\AeroZoom_MouseL.exe",,
		ExitApp
	;}
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
	If (OSver>6) {
		WinWait, ahk_class MagUIClass,,4 
		if (hideOrMin=1) {
			WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
			if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
				WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
		} else if (hideOrMin=2) {
			WinMinimize, ahk_class MagUIClass
		}
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
		if numPadAddBit
			sendinput #{NumpadAdd}
		else
			SendInput #{+}
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
		if numPadSubBit
			sendinput #{NumpadSub}
		else
			SendInput #{-}
		Gosub, ReadValueUpdatePanel
		Sleep 150
	}
	GuiControl, Enable, Magnification
	; GuiControl,, Magnification, %Magnification%
}

; Update the panel menu
If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
	if (MagnificationRaw=0x64) ; if zoomed out (because Preview Full Screen only works when zoomed in)
		Menu, ViewsMenu, Disable, &Preview Full Screen`tCtrl+Alt+Space
	else ; if zoomed in
		Menu, ViewsMenu, Enable, &Preview Full Screen`tCtrl+Alt+Space
}
Return

; ----------------------------------------------------- Zoom Increment 3 of 3 (Subroutine)
SliderX:
if (OSver<6.1) {
	return
}

; Gui, Submit, NoHide << not required if a gLabel is used in Slider
if (zoomInc=1) {
	zoomIncRaw=0x19
	zoomIncText=25`%
} else if (zoomInc=2) {
	zoomIncRaw=0x32
	zoomIncText=50`%
} else if (zoomInc=3) {
	zoomIncRaw=0x64
	zoomIncText=100`%
} else if (zoomInc=4) {
	zoomIncRaw=0x96
	zoomIncText=150`%
} else if (zoomInc=5) {
	zoomIncRaw=0xc8
	zoomIncText=200`%
} else if (zoomInc=6) {
	zoomIncRaw=0x190
	zoomIncText=400`%
} else {
	zoomIncRaw=0x64
	zoomIncText=100`%
}

RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CaptureDiskOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomitColorOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipModeOSD
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIncTextOSD, %ZoomIncText%

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
	if (OSver>=6.2)
		Big4Buttons=1 ; needed on windows 8 for this function to work
	GoSub, CloseMagnifier ; !!!!!! If magnifier is running, rerun Magnifier to apply the setting
	sleep, %delayButton%
	Run,"%windir%\system32\magnify.exe",,Min
} else {
	hideOrMinLast= ; if not defined, use default settings
}
	
Gosub, MagWinRestore

If (OSD=1)
	Run, "%A_WorkingDir%\Data\OSD.exe"

Return
; ----------------------------------------------------- Zoom Increment END (return to listen hotkey)

RunOnStartup:

Gui, 1:Font, CRed,
GuiControl,1:Font,Txt, ; to apply the color change
GuiControl,1:,Txt,- Please Wait -
GuiControl,Disable,Bye
;Gui,+Disabled ; this is commented to avoid gui from hiding itself when not always on top

; Check if AeroZoom task exist

RegRead,RunOnStartupMsg,HKCU,Software\wandersick\AeroZoom,RunOnStartupMsg
if errorlevel
{
	if not GuideDisabled
	{
		Msgbox, 262208, This message will only be shown once, Use this especially if you have User Account Control (UAC) on for your PC.`n`n'Run on Startup' takes advantage of Task Scheduler to run AeroZoom at logon as admin without any screen-dimming prompts. It is an exclusive feature for Windows Vista and later.`n`nNote: If you have any other programs prompting for admin rights at logon, this function might not work.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RunOnStartupMsg, 1
	}
}

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
	Menu, FileMenu, Uncheck, &Run on Startup
	RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 0
	Msgbox, 262144, AeroZoom, Task successfully removed.
} else if (errorlevel=3) { ; if task did not exist has just been successfully created
	Menu, FileMenu, Check, &Run on Startup
	RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 1
	Msgbox, 262144, AeroZoom, Task successfully created.`n`nAeroZoom will start at boot time with current settings for this user: %A_UserName%`n`nUnder this copy of AeroZoom: %A_WorkingDir%
} else {
	Msgbox, 262192, AeroZoom, Sorry. There was a problem creating or deleting task.`n`nMaybe you don't have administrator rights?
}

Gui, 1:Font, c666666
GuiControl,1:Font,Txt,
GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
Gui,-Disabled
GuiControl,Enable,Bye

return

Install:
IfWinExist, AeroZoom Panel
	ExistAZ=1
; Install / Unisntall
regKey=SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AeroZoom
IfExist, %programfiles% (x86)\wandersick\AeroZoom\AeroZoom.exe
{
	if ExistAZ
	{
		Menu, FileMenu, Disable, &Install as Current User
	}
	Msgbox, 262192, AeroZoom, Please uninstall AeroZoom from 'Control Panel\Programs and Features' or use Setup.exe /programfiles.
	ExistAZ=
	return
}
IfExist, %programfiles%\wandersick\AeroZoom\AeroZoom.exe
{
	if ExistAZ
	{
		Menu, FileMenu, Disable, &Install as Current User
	}
	Msgbox, 262192, AeroZoom, Please uninstall AeroZoom from 'Control Panel\Programs and Features' or use Setup.exe /programfiles.
	ExistAZ=
	return
}
IfNotExist, %localappdata%\wandersick\AeroZoom\AeroZoom.exe
{
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Installer , Install AeroZoom for user '%A_UserName%' in the following location?`n`n%localappdata%\wandersick\AeroZoom
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
	;Gui,+Disabled ; this is commented to avoid gui from hiding itself when not always on top
	; Remove existing directory
	FileRemoveDir, %localappdata%\wandersick\AeroZoom\Data, 1
	FileRemoveDir, %localappdata%\wandersick\AeroZoom, 1
	; Copy AeroZoom to %localappdata%
	FileCopyDir, %A_WorkingDir%, %localappdata%\wandersick\AeroZoom, 1
	; Create shortcut to Start Menu (Current User)
	IfExist, %localappdata%\wandersick\AeroZoom\AeroZoom.exe
	{
		FileCreateShortcut, %localappdata%\wandersick\AeroZoom\AeroZoom.exe, %A_Programs%\AeroZoom.lnk, %localappdata%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
		FileCreateShortcut, %localappdata%\wandersick\AeroZoom\AeroZoom.exe, %A_Desktop%\AeroZoom.lnk, %localappdata%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
	} else {
		FileCreateShortcut, %A_WorkingDir%\AeroZoom.exe, %A_Programs%\AeroZoom.lnk, %A_WorkingDir%,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
		FileCreateShortcut, %A_WorkingDir%\AeroZoom.exe, %A_Desktop%\AeroZoom.lnk, %A_WorkingDir%,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
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
				RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 1
				Menu, FileMenu, Check, &Run on Startup
			}
		} else if (errorlevel=5) {
			RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 0
			Menu, FileMenu, Uncheck, &Run on Startup
		}
		;IfExist, %localappdata%\wandersick\AeroZoom\AeroZoom.exe
		;{
			; FileCreateShortcut, %localappdata%\wandersick\AeroZoom\AeroZoom.exe, %A_Startup%\AeroZoom.lnk, %localappdata%\wandersick\AeroZoom\,, AeroZoom`, the smooth wheel-zooming and snipping mouse-enhancing panel,,
		;}
		;IfExist, %A_Startup%\*AeroZoom*.*
		;{
		;	Menu, FileMenu, Check, &Run on Startup
		;}
	; Write uninstall entry to registry 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayIcon, %localappdata%\wandersick\AeroZoom\AeroZoom.exe,0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayName, AeroZoom %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallDate, %A_YYYY%%A_MM%%A_DD%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, HelpLink, http://wandersick.blogspot.com
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, URLInfoAbout, http://wandersick.blogspot.com
	
	; ******************************************************************************************
	; ******************************************************************************************
	; ******************************************************************************************
	; ******************************************************************************************
	
	
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %localappdata%\wandersick\AeroZoom\setup.exe /unattendAZ=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallLocation, %localappdata%\wandersick\AeroZoom
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayVersion, %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, Publisher, a wandersick
	; Calc folder size
	; SetBatchLines, -1  ; Make the operation run at maximum speed.
	EstimatedSize = 0
	Loop, %localappdata%\wandersick\AeroZoom\*.*, , 1
	EstimatedSize += %A_LoopFileSize%
	EstimatedSize /= 1024
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, %regKey%, EstimatedSize, %EstimatedSize%
	IfExist, %localappdata%\wandersick\AeroZoom\AeroZoom.exe
	{
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}	
		if ExistAZ
		{
			Menu, FileMenu, Check, &Install as Current User
		}
		Msgbox, 262144, AeroZoom, Successfully installed.`n`nAccess the uninstaller in 'Control Panel\Programs and Features'. ; 262144 = Always on top
	} else {
		IfEqual, unattendAZ, 1
		{
			ExitApp, 1
		}
		Msgbox, 262192, AeroZoom, Installation failed.`n`nPlease ensure this folder is unlocked:`n`n%localappdata%\wandersick\AeroZoom
	}
} else {
	; if unattend switch is on, skip the check since user must be running the uninstaller from control panel
	; not from AeroZoom program
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Uninstaller , Uninstall AeroZoom for the current user from the following location?`n`n%localappdata%\wandersick\AeroZoom`n`nWarning: Preferences will be lost.
		IfMsgBox No
		{
			ExistAZ=
			return
		}
		Gui, 1:Font, CRed,
		GuiControl,1:Font,Txt, ; to apply the color change
		GuiControl,1:,Txt,- Uninstalling - 
		GuiControl,Disable,Bye
		;Gui,+Disabled ; this is commented to avoid gui from hiding itself when not always on top
		IfExist, %A_WorkingDir%\Data\ZoomIt.exe ; if ZoomIt exists, its setting is kept in order to avoid a bug (need to click 2 times in the menu)
			RegRead,zoomitTemp,HKCU,Software\wandersick\AeroZoom,zoomit
			
		; (Same reason as above for the next check but to further look into the executables.)
		; AeroZoom has a built-in function to uninstall its copy in %localappdata%. That only works
		; if the AeroZoom running is a portable copy and not the installed one (because the currently
		; running AeroZoom in %localappdata% cannot delete itself)
		
		; ** Update: the following requires AutoHotkey_L. But even with _L, it worked fine on one PC but not another.
		; ** (maybe my codes suck lol) Given _L is 3 times larger than Basic, I will stick to Basic for now.
		
		; foundPos=0
		; for process in ComObjGet("winmgmts:").ExecQuery("Select CommandLine from Win32_Process")
		
			; this checks CommandLine row of Win32_Process to see if any of the currently running executables
			; are from %localappdata%\wandersick\AeroZoom. (match wandersick\aerozoom\...\zoomit.exe aerozoom.exe, etc.)
			; if the expression returns non-zero (found), then uninstallation must be done via control panel 
			
				 ; FoundPos .= RegExMatch(process.CommandLine[A_Index-1], "i)wandersick.*AeroZoom.*exe")
				 
				 ; this should output 000000005010000 or anything non-zero if a exe in %localappdata%\wandersick\AeroZoom
				 ; is found running (then OK to uninstall)
				 ; this should output 000000000000000000 if not found (NOT OK to uninstall)
				 
		; If (FoundPos<>0) {
			; users will be prompted to remove AeroZoom from Control Panel\Programs and Features
			;**  the uninstaller code below is abandoned.
			if ExistAZ
			{
				Menu, FileMenu, Disable, &Install as Current User
			}
			Msgbox, 262192, AeroZoom, Please uninstall AeroZoom from 'Control Panel\Programs and Features' or use Setup.exe.
			Gui, 1:Font, c666666
			GuiControl,1:Font,Txt,	
			GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
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
		RegWrite, REG_SZ, HKCU, Software\wandersick\AeroZoom, RunOnStartup, 0
		Menu, FileMenu, Uncheck, &Run on Startup
	}
	; remove reg keys
	RegDelete, HKEY_CURRENT_USER, %regKey%
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom
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
	FileSetAttrib, -R, %localappdata%\wandersick\AeroZoom\*.*
	FileRemoveDir, %localappdata%\wandersick\AeroZoom\Data, 1
	FileRemoveDir, %localappdata%\wandersick\AeroZoom, 1
	IfNotExist, %localappdata%\wandersick\AeroZoom\AeroZoom.exe
	{
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}
		if ExistAZ
		{
			Menu, FileMenu, Uncheck, &Install as Current User
		}
		if zoomitTemp
		{
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIt, %zoomitTemp%
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
		Msgbox, 262192, AeroZoom, Uninstallation failed.`n`nPlease ensure this folder is unlocked:`n`n%localappdata%\wandersick\AeroZoom
	}
}
Gui, 1:Font, c666666
GuiControl,1:Font,Txt,	
GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
Gui,-Disabled
GuiControl,Enable,Bye
ExistAZ=
return

NirCmd:
IfNotExist, %A_WorkingDir%\Data\NirCmd.exe
	goto, NirCmdDownload
if (NirCmd=1) {
	NirCmd=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, NirCmd, 0
	Menu, ToolboxMenu, Uncheck, &Save Captures
	If (OSver<6.1) {
		GuiControl,1:, SnipSlider, 1
	}
} else {
	NirCmd=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, NirCmd, 1
	Menu, ToolboxMenu, Check, &Save Captures
	If (OSver<6.1) {
		GuiControl,1:, SnipSlider, 2
	}
}

return

ConfigBackup:
gosub, configGuidance
if (EnableAutoBackup=1) {
	EnableAutoBackup=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, EnableAutoBackup, 0
	Menu, Configuration, Uncheck, &Save Config on Exit
} else {
	EnableAutoBackup=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, EnableAutoBackup, 1
	Menu, Configuration, Check, &Save Config on Exit
}

return

Zoomit:
Process, Exist, ZoomIt.exe
if (errorlevel<>0) {
	Process, Close, zoomit.exe
	Process, Close, zoomit64.exe
	Menu, ToolboxMenu, Uncheck, &Use ZoomIt as Magnifier
	Menu, ViewsMenu, Disable, Sysinternals &ZoomIt
	zoomit=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIt, 0
	if zoomitPanel
		gosub, zoomitPanel
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
			If Welcome ; except first-run (where user might have moved AeroZoom to another PC)
			{
				Msgbox, 262196, Notice, AeroZoom has detected the step of accepting ZoomIt's End User Licensing Agreement (EULA) may have not been completed. If that is the case, click 'Yes'.`n`nIf you suspect the download failed and ZoomIt.exe is corrupt (sign: strange error prompts), click 'No' so that AeroZoom deletes the file and lets you download again. `n`nAlternatively, you can manually delete or put ZoomIt.exe into:`n`n%A_WorkingDir%\Data
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
	}
	skipEulaChk = 
	Run, "%A_WorkingDir%\Data\ZoomIt.exe"
	if ZoomItFirstRun
	{
		WinWait, ZoomIt License Agreement,,3 ; Prevent AZ panel fro covering EULA
		WinHide, AeroZoom Panel
		WinSet, AlwaysOnTop, On, ZoomIt License Agreement
		WinWaitClose, ZoomIt License Agreement
		WinWait, ZoomIt - Sysinternals: www.sysinternals.com,,1 ; zoomit options may show if it is the first time zoomit has run
		IfWinExist, ZoomIt - Sysinternals: www.sysinternals.com
			WinClose
		WinShow, AeroZoom Panel
	}
	ZoomItFirstRun=
	RegRead,EulaAccepted,HKCU,Software\Sysinternals\ZoomIt,EulaAccepted
	If not EulaAccepted
		return
	Menu, ToolboxMenu, Check, &Use ZoomIt as Magnifier
	Menu, ViewsMenu, Enable, Sysinternals &ZoomIt
	zoomit=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIt, 1
}
return

UseZoomPad:
if (zoomPad=1) {
	zoomPad=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomPad, 0
	Menu, ToolboxMenu, Uncheck, &Misclick-Preventing Pad
	;GuiControl,, T&ype, Word
} else {
	zoomPad=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomPad, 1
	Menu, ToolboxMenu, Check, &Misclick-Preventing Pad
	;GuiControl,, T&ype, Note
}
return

ToggleElasticZoom:
if (ElasticZoom=1) {
	ElasticZoom=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ElasticZoom, 0
	Menu, ToolboxMenu, Uncheck, &Elastic Zoom
} else {
	ElasticZoom=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ElasticZoom, 1
	Menu, ToolboxMenu, Check, &Elastic Zoom
}
return

HoldMiddle:
if (holdMiddle=1) {
	holdMiddle=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, holdMiddle, 0
	Menu, CustomHkMenu, Uncheck, &Enable Holding Middle
} else {
	holdMiddle=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, holdMiddle, 1
	Menu, CustomHkMenu, Check, &Enable Holding Middle
}
return

CtrlAltShiftWin:
if (CtrlAltShiftWin=1) {
	CtrlAltShiftWin=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlAltShiftWin, 0
	Menu, CustomHkMenu, Uncheck, &Enable Ctrl/Alt/Shift/Win
} else {
	CtrlAltShiftWin=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlAltShiftWin, 1
	Menu, CustomHkMenu, Check, &Enable Ctrl/Alt/Shift/Win
}
return

ForwardBack:
if (ForwardBack=1) {
	ForwardBack=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardBack, 0
	Menu, CustomHkMenu, Uncheck, &Enable Forward/Back
} else {
	ForwardBack=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardBack, 1
	Menu, CustomHkMenu, Check, &Enable Forward/Back
}
return

LeftRight:
if (LeftRight=1) {
	LeftRight=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftRight, 0
	Menu, CustomHkMenu, Uncheck, &Enable Left/Right
} else {
	LeftRight=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftRight, 1
	Menu, CustomHkMenu, Check, &Enable Left/Right
}
return

UseNotepad:
if (notepad=1) {
	notepad=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Notepad, 0
	Menu, ToolboxMenu, Uncheck, &Type with Notepad
	;GuiControl,, &Note, Word
} else {
	notepad=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Notepad, 1
	Menu, ToolboxMenu, Check, &Type with Notepad
	; When useNotepad is selected, customEd is deselected
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, customEdCheckbox
	customEdCheckbox=
	;GuiControl,, &Note, Note
}
return

ClicknGo:
; Toggle Click 'n Go
RegRead,clickGoBit,HKCU,Software\wandersick\AeroZoom,clickGoBit
if clickGoBit
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, clickGoBit, 0
	Menu, OptionsMenu, Uncheck, Legacy: Click-n-Go Buttons
	guiDestroy=
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, clickGoBit, 1
	Menu, OptionsMenu, Check, Legacy: Click-n-Go Buttons
	guiDestroy=Destroy
}
return

MouseCenteredZoomMenu:
; Toggle Mouse-Centered Zoom
RegRead,mouseCenteredZoomBit,HKCU,Software\wandersick\AeroZoom,mouseCenteredZoomBit
if (OSver>=6.1) {
	if mouseCenteredZoomBit
	{
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, mouseCenteredZoomBit, 0
		Menu, OptionsMenu, Uncheck, Experiment: Center Zoom
		mouseCenteredZoomBit=0
		guiDestroy=
	} else {
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, mouseCenteredZoomBit, 1
		Menu, OptionsMenu, Check, Experiment: Center Zoom
		mouseCenteredZoomBit=1
		guiDestroy=Destroy
	}
}
return

PreferNumpadAdd:
RegRead,NumpadAddSubMsg,HKCU,Software\wandersick\AeroZoom,NumpadAddSubMsg
if errorlevel
{
	if not GuideDisabled
		Msgbox,262208,This message will only be shown once,AeroZoom will flip this switch for you.`n`nThis workaround enables AeroZoom to use an alternative keyboard shortcut to zoom in/out with the Windows Magnifier. Trying a different combination of this setting might solve problems such as +/- characters being generated during zoom in/out.`n`nBy default NumpadAdd is enabled while NumpadSub is disabled. This combination works best normally for Ctrl modifier. You may finetune this setting if it does not work best for you.`n`nIn case you mess it up, you may need to restore AeroZoom to the default settings.
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, NumpadAddSubMsg, 1
}
RegRead,numPadAddBit,HKCU,Software\wandersick\AeroZoom,numPadAddBit
if numPadAddBit
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, numPadAddBit, 0
	Menu, OptionsMenu, Uncheck, Workaround: Prefer NumpadAdd to +
	numPadAddBit=0
	guiDestroy=
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, numPadAddBit, 1
	Menu, OptionsMenu, Check, Workaround: Prefer NumpadAdd to +
	numPadAddBit=1
	guiDestroy=Destroy
}
return

PreferNumpadSub:
RegRead,NumpadAddSubMsg,HKCU,Software\wandersick\AeroZoom,NumpadAddSubMsg
if errorlevel
{
	if not GuideDisabled
		Msgbox,262208,This message will only be shown once,AeroZoom will flip this switch for you.`n`nThis workaround enables AeroZoom to use an alternative keyboard shortcut to zoom in/out with the Windows Magnifier. Trying a different combination of this setting might solve problems such as +/- characters being generated during zoom in/out.`n`nBy default NumpadAdd is enabled while NumpadSub is disabled. This combination works best normally for Ctrl modifier. You may finetune this setting if it does not work best for you.`n`nIn case you mess it up, you may need to restore AeroZoom to the default settings.
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, NumpadAddSubMsg, 1
}
RegRead,numPadSubBit,HKCU,Software\wandersick\AeroZoom,numPadSubBit
if numPadSubBit
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, numPadSubBit, 0
	Menu, OptionsMenu, Uncheck, Workaround: Prefer NumpadSub to -
	numPadSubBit=0
	guiDestroy=
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, numPadSubBit, 1
	Menu, OptionsMenu, Check, Workaround: Prefer NumpadSub to -
	numPadSubBit=1
	guiDestroy=Destroy
}
return


OnTop:
; Toggle Always on Top
RegRead,onTopBit,HKCU,Software\wandersick\AeroZoom,onTopBit
if onTopBit
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, onTopBit, 0
	Menu, ToolboxMenu, Uncheck, &Always on Top
	onTop=-AlwaysOnTop
	onTopBit=0
	WinSet, AlwaysOnTop, off, ahk_class %calcClass%
	WinSet, AlwaysOnTop, off, ahk_class MSPaintApp
	WinSet, AlwaysOnTop, off, ahk_class WordPadClass
	WinSet, AlwaysOnTop, off, ahk_class Notepad
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, onTopBit, 1
	Menu, ToolboxMenu, Check, &Always on Top
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
Gui, 1:-AlwaysOnTop
FileSelectFile, customEdPath, 3, , Select something to launch by this button, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if customEdPath
{
	GuiControl,3:,customEdPath,%customEdPath%
}
return

3ButtonBrowse2:
Gui, 1:-AlwaysOnTop ; to prevent the Browse dialog from being covered by the Advanced Options dialog
FileSelectFile, customCalcPath, 3, , Select something to launch by this button, 
If onTopBit
	Gui, 1:+AlwaysOnTop
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
RegRead,zoomItOptions,HKCU,Software\wandersick\AeroZoom,zoomItOptions
if not zoomItOptions
{
	if not GuideDisabled
	{
		Msgbox, 262144, This message will only be shown once, Please do not modify the keyboard shortcuts in ZoomIt Options as AeroZoom depends on the default hotkeys to work.`n`nIn case they are modified, it can be reverted by clicking 'Reset' in Tool > Preferences > Advanced Options.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomItOptions, 1
	}
}
Run, "%A_WorkingDir%\Data\ZoomIt.exe" ; running an already running ZoomIt brings up the options menu.
WinWait, ZoomIt - Sysinternals: www.sysinternals.com,,3 ; Prevent AZ panel fro covering ZoomIt Options
;WinSet, AlwaysOnTop, Off, AeroZoom Panel
WinSet, AlwaysOnTop, On, ZoomIt - Sysinternals: www.sysinternals.com
;WinWaitClose, ZoomIt - Sysinternals: www.sysinternals.com
;If onTopBit
;	WinSet, AlwaysOnTop, On, AeroZoom Panel
;Else
;	WinActivate, AeroZoom Panel
return

ViewFullScreen:
Process, Exist, magnify.exe
if not errorlevel ; if not running
	Run,"%windir%\system32\magnify.exe",,
IfWinExist, AeroZoom Panel
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
	If (OSver>6) {
		WinWait, ahk_class MagUIClass,,3
	}
}
IfWinExist, AeroZoom Panel
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
	If (OSver>6) {
		WinWait, ahk_class MagUIClass,,3
	}
}
IfWinExist, AeroZoom Panel
{
	Menu, ViewsMenu, Uncheck, &Full Screen`tCtrl+Alt+F
	Menu, ViewsMenu, Uncheck, &Lens`tCtrl+Alt+L
	Menu, ViewsMenu, Check, &Docked`tCtrl+Alt+D
}
sendinput ^!d
return

ViewPreview:
If (OSver<6.1) {
	return
}
Process, Exist, magnify.exe
if not errorlevel ; if not running
{
	Run,"%windir%\system32\magnify.exe",,
		WinWait, ahk_class MagUIClass,,3
}
sendinput ^!{Space}
return

ViewStillZoom:
if not zoomItGuidance
	Gosub, ZoomItGuidance
Process, Close, ZoomPad.exe ; prevent zoompad frame from appearing in zoomit
process, close, osd.exe ; prevent osd from showing in 'picture'
WinHide, AeroZoom Panel
If (A_ThisMenu="ZoomitMenu") ; takes longer to fade out the menu on some system w/o good display
	Sleep, 225
sendinput ^1
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

ViewLiveZoom:
if (OSver<6.0) {
	Msgbox, 262192, ERROR, Live Zoom requires Windows Vista or later.
	return
}
	
IfWinExist, ahk_class MagnifierClass ; if zoomit is working, enhance (stop) it instead
{
	sendinput ^4
	return
}
IfWinExist, ahk_class ZoomitClass
{
	sendinput ^1
	WinWaitClose, ahk_class ZoomitClass,, 4
}

;If not zoomItGuidance
;	Gosub, ZoomItGuidance

gosub, ZoomItLiveMsg

sendinput ^4
gosub, WorkaroundFullScrLiveZoom
return

ViewBlackBoard:
if not zoomItGuidance
	Gosub, ZoomItGuidance
WinHide, AeroZoom Panel
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
sendinput kt
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

ViewWhiteBoard:
if not zoomItGuidance
	Gosub, ZoomItGuidance
WinHide, AeroZoom Panel
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
sendinput wt
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

ViewDraw:
if not zoomItGuidance
	Gosub, ZoomItGuidance
Process, Close, ZoomPad.exe ; prevent zoompad frame from appearing in zoomit
process, close, osd.exe ; prevent osd from showing in 'picture'
WinHide, AeroZoom Panel
If (A_ThisMenu="ZoomitMenu") ; takes longer to fade out the menu on some system w/o good display
	Sleep, 225
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

ViewType:
if not zoomItGuidance
	Gosub, ZoomItGuidance
Process, Close, ZoomPad.exe ; prevent zoompad frame from appearing in zoomit
process, close, osd.exe ; prevent osd from showing in 'picture'
WinHide, AeroZoom Panel
If (A_ThisMenu="ZoomitMenu") ; takes longer to fade out the menu on some system w/o good display
	Sleep, 225
sendinput ^2
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
sendinput t
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

ViewBreakTimer:
if not zoomItGuidance
	Gosub, ZoomItGuidance
WinHide, AeroZoom Panel
sendinput ^3
WinWait, ahk_class ZoomitClass,,5
gosub, ZoomItColor
WinWaitClose, ahk_class ZoomitClass
WinShow, AeroZoom Panel
return

; 1-61
MagReadValues1:
	
RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0x7D) { ; 125
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x96) { ; 150
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0xAF) { ; 175
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4	
} else if (MagnificationRaw=0xC8) { ; 200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0xE1) { ; 225
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0xFA) { ; 250
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x113) { ; 275
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x12C) { ; 300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x145) { ; 325
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x15E) { ; 350
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 11
	Magnification=11
} else if (MagnificationRaw=0x177) { ; 375
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 12
	Magnification=12
} else if (MagnificationRaw=0x190) { ; 400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 13
	Magnification=13
} else if (MagnificationRaw=0x1A9) { ; 425
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 14
	Magnification=14
} else if (MagnificationRaw=0x1C2) { ; 450
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 15
	Magnification=15
} else if (MagnificationRaw=0x1DB) { ; 475
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 16
	Magnification=16
} else if (MagnificationRaw=0x1F4) { ; 500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 17
	Magnification=17
} else if (MagnificationRaw=0x20D) { ; 525
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 18
	Magnification=18
} else if (MagnificationRaw=0x226) { ; 550
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 19
	Magnification=19
} else if (MagnificationRaw=0x23F) { ; 575
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 20
	Magnification=20
} else if (MagnificationRaw=0x258) { ; 600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 21
	Magnification=21
} else if (MagnificationRaw=0x271) { ; 625
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 22
	Magnification=22
} else if (MagnificationRaw=0x28A) { ; 650
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 23
	Magnification=23
} else if (MagnificationRaw=0x2A3) { ; 675
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 24
	Magnification=24
} else if (MagnificationRaw=0x2BC) { ; 700
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 25
	Magnification=25
} else if (MagnificationRaw=0x2D5) { ; 725
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 26
	Magnification=26
} else if (MagnificationRaw=0x2EE) { ; 750
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 27
	Magnification=27
} else if (MagnificationRaw=0x307) { ; 775
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 28
	Magnification=28
} else if (MagnificationRaw=0x320) { ; 800
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 29
	Magnification=29
} else if (MagnificationRaw=0x339) { ; 825
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 30
	Magnification=30
} else if (MagnificationRaw=0x352) { ; 850
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 31
	Magnification=31
} else if (MagnificationRaw=0x36B) { ; 875
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 32
	Magnification=32
} else if (MagnificationRaw=0x384) { ; 900
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 33
	Magnification=33
} else if (MagnificationRaw=0x39D) { ; 925
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 34
	Magnification=34
} else if (MagnificationRaw=0x3B6) { ; 950
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 35
	Magnification=35
} else if (MagnificationRaw=0x3CF) { ; 975
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 36
	Magnification=36
} else if (MagnificationRaw=0x3E8) { ; 1000
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 37
	Magnification=37
} else if (MagnificationRaw=0x401) { ; 1025
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 38
	Magnification=38
} else if (MagnificationRaw=0x41A) { ; 1050
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 39
	Magnification=39
} else if (MagnificationRaw=0x433) { ; 1075
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 40
	Magnification=40
} else if (MagnificationRaw=0x44C) { ; 1100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 41
	Magnification=41
} else if (MagnificationRaw=0x465) { ; 1125
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 42
	Magnification=42
} else if (MagnificationRaw=0x47E) { ; 1150
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 43
	Magnification=43
} else if (MagnificationRaw=0x497) { ; 1175
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 44
	Magnification=44
} else if (MagnificationRaw=0x4B0) { ; 1200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 45
	Magnification=45
} else if (MagnificationRaw=0x4C9) { ; 1225
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 46
	Magnification=46
} else if (MagnificationRaw=0x4E2) { ; 1250
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 47
	Magnification=47
} else if (MagnificationRaw=0x4FB) { ; 1275
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 48
	Magnification=48
} else if (MagnificationRaw=0x514) { ; 1300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 49
	Magnification=49
} else if (MagnificationRaw=0x52D) { ; 1325
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 50
	Magnification=50
} else if (MagnificationRaw=0x546) { ; 1350
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 51
	Magnification=51
} else if (MagnificationRaw=0x55F) { ; 1375
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 52
	Magnification=52
} else if (MagnificationRaw=0x578) { ; 1400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 53
	Magnification=53
} else if (MagnificationRaw=0x591) { ; 1425
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 54
	Magnification=54
} else if (MagnificationRaw=0x5AA) { ; 1450
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 55
	Magnification=55
} else if (MagnificationRaw=0x5C3) { ; 1475
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 56
	Magnification=56
} else if (MagnificationRaw=0x5DC) { ; 1500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 57
	Magnification=57
} else if (MagnificationRaw=0x5F5) { ; 1525
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 58
	Magnification=58
} else if (MagnificationRaw=0x60E) { ; 1550
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 59
	Magnification=59
} else if (MagnificationRaw=0x627) { ; 1575
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 60
	Magnification=60
} else if (MagnificationRaw=0x640) { ; 1600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 61
	Magnification=61
} else {
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
}

return

; 1-31
MagReadValues2:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0x96) { ; 150
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0xC8) { ; 200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0xFA) { ; 250
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x12C) { ; 300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x15E) { ; 350
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x190) { ; 400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x1C2) { ; 450
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x1F4) { ; 500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x226) { ; 550
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x258) { ; 600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 11
	Magnification=11
} else if (MagnificationRaw=0x28A) { ; 650
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 12
	Magnification=12
} else if (MagnificationRaw=0x2BC) { ; 700
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 13
	Magnification=13
} else if (MagnificationRaw=0x2EE) { ; 750
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 14
	Magnification=14
} else if (MagnificationRaw=0x320) { ; 800
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 15
	Magnification=15
} else if (MagnificationRaw=0x352) { ; 850
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 16
	Magnification=16
} else if (MagnificationRaw=0x384) { ; 900
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 17
	Magnification=17
} else if (MagnificationRaw=0x3B6) { ; 950
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 18
	Magnification=18
} else if (MagnificationRaw=0x3E8) { ; 1000
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 19
	Magnification=19
} else if (MagnificationRaw=0x41A) { ; 1050
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 20
	Magnification=20
} else if (MagnificationRaw=0x44C) { ; 1100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 21
	Magnification=21
} else if (MagnificationRaw=0x47E) { ; 1150
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 22
	Magnification=22
} else if (MagnificationRaw=0x4B0) { ; 1200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 23
	Magnification=23
} else if (MagnificationRaw=0x4E2) { ; 1250
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 24
	Magnification=24
} else if (MagnificationRaw=0x514) { ; 1300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 25
	Magnification=25
} else if (MagnificationRaw=0x546) { ; 1350
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 26
	Magnification=26
} else if (MagnificationRaw=0x578) { ; 1400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 27
	Magnification=27
} else if (MagnificationRaw=0x5AA) { ; 1450
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 28
	Magnification=28
} else if (MagnificationRaw=0x5DC) { ; 1500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 29
	Magnification=29
} else if (MagnificationRaw=0x60E) { ; 1550
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 30
	Magnification=30
} else if (MagnificationRaw=0x640) { ; 1600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 31
	Magnification=31
} else {
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
}
return

; 1-16
MagReadValues3:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0xC8) { ; 200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x12C) { ; 300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x190) { ; 400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x1F4) { ; 500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x258) { ; 600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x2BC) { ; 700
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x320) { ; 800
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x384) { ; 900
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x3E8) { ; 1000
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x44C) { ; 1100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 11
	Magnification=11
} else if (MagnificationRaw=0x4B0) { ; 1200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 12
	Magnification=12
} else if (MagnificationRaw=0x514) { ; 1300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 13
	Magnification=13
} else if (MagnificationRaw=0x578) { ; 1400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 14
	Magnification=14
} else if (MagnificationRaw=0x5DC) { ; 1500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 15
	Magnification=15
} else if (MagnificationRaw=0x640) { ; 1600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 16
	Magnification=16
} else {
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
}

return

; 1-11
MagReadValues4:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0xFA) { ; 250
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x190) { ; 400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x226) { ; 550
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x2BC) { ; 700
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x352) { ; 850
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x3E8) { ; 1000
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x47E) { ; 1150
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x514) { ; 1300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 9
	Magnification=9
} else if (MagnificationRaw=0x5AA) { ; 1450
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 10
	Magnification=10
} else if (MagnificationRaw=0x640) { ; 1600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 11
	Magnification=11
} else {
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
}
	
return

;1-9
MagReadValues5:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0xC8) { ; 200 
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x12C) { ; 300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x190) { ; 400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x1F4) { ; 500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x258) { ; 600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x2BC) { ; 700
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x320) { ; 800
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x384) { ; 900
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else if (MagnificationRaw=0x3E8) { ; 1000
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x44C) { ; 1100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 6
	Magnification=6
} else if (MagnificationRaw=0x4B0) { ; 1200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x514) { ; 1300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 7
	Magnification=7
} else if (MagnificationRaw=0x578) { ; 1400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x5DC) { ; 1500 ; when zooming out after zooming in to the max (1600), it reduces to 1400 instead of 1300, so both 1300 and 1400 share the same value, and vice versa
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 8
	Magnification=8
} else if (MagnificationRaw=0x640) { ; 1600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 9
	Magnification=9
} else {
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
}

return

; 1-5
MagReadValues6:

RegRead,MagnificationRaw,HKCU,Software\Microsoft\ScreenMagnifier,Magnification
if (MagnificationRaw=0x64) { ; 100
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
} else if (MagnificationRaw=0x190) { ; 400
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x1F4) { ; 500
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 2
	Magnification=2
} else if (MagnificationRaw=0x320) { ; 800
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x384) { ; 900
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 3
	Magnification=3
} else if (MagnificationRaw=0x4B0) { ; 1200
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x514) { ; 1300
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 4
	Magnification=4
} else if (MagnificationRaw=0x640) { ; 1600
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 5
	Magnification=5
} else {
	if (ExistAZ AND SwitchSlider=2 AND !zoomitPanel)
		GuiControl,, Magnification, 1
	Magnification=1
}

return

ReadValueUpdatePanel:

;if not quickZoomIncChk
;{
	IfWinExist, AeroZoom Panel
		ExistAZ=1
;}

; Refresh ZoomIncrement and Magnification ; note this may not be the best way of doing it
RegRead,zoomIncRaw,HKCU,Software\Microsoft\ScreenMagnifier,ZoomIncrement
if (zoomIncRaw=0x19) { ; Get values from registry, Hex to Dec
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
		GuiControl,, ZoomInc, 1
	zoomInc=1
} else if (zoomIncRaw=0x32) {
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
		GuiControl,, ZoomInc, 2
	zoomInc=2
} else if (zoomIncRaw=0x64) {
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
		GuiControl,, ZoomInc, 3
	zoomInc=3
} else if (zoomIncRaw=0x96) {
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
		GuiControl,, ZoomInc, 4
	zoomInc=4
} else if (zoomIncRaw=0xc8) {
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
		GuiControl,, ZoomInc, 5
	zoomInc=5
} else if (zoomIncRaw=0x190) {
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
		GuiControl,, ZoomInc, 6
	zoomInc=6
} else {
	if (ExistAZ AND SwitchSlider=1 AND !zoomitPanel)
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
	If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
		RegRead,MagnificationMode,HKCU,Software\Microsoft\ScreenMagnifier,MagnificationMode
		if (MagnificationMode=0x2) {
			if (MagnificationRaw=0x64) ; if zoomed out (because Preview Full Screen only works when zoomed in)
				Menu, ViewsMenu, Disable, &Preview Full Screen`tCtrl+Alt+Space
			else ; if zoomed in
				Menu, ViewsMenu, Enable, &Preview Full Screen`tCtrl+Alt+Space
		}
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

If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic") {
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
}

return

SwitchSlider:
IfInString, A_ThisMenuItem, Zoom Rate
	SwitchSlider=1
IfInString, A_ThisMenuItem, Magnify
	SwitchSlider=2
IfInString, A_ThisMenuItem, AeroSnip
	SwitchSlider=3
IfInString, A_ThisMenuItem, Save-Capture
	SwitchSlider=4
	
GuiControl, Disable, ZoomItColor
GuiControl, Hide, ZoomItColor
GuiControl, Disable, ZoomInc
GuiControl, Hide, ZoomInc
GuiControl, Disable, Magnification
GuiControl, Hide, Magnification
GuiControl, Disable, SnipMode
GuiControl, Hide, SnipMode
GuiControl, Disable, SnipSlider
GuiControl, Hide, SnipSlider
If (OSver>=6.1) {
	Menu, FileMenu, Uncheck, Switch to &Magnify Slider
    If !(!A_IsAdmin AND EnableLUA) { ; if Win 7 + Limited Account + UAC, Kill is impossible, so zoom rate slider is unavailable.
		Menu, FileMenu, Uncheck, Switch to &Zoom Rate Slider
	}
}
If SnippingToolExists
	Menu, FileMenu, Uncheck, Switch to &AeroSnip Slider
If (OSver<6.1)
	Menu, FileMenu, Uncheck, Switch to Save-Capture Slider
if (SwitchSlider=1) {
	Menu, FileMenu, Check, Switch to &Zoom Rate Slider
	GuiControl, Enable, ZoomInc
	GuiControl, Show, ZoomInc
} else if (SwitchSlider=2) {
	Menu, FileMenu, Check, Switch to &Magnify Slider
	GuiControl, Enable, Magnification
	GuiControl, Show, Magnification
} else if (SwitchSlider=3) {
	Menu, FileMenu, Check, Switch to &AeroSnip Slider
	GuiControl, Enable, SnipMode
	GuiControl, Show, SnipMode
} else if (SwitchSlider=4) {
	Menu, FileMenu, Check, Switch to Save-Capture Slider
	GuiControl, Enable, SnipSlider
	GuiControl, Show, SnipSlider
}
	
; Save last AZ window position before exit so that it shows the GUI after restart
;WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SwitchSlider, %SwitchSlider%
;reload
return

SwitchMiniMode:
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
If SwitchMiniMode
{
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SwitchMiniMode, 0
	If (OSD=1) AND (A_ThisMenuItem<>"&Go to Full View") AND (A_ThisMenuItem<>"&Go to Mini View")
		Run, "%A_WorkingDir%\Data\OSD.exe" Sw1
} else {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SwitchMiniMode, 1
	If (OSD=1) AND (A_ThisMenuItem<>"&Go to Full View") AND (A_ThisMenuItem<>"&Go to Mini View")
		Run, "%A_WorkingDir%\Data\OSD.exe" Sw2
}
Gosub, SaveCurrentProfile
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
IfWinNotExist, AeroZoom Panel
	return
	
; confirm Magnifier is shown (if magnifier is hidden, user would have no way to change its settings there anyway, so no need to use DetectHiddenWindows)
IfWinNotExist, ahk_class MagUIClass,
	return

; Check the slider for update

ZoomIncOld=%ZoomInc%
; quickZoomIncChk=1 ; reduce the burden for SetTimer to return more quickly
Gosub, ReadValueUpdatePanel
; quickZoomIncChk=

; --- WHY RESTART? ---
;If (SwitchSlider=1) { ; no need to restart if AZ panel is not in 'zoominc slider' mode
;	If (ZoomIncOld<>ZoomInc)
;	{
;		; reload AZ script to update
;		; Save last AZ window position before exit so that it shows the GUI after restart
;		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
;		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
;		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
;		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
;		reload
;	}
;}

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

if zoomitPanel
return

; if panel GUI is already created, update using GuiControl

If (MouseLast<>MouseCurrent)
	GuiControl,,Mouse,&Mouse %MouseCurrent% > %MouseNext%
If (KeyboardLast<>KeyboardCurrent)
	GuiControl,,Keyboard,&Keyboard %KeyboardCurrent% > %KeyboardNext%
If (TextLast<>TextCurrent)
	GuiControl,,Text,Te&xt %TextCurrent% > %TextNext%

return

startupTips:
if (TipDisabled=1) {
	TipDisabled=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, TipDisabled, 0
	Menu, AboutMenu, Uncheck, Disable Startup &Tips
} else {
	TipDisabled=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, TipDisabled, 1
	Menu, AboutMenu, Check, Disable Startup &Tips
}
return

firstUseGuide:
if (GuideDisabled=1) {
	GuideDisabled=0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, GuideDisabled, 0
	Menu, AboutMenu, Uncheck, Disable First-Use &Guide
} else {
	GuideDisabled=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, GuideDisabled, 1
	Menu, AboutMenu, Check, Disable First-Use &Guide
}
return

WinCalc:
Run, %windir%\System32\calc.exe
return

; Supports "Old Windows 7 Calculator for Windows 10" from Winaero if calc1.exe is detected under Windows\System32.
WinCalc1:
Run, %windir%\System32\calc1.exe
return

WinCMD:
Run, %windir%\System32\cmd.exe
return

WinCmdAdmin:
Run, *RunAs cmd
return

WinNetworkProjector:
Run, %windir%\system32\NetProj.exe
return

WinProjector:
Run, %windir%\system32\displayswitch.exe
return
	
WinControl:
Run, %windir%\System32\control.exe
return

WinMath:
Run, %CommonProgramFiles%\Microsoft Shared\Ink\mip.exe
return

WinNote:
Run, %windir%\System32\notepad.exe
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

ChMac:
Run, "%comspec%" /k "%systemdrive%\ChMac\ChMac.bat",%systemdrive%\ChMac
return

CmdDict1:
Run, "%comspec%" /k "%systemdrive%\Cmd Dict\Cmd Dict.bat",%systemdrive%\Cmd Dict
return

CmdDict2:
Run, "%comspec%" /k "%systemdrive%\Cmd Dict\Portable.cmd",%systemdrive%\Cmd Dict
return

ECPP1:
Run, "%systemdrive%\ECPP\CommandPromptPortable.exe",%systemdrive%\ECPP
return

ECPP2:
Run, "%systemdrive%\ECPP\ECPP.exe",%systemdrive%\ECPP
return
	
TMS1:
Run, "%comspec%" /k "%systemdrive%\Total Malware Scanner\Total Malware Scanner.bat",%systemdrive%\Total Malware Scanner
return

TMS2:
Run, "%comspec%" /k "%systemdrive%\Total Malware Scanner\Total Malware Scanner.exe",%systemdrive%\Total Malware Scanner
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
IfExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
	Run, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
	
IfNotExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe ; for vista's file virtualization
{
	IfExist, C:\Program Files\Windows NT\Accessories\wordpad.exe
		Run, C:\Program Files\Windows NT\Accessories\wordpad.exe
}
return

WinTask:
Run, %windir%\System32\taskmgr.exe
return

WinTabletInput:
Run, %CommonProgramFiles%\Microsoft Shared\Ink\TabTip.exe
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
		IfWinNotActive, AeroZoom Panel ;if current win is not the panel (zooming over the panel does not require zoompad)
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
If (A_ThisHotkey="~MButton")
	click middle ; prevents captureing the anchor
	
If not SnippingToolExists
{
	IfInString, A_ThisHotkey, MButton
		MButtonErrorMsg=`n`nTip: You may define the Middle button to do things other than snipping in 'Tool > Preferences > Custom Hotkeys > Middle'.
	Else
		MButtonErrorMsg=
	If (OSver=6.0) {
		If (EditionID="HomeBasic" OR EditionID="Starter") {
			msgbox, 262192, ERROR, Snipping Tool is unavailable for Windows Vista Home Basic and Starter. The minimum requirement is Home Premium.`n`nIf you still have a problem, please post it on the AeroZoom page.%MButtonErrorMsg%
		} else {
			msgbox, 262192, ERROR, Snipping Tool.exe is not found in %windir%\system32.`n`nWindows Vista Home Premium or above comes with Snipping Tool but may be disabled by default. Users can enable it by following these steps:`n`n1. Click 'Start', type 'optionalfeatures', wait a second then press enter.`n`n(Alternatively, you can go to Start -> Control Panel -> Programs and Features -> Turn Windows Features on or off.)`n`n2. Select 'Tablet PC Optional Components' then click OK.`n`nIf you still have a problem, please post it on the AeroZoom page.
		}
	} else if (OSver=6.1) {
		If (EditionID="HomeBasic" OR EditionID="Starter") {
			msgbox, 262192, ERROR, Snipping Tool is unavailable for Windows 7 Home Basic and Starter. The minimum requirement is Home Premium.`n`nIf you still have a problem, please post it on the AeroZoom page.%MButtonErrorMsg%
		} else {
			msgbox, 262192, ERROR, SnippingTool.exe is not found in %windir%\system32.`n`nWindows 7 Home Premium or above should come pre-installed with Snipping Tool by default. If you still cannot use it, there is a problem with your system. Please search for the specific error on the web or post the question on the AeroZoom page.
		}
	} else {
		msgbox, 262192, ERROR, Snipping Tool is unsupported for your system. The minimum requirement is Windows Vista Home Premium.`n`nIf unsure, you may ask in the AeroZoom page.%MButtonErrorMsg%
	}
	SnipModeOnce= ; free up for next individual launch
	return
}

;RegRead,AutoCopyToClipboard,HKCU,Software\Microsoft\Windows\TabletPC\Snipping Tool,AutoCopyToClipboard
;If (SnipToClipboard<>AutoCopyToClipboard) { ; if user has changed the setting from AeroZoom
;	Process, Exist, SnippingTool.exe
;	If errorlevel
;		Process, Close, SnippingTool.exe
;	If SnipToClipboard
;		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, AutoCopyToClipboard, 0x1
;	Else 
;		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, AutoCopyToClipboard, 0x0
;}

gosub, EnsureAutoCopyToClipboard

If SnipModeOnce ; if user uses the hotkey or the Snip menu
	SnipModeNow=%SnipModeOnce%
Else
	SnipModeNow=%SnipMode%

If (SnipModeNow=4) { ; if full-screen
	RegRead,SnipFullScreenMsg,HKCU,Software\wandersick\AeroZoom,SnipFullScreenMsg
	if errorlevel
	{
		if not GuideDisabled
		{
			Msgbox,262208,This message will only be shown once,Loading may take a while for full-screen snipping, please be patient and do not press any button until a capture is done.
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipFullScreenMsg, 1
		}
	}
}
	
RegRead,CaptureMode,HKCU,Software\Microsoft\Windows\TabletPC\Snipping Tool,CaptureMode
If (SnipModeNow<>CaptureMode) {
	Process, Exist, SnippingTool.exe
	If errorlevel
		Process, Close, SnippingTool.exe
	If (SnipModeNow=1) { ; 1 free-form snip
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, CaptureMode, 0x1
	} else if (SnipModeNow=3) { ; 3 window snip
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, CaptureMode, 0x3
	} else if (SnipModeNow=4) { ; 4 full-screen snip (be careful of hangs)
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, CaptureMode, 0x4
	} else { ; 2 rectangular snip (default)
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, CaptureMode, 0x2
	}
}

If SnipDelay
	Sleep, %SnipDelay%
	
If (SnipRunBeforeCommandCheckbox AND SnipRunBeforeCommand)
{
	RunWait, %SnipRunBeforeCommand% ; wait until the command exits
}

process, close, zoompad.exe
process, close, osd.exe ; prevent osd from showing in capture

IfWinExist, ahk_class Microsoft-Windows-Tablet-SnipperToolbar
{
	WinHide, AeroZoom Panel
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperToolbar ; WinRestore is unneeded as WinActivate covers it
	Sleep, 50
	If SnippingToolSetting ; go to Snipping Tool program settings (if user clicked Settings within AeroSnip Options)
	{
		sendinput !o
		SnippingToolSetting=
		return
	}
	sendinput ^n
	if !(SnipModeNow=4) { ; full-screen snip doesn't require this
		WinWait, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,4
		If Errorlevel
			Gosub, SnippingToolRestart
		WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
		Sleep, 900
	}
	WinWaitClose, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,8
	If (SnipWin="1") {
		WinHide, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	} else if (SnipWin="2") {
		WinMinimize, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	}
	If NirCmd
	{
		IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
			Run, "%A_WorkingDir%\Data\NirCmd.exe" clipboard saveimage "%SnipSaveDir%\Snip%A_YYYY%%A_MM%%A_DD%%A_Hour%%A_Min%%A_Sec%.%SnipSaveFormat%", ,min
	}
	If (SnipRunCommandCheckbox AND SnipRunCommand)
	{
		Process, WaitClose, NirCmd.exe, 5 ; ensure capture is complete before running a command
		Run, %SnipRunCommand%,,,SnipCommandPID
		If SnipPasteCheckbox
		{
			WinWait, ahk_pid %SnipCommandPID%,,10
			WinActivate
			sendinput ^v
		}
	}
	if (SnipModeNow=4) { ; to avoid capturing AeroZoom panel
		Sleep, 850
	}
	WinShow, AeroZoom Panel
	SnipModeOnce=
	return
}
IfWinExist, ahk_class Microsoft-Windows-Tablet-SnipperEditor
{
	WinHide, AeroZoom Panel
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	Sleep, 50
	sendinput ^n
	WinWait, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,4
	If Errorlevel
		Gosub, SnippingToolRestart
	WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
	Sleep, 900
	If SnippingToolSetting ; go to Snipping Tool program settings (if user clicked Settings within AeroSnip Options)
	{
		sendinput {Esc}
		WinWait, ahk_class Microsoft-Windows-Tablet-SnipperToolbar,,6
		sendinput !o
		SnippingToolSetting=
		return
	}
	if (SnipModeNow=4) { ; full-screen snip is strange when launched from start or from the editor
		sendinput {Esc}
		WinWait, ahk_class Microsoft-Windows-Tablet-SnipperToolbar,,6
		sendinput ^n
	}
	WinWaitClose, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,8
	If (SnipWin="1") {
		WinHide, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	} else if (SnipWin="2") {
		WinMinimize, ahk_class Microsoft-Windows-Tablet-SnipperEditor
	}
	If NirCmd
	{
		IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
			Run, "%A_WorkingDir%\Data\NirCmd.exe" clipboard saveimage "%SnipSaveDir%\Snip%A_YYYY%%A_MM%%A_DD%%A_Hour%%A_Min%%A_Sec%.%SnipSaveFormat%", ,min
	}
	If (SnipRunCommandCheckbox AND SnipRunCommand)
	{
		Process, WaitClose, NirCmd.exe, 5 ; ensure capture is complete before running a command
		Run, %SnipRunCommand%,,,SnipCommandPID
		If SnipPasteCheckbox
		{
			WinWait, ahk_pid %SnipCommandPID%,,10
			WinActivate
			sendinput ^v
		}
	}
	if (SnipModeNow=4) { ; to avoid capturing AeroZoom panel
		Sleep, 850
	}
	WinShow, AeroZoom Panel
	SnipModeOnce=
	return
}
WinHide, AeroZoom Panel
Run,"%windir%\system32\SnippingTool.exe",,
WinWait, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,6
If Errorlevel
	Gosub, SnippingToolRestart
WinActivate, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
Sleep, 900
If SnippingToolSetting ; go to Snipping Tool program settings (if user clicked Settings within AeroSnip Options)
{
	sendinput {Esc}
	WinWait, ahk_class Microsoft-Windows-Tablet-SnipperToolbar,,6
	sendinput !o
	SnippingToolSetting=
	return
}
if (SnipModeNow=4) { ; full-screen snip is strange when launched from start or from the editor
	sendinput {Esc}
	WinWait, ahk_class Microsoft-Windows-Tablet-SnipperToolbar,,6
	sendinput ^n
}
WinWaitClose, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm,,8
If (SnipWin="1") {
	WinHide, ahk_class Microsoft-Windows-Tablet-SnipperEditor
} else if (SnipWin="2") {
	WinMinimize, ahk_class Microsoft-Windows-Tablet-SnipperEditor
}
If NirCmd
{
	IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
		Run, "%A_WorkingDir%\Data\NirCmd.exe" clipboard saveimage "%SnipSaveDir%\Snip%A_YYYY%%A_MM%%A_DD%%A_Hour%%A_Min%%A_Sec%.%SnipSaveFormat%", ,min
}
If (SnipRunCommandCheckbox AND SnipRunCommand)
{
	Process, WaitClose, NirCmd.exe, 5 ; ensure capture is complete before running a command
	Run, %SnipRunCommand%,,,SnipCommandPID
	If SnipPasteCheckbox
	{
		WinWait, ahk_pid %SnipCommandPID%,,10
		WinActivate
		sendinput ^v
	}
}
if (SnipModeNow=4) { ; to avoid capturing AeroZoom panel
	Sleep, 850
}
WinShow, AeroZoom Panel
SnipModeOnce= ; free up for next individual launch
return

SnippingToolRestart:
Process, Close, SnippingTool.exe
sleep, %delayButton%
Run,"%windir%\system32\SnippingTool.exe",,
return

ZoomItDownload:
IfWinExist, AeroZoom Panel
	Gui, 4:+owner1 
;Gui, +Disabled
;Gui, 4:-MinimizeBox -MaximizeBox 
Gui, 4:+ToolWindow
Gui, 4:Font, s8, Tahoma
userZoomItPath = http://live.sysinternals.com/ZoomIt.exe
Gui, 4:Add, Edit, x12 y140 w210 h20 -Multi -WantTab -WantReturn vUserZoomItPath, %UserZoomItPath%
userZoomItPath_TT := "Input the path to ZoomIt.exe"
Gui, 4:Add, Text, x12 y170 w270 h30 , Note: If the head is http`, it'll be downloaded (500+ KB)`n         (AeroZoom must not be used during download.)
Gui, 4:Add, Button, x222 y139 w60 h22 v4ButtonBrowse g4ButtonBrowse, &Browse
4ButtonBrowse_TT := "Browse for ZoomIt.exe"
Gui, 4:Add, Button, x142 y210 w70 h30 Default g4ButtonOK v4ButtonOKTemp, &OK
4ButtonOKTemp_TT := "Click to continue"
Gui, 4:Add, Button, x212 y210 w70 h30 g4ButtonCancel v4ButtonCancelTemp, &Cancel
4ButtonCancelTemp_TT := "Click to withdraw"
Gui, 4:Add, Text, x12 y10 w270 h120 , AeroZoom eases mouse operations of Sysinternals ZoomIt`, a free Microsoft magnifier`, with features as ZoomIt Panel (an easy-to-use interface)`, elastic/wheel zoom`, custom hotkeys`, pen color slider, black/white board and more via panel, buttons and menus.`n`nZoomIt's hotkeys will be set to defaults for it to work.`n`nTo continue`, please specify the path to ZoomIt.exe:
Gui, 4:Show, h252 w298, ZoomIt Enhancements Setup
return

NirCmdDownload:
IfWinExist, AeroZoom Panel
	Gui, 6:+owner1 
;Gui, +Disabled
Gui, 6:-MinimizeBox -MaximizeBox 
Gui, 6:+ToolWindow
Gui, 6:Font, s8, Tahoma
userNirCmdPath = http://www.nirsoft.net/panel/nircmd.exe
Gui, 6:Add, Edit, x12 y190 w210 h20 -Multi -WantTab -WantReturn vuserNirCmdPath, %userNirCmdPath%
userNirCmdPath_TT := "Input the path to NirCmd.exe"
Gui, 6:Add, Text, x12 y220 w270 h30 , Note: If the head is http`, it'll be downloaded (30+ KB)`n         (AeroZoom must not be used during download.)
Gui, 6:Add, Button, x222 y189 w60 h22 v6ButtonBrowse g6ButtonBrowse, &Browse
6ButtonBrowse_TT := "Browse for NirCmd.exe"
Gui, 6:Add, Button, x142 y260 w70 h30 Default g6ButtonOK v6ButtonOKTemp, &OK
6ButtonOKTemp_TT := "Click to continue"
Gui, 6:Add, Button, x212 y260 w70 h30 g6ButtonCancel v6ButtonCancelTemp, &Cancel
6ButtonCancelTemp_TT := "Click to withdraw"
Gui, 6:Add, Text, x12 y10 w270 h178 , AeroSnip enhances the regional screen capturing of Snipping Tool. To begin a new snip after an old one, there's no need wasting time locating Snipping Tool to click the 'New' button - Just press Win+Alt+F/R/W/S or hold the middle button. We can even set it to run an editor other than Snipping Tool after a snip, e.g. Paint.`n`nNormally captures are only saved to clipboard. With NirSoft NirCmd, AeroZoom can save them on disk as well, like the capture hotkeys of Mac OS X and Linux (Compiz). PrintScreen is also enhanced by default.`n`nTo continue`, please specify the path to NirCmd.exe:
Gui, 6:Show, h300 w298, AeroSnip Enhancements Setup
return

NirCmdDownloadAlt: ; this section is used not by AeroSnip but by other nircmd tasks
onlyDownloadNirCmd = 1
IfWinExist, AeroZoom Panel
	Gui, 6:+owner1 
;Gui, +Disabled
Gui, 6:-MinimizeBox -MaximizeBox 
Gui, 6:Font, s8, Tahoma
userNirCmdPath = http://www.nirsoft.net/panel/nircmd.exe
Gui, 6:Add, Edit, x12 y116 w210 h20 -Multi -WantTab -WantReturn vuserNirCmdPath, %userNirCmdPath%
userNirCmdPath_TT := "Input the path to NirCmd.exe"
Gui, 6:Add, Text, x12 y150 w270 h30 , Note: If the head is http`, it'll be downloaded (30+ KB)`n         (AeroZoom must not be used during download.)
Gui, 6:Add, Button, x222 y115 w60 h22 v6ButtonBrowse g6ButtonBrowse, &Browse
6ButtonBrowse_TT := "Browse for NirCmd.exe"
Gui, 6:Add, Button, x142 y190 w70 h30 Default g6ButtonOK v6ButtonOKTemp, &OK
6ButtonOKTemp_TT := "Click to continue"
Gui, 6:Add, Button, x212 y190 w70 h30 g6ButtonCancel v6ButtonCancelTemp, &Cancel
6ButtonCancelTemp_TT := "Click to withdraw"
Gui, 6:Add, Text, x12 y10 w270 h100 , This is a feature that requires NirSoft NirCmd but it has not been installed yet.`n`nAeroZoom makes use of NirCmd to provide optional enhancements.`n`nTo continue`, please specify the path to NirCmd.exe:
Gui, 6:Show, h230 w298, NirCmd Enhancements Setup
return

CustomizeMiddle:
if (chkMod=7) {
RegRead,MiddleTriggerMsg,HKCU,Software\wandersick\AeroZoom,MiddleTriggerMsg
	if errorlevel
	{
		if not GuideDisabled
		{
			Msgbox, 262208, This message will only be shown once, Since you're using the middle button for zoom already, holding it will have no effect. However, you may still access the function with another hotkey: [Middle]+[Left]
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, MiddleTriggerMsg, 1
		}
	}
}
if not HoldMiddle
{
	Msgbox, 262180, Umm, 'Holding Middle (Custom Hotkeys)' is currently disabled. Enable it?
	IfMsgbox Yes
		gosub, HoldMiddle
}
Gui, 7:+owner1
;Gui, +Disabled
;Gui, 7:-MinimizeBox -MaximizeBox 
Gui, 7:+ToolWindow
Gui, 7:Font, s8, Tahoma
Gui, 7:Add, Edit, x67 y60 w180 h20 -Multi -WantTab -WantReturn vCustomMiddlePath, %CustomMiddlePath%
Gui, 7:Add, DropDownList, x191 y30 w115 h21 R42 +AltSubmit vMiddleButtonAction Choose%MiddleButtonAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Preview full screen (7)|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Reset Zoom|Reset Magnifier|Custom (define)|None
MiddleButtonAction_TT := "Choose an action"
Gui, 7:Add, Text, x17 y36 w172 h20 , Pick an action or 'Custom (define)':
Gui, 7:Add, Button, x247 y59 w60 h22 v7BrowseTemp, &Browse
7BrowseTemp_TT := "Browse for an executable"
CustomMiddlePath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
Gui, 7:Add, Text, x17 y65 w50 h20 , Custom:
Gui, 7:Add, Button, x134 y200 w60 h30 v7OKtemp Default, &OK
7OKtemp_TT := "Click to save changes"
Gui, 7:Add, Button, x254 y200 w60 h30 v7HelpTemp, &Help
7HelpTemp_TT := "Click to get help"
Gui, 7:Add, Button, x194 y200 w60 h30 v7CancelTemp, &Cancel
7CancelTemp_TT := "Click to cancel changes"
Gui, 7:Add, Text, x77 y144 w210 h20 , How long to hold the middle button (in ms)
Gui, 7:Add, Edit, x17 y142 w50 h20 +Center +Limit4 -Multi +Number -WantTab -WantReturn vStillZoomDelayTemp, 
StillZoomDelayTemp_TT := "How long holding [Middle] button triggers snip/preview. Default: 800 ms"
Gui, 7:Add, UpDown, x49 y142 w18 h20 vStillZoomDelay Range0-9999, %stillZoomDelay%

if DisableZoomItMiddle ; if checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}
;Gui, 7:Font, Bold s8, Tahoma
Gui, 7:Add, CheckBox, %Checked% -Wrap x17 y109 w290 h30 vDisableZoomItMiddle, &Disable ZoomIt auto switching (legacy)
;Gui, 7:Font, s8, Tahoma
DisableZoomItMiddle_TT := "Holding middle does the action specified here instead of 'still zoom' when 'Tool > Use ZoomIt as Magnifier' is on."

if disablePreviewFullScreen ; if checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}
Gui, 7:Add, CheckBox, %Checked% -Wrap x17 y84 w290 h30 vDisablePreviewFullScreen, &Disable Full Screen Preview auto switching
disablePreviewFullScreen_TT := "When zoomed in, holding middle does the action specified here instead of 'full screen preview' (for 'Full Screen' view of Aero-Enabled Windows Magnifier.)"
Gui, 7:Add, GroupBox, x7 y10 w310 h160 , Hold Middle Button as a Trigger
if disableZoomResetHotkey ; if checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}
Gui, 7:Add, CheckBox, %Checked% -Wrap x17 y173 w250 h23 vDisableZoomResetHotkey, &Disable Zoom Reset hotkey (modifier+middle)
DisableZoomResetHotkey_TT := "For systems that conflicts with the hotkey. (Please report if you need this on.)"
Gui, 7:Show, h236 h236, Customize Middle

;if (chkMod=7) { ; if MButton ahk, disable the menu item
;	GuiControl,7:Disable,7BrowseTemp
;	GuiControl,7:Disable,CustomMiddlePath
;	GuiControl,7:Disable,MiddleButtonAction
;	GuiControl,7:Disable,7OKtemp
;	GuiControl,7:Disable,StillZoomDelay
;	GuiControl,7:Disable,StillZoomDelayTemp
;	GuiControl,7:Disable,DisableZoomItMiddle
;}
;Return
return

7ButtonHelp:
Msgbox, 262208, Help: Customize Holding Middle, Please don't mix up this feature with the radio button named 'Middle' down the panel. While that Middle button is held for zooming, this one is about holding it to run customizable tasks.`n`nIntroduction: AeroZoom creates a hotkey out of the action of 'holding the middle button'. By default, triggering it automatically switches between 2 operations.`n`n1. When zoomed in`, enter a full screen preview.`n2. When unzoomed`, starts an enhanced regional screen capture with Snipping Tool (AeroSnip).`n`nAlso, if 'Disable ZoomIt auto switching (legacy)' is unchecked, when unzoomed and ZoomIt is on`, still zoom of ZoomIt will be entered. (As this may interfere with the customizable hotkeys, it is now by default checked i.e. disabled since AeroZoom 3.0).`n`nThe default actions above can be customized here, with built-in functions such as these less known ones: Speak, Google, Timer, Eject CD, Monitor Off, Always On Top or any external application or command.`n`nNote 1: Choose 'Custom (define)' from the built-in functions (dropdown menu) before specifying an action in the Custom bar.`n`nNote 2: If the Middle button is used for zoom, this feature needs to be called with another hotkey: [Middle]+[Left].
return

7ButtonBrowse:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomMiddlePath, 3, , Select something to launch by middle button, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomMiddlePath
{
	GuiControl,7:,CustomMiddlePath,%CustomMiddlePath%
}
return

7ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
if CustomMiddlePath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomMiddlePath, %CustomMiddlePath%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, MiddleButtonAction, %MiddleButtonAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, DisableZoomItMiddle, %DisableZoomItMiddle%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, DisablePreviewFullScreen, %disablePreviewFullScreen%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, DisableZoomResetHotkey, %disableZoomResetHotkey%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, stillZoomDelay, %stillZoomDelay%

return


; --
; Custom Hotkey (Part 3) Start
; --

; Part 3 does not exist in the external Custom Hotkey exe's

CustomizeForwardBack:
Gui, 8:+owner1
;Gui, +Disabled
;Gui, 8:-MinimizeBox -MaximizeBox 
Gui, 8:+ToolWindow
Gui, 8:Font, s8, Tahoma
Gui, 8:Add, Edit, x12 y37 w140 h20 -Multi -WantTab -WantReturn vCustomBackLeftPath, %CustomBackLeftPath%
Gui, 8:Add, Text, x12 y13 w75 h20 , Back + Left
Gui, 8:Add, Button, x152 y36 w60 h22 g8ButtonBrowse1 v8ButtonBrowse1Temp, &Browse
Gui, 8:Add, DropDownList, x97 y10 w115 h21 R37 +AltSubmit vBackLeftAction Choose%BackLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Text, x12 y73 w75 h20 , Back + Right
Gui, 8:Add, DropDownList, x97 y70 w115 h21 R37 +AltSubmit vBackRightAction Choose%BackRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, DropDownList, x97 y130 w115 h21 R37 +AltSubmit vForwardLeftAction Choose%ForwardLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Edit, x12 y97 w140 h20 -Multi -WantTab -WantReturn vCustomBackRightPath, %CustomBackRightPath%
Gui, 8:Add, Button, x152 y96 w60 h22 g8ButtonBrowse2 v8ButtonBrowse2Temp, B&rowse
Gui, 8:Add, Text, x12 y133 w75 h20 , Fwd + Left
Gui, 8:Add, Edit, x12 y157 w140 h20 -Multi -WantTab -WantReturn vCustomForwardLeftPath, %CustomForwardLeftPath%
Gui, 8:Add, Button, x152 y156 w60 h22 g8ButtonBrowse3 v8ButtonBrowse3Temp, Bro&wse
Gui, 8:Add, Text, x12 y193 w75 h20 , Fwd + Right
Gui, 8:Add, DropDownList, x97 y190 w115 h21 R37 +AltSubmit vForwardRightAction Choose%ForwardRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Edit, x12 y217 w140 h20 -Multi -WantTab -WantReturn vCustomForwardRightPath, %CustomForwardRightPath%
Gui, 8:Add, Button, x152 y216 w60 h22 g8ButtonBrowse4 v8ButtonBrowse4Temp, Brow&se
Gui, 8:Add, Button, x242 y247 w60 h30 Default v8OKtemp, &OK
Gui, 8:Add, Button, x362 y247 w60 h30 v8HelpTemp, &Help
Gui, 8:Add, Button, x302 y247 w60 h30 v8CancelTemp, &Cancel
Gui, 8:Add, Text, x222 y13 w75 h20 , Back + Wup
Gui, 8:Add, DropDownList, x307 y10 w115 h21 R37 +AltSubmit vBackWupAction Choose%BackWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Edit, x222 y37 w140 h20 -Multi -WantTab -WantReturn vCustomBackWupPath, %CustomBackWupPath%
Gui, 8:Add, Button, x362 y36 w60 h22 g8ButtonBrowse1a v8ButtonBrowse1aTemp, &Browse
Gui, 8:Add, Text, x222 y73 w75 h20 , Back + Wdown
Gui, 8:Add, DropDownList, x307 y70 w115 h21 R37 +AltSubmit vBackWdownAction Choose%BackWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Edit, x222 y97 w140 h20 -Multi -WantTab -WantReturn vCustomBackWdownPath, %CustomBackWdownPath%
Gui, 8:Add, Button, x362 y96 w60 h22 g8ButtonBrowse2a v8ButtonBrowse2aTemp, &Browse
Gui, 8:Add, Text, x222 y133 w75 h20 , Fwd + Wup
Gui, 8:Add, DropDownList, x307 y130 w115 h21 R37 +AltSubmit vForwardWupAction Choose%ForwardWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Edit, x222 y157 w140 h20 -Multi -WantTab -WantReturn vCustomForwardWupPath, %CustomForwardWupPath%
Gui, 8:Add, Button, x362 y156 w60 h22 g8ButtonBrowse3a v8ButtonBrowse3aTemp, &Browse
Gui, 8:Add, Text, x222 y193 w75 h20 , Fwd + Wdown
Gui, 8:Add, DropDownList, x307 y190 w115 h21 R37 +AltSubmit vForwardWdownAction Choose%ForwardWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 8:Add, Edit, x222 y217 w140 h20 -Multi -WantTab -WantReturn vCustomForwardWdownPath, %CustomForwardWdownPath%
Gui, 8:Add, Button, x362 y216 w60 h22 g8ButtonBrowse4a v8ButtonBrowse4aTemp, &Browse
Gui, 8:Font, CMaroon s9, Arial, 
Gui, 8:Add, Text, x12 y245 w230 h30 , Left / Right :  Mouse click`nWup / Wdown :  Scroll wheel
Gui, 8:Font, norm, 
BackLeftAction_TT := "Choose an action to run on pressing Back and Left mouse buttons"
BackRightAction_TT := "Choose an action to run on pressing Back and Right mouse buttons"
BackWupAction_TT := "Choose an action to run on pressing Back and Wheel-up mouse buttons"
BackWdownAction_TT := "Choose an action to run on pressing Back and Wheel-down mouse buttons"
ForwardLeftAction_TT := "Choose an action to run on pressing Forward and Left mouse buttons"
ForwardRightAction_TT := "Choose an action to run on pressing Forward and Right mouse buttons"
ForwardWupAction_TT := "Choose an action to run on pressing Forward and Wheel-up mouse buttons"
ForwardWdownAction_TT := "Choose an action to run on pressing Forward and Wheel-down mouse buttons"
CustomBackLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomBackRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomBackWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomBackWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomForwardLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomForwardRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomForwardWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomForwardWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
8ButtonBrowse1Temp_TT := "Browse for an executable"
8ButtonBrowse2Temp_TT := "Browse for an executable"
8ButtonBrowse3Temp_TT := "Browse for an executable"
8ButtonBrowse4Temp_TT := "Browse for an executable"
8ButtonBrowse1aTemp_TT := "Browse for an executable"
8ButtonBrowse2aTemp_TT := "Browse for an executable"
8ButtonBrowse3aTemp_TT := "Browse for an executable"
8ButtonBrowse4aTemp_TT := "Browse for an executable"
8OKtemp_TT := "Click to save changes"
8HelpTemp_TT := "Click to get help"
8CancelTemp_TT := "Click to save changes"

Gui, 8:Show, h285 w432, Custom Hotkeys: Forward and Back

If (chkMod=9) { ; if xbutton1
	GuiControl,8:Disable,8ButtonBrowse1aTemp
	GuiControl,8:Disable,8ButtonBrowse2aTemp
	GuiControl,8:Disable,BackWupAction
	GuiControl,8:Disable,BackWdownAction
	GuiControl,8:Disable,CustomBackWupPath
	GuiControl,8:Disable,CustomBackWdownPath
} else if (chkMod=8) { ; if xbutton2
	GuiControl,8:Disable,8ButtonBrowse3aTemp
	GuiControl,8:Disable,8ButtonBrowse4aTemp
	GuiControl,8:Disable,ForwardWupAction
	GuiControl,8:Disable,ForwardWdownAction
	GuiControl,8:Disable,CustomForwardWupPath
	GuiControl,8:Disable,CustomForwardWdownPath
}

Return

8ButtonHelp:
Msgbox, 262208, Help: Customize Forward and Back, AeroZoom enhances mouse devices with Back and Forward buttons by adding 8 more mouse hotkeys`, which can be customized here for doing tasks such as Speak, Google, Eject CD, Timer, Monitor Off, Always On Top or running any command or application.`n`nNote: Choose 'Custom (define)' from the built-in functions (dropdown menu) before specifying an action in the Custom bar.`n`nTip 1: Some functions may not be suitable for Back or Forward. Use other 'Custom Hotkeys' options in 'Tool > Preferences' instead.`n`nTip 2: Hold 'Back'/'Forward' longer before release to avoid sending a click (of Back/Forward) to the app behind.
return

CustomizeKeys:
;RegRead,CustomizeKeysIntro,HKCU,Software\wandersick\AeroZoom,CustomizeKeysIntro
;if errorlevel
;{
	;Msgbox, 262180, This message will only be shown once, Hey! Since this is the first time you run this feature, would you like some command examples as a template for editing?`n`nThey should be usable right away (except the first and last ones). To try them, choose 'Custom (define)' from the drop-down menu.
	;IfMsgBox, No
	;{
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlLeftPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlRightPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlWupPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlWdownPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltRightPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltWupPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltWdownPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftLeftPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftRightPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftWupPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftWdownPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinLeftPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinRightPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinWupPath, 
	;	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinWdownPath,
	;	CustomCtrlLeftPath=
	;	CustomCtrlRightPath=
	;	CustomCtrlWupPath=
	;	CustomCtrlWdownPath=
	;	CustomAltRightPath=
	;	CustomAltWupPath=
	;	CustomAltWdownPath=
	;	CustomShiftLeftPath=
	;	CustomShiftRightPath=
	;	CustomShiftWupPath=
	;	CustomShiftWdownPath= 
	;	CustomWinLeftPath=
	;	CustomWinRightPath=
	;	CustomWinWupPath=
	;	CustomWinWdownPath=
	;}
	;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomizeKeysIntro, 1
;}
Gui, 9:+owner1
;Gui, +Disabled
;Gui, 9:-MinimizeBox -MaximizeBox
Gui, 9:+ToolWindow
Gui, 9:Font, s8, Tahoma
Gui, 9:Add, Edit, x12 y37 w140 h20 -Multi -WantTab -WantReturn vCustomAltLeftPath, %CustomAltLeftPath%
Gui, 9:Add, Text, x12 y13 w75 h20 , Alt + Left
Gui, 9:Add, DropDownList, x97 y10 w115 h21 R41 +AltSubmit vAltLeftAction Choose%AltLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Button, x152 y36 w60 h22 g9ButtonBrowse3 v9ButtonBrowse3Temp, &Browse
Gui, 9:Add, Text, x12 y73 w75 h20 , Alt + Right
Gui, 9:Add, DropDownList, x97 y70 w115 h21 R41 +AltSubmit vAltRightAction Choose%AltRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x12 y97 w140 h20 -Multi -WantTab -WantReturn vCustomAltRightPath, %CustomAltRightPath%
Gui, 9:Add, Button, x152 y96 w60 h22 g9ButtonBrowse4 v9ButtonBrowse4Temp, &Browse
Gui, 9:Add, Edit, x12 y156 w140 h20 -Multi -WantTab -WantReturn vCustomCtrlLeftPath, %CustomCtrlLeftPath%
Gui, 9:Add, Text, x12 y133 w75 h20 , Ctrl + Left
Gui, 9:Add, Button, x152 y155 w60 h22 g9ButtonBrowse1 v9ButtonBrowse1Temp, &Browse
Gui, 9:Add, DropDownList, x97 y130 w115 h21 R41 +AltSubmit vCtrlLeftAction Choose%CtrlLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Text, x12 y193 w75 h20 , Ctrl + Right
Gui, 9:Add, DropDownList, x97 y190 w115 h21 R41 +AltSubmit vCtrlRightAction Choose%CtrlRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x12 y216 w140 h20 -Multi -WantTab -WantReturn vCustomCtrlRightPath, %CustomCtrlRightPath%
Gui, 9:Add, Button, x152 y215 w60 h22 g9ButtonBrowse2 v9ButtonBrowse2Temp, &Browse
Gui, 9:Add, Text, x12 y253 w75 h20 , Shift + Left
Gui, 9:Add, DropDownList, x97 y250 w115 h21 R41 +AltSubmit vShiftLeftAction Choose%ShiftLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x12 y276 w140 h20 -Multi -WantTab -WantReturn vCustomShiftLeftPath, %CustomShiftLeftPath%
Gui, 9:Add, Button, x152 y275 w60 h22 g9ButtonBrowse5 v9ButtonBrowse5Temp, &Browse
Gui, 9:Add, Text, x12 y313 w75 h20 , Shift + Right
Gui, 9:Add, DropDownList, x97 y310 w115 h21 R41 +AltSubmit vShiftRightAction Choose%ShiftRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x12 y336 w140 h20 -Multi -WantTab -WantReturn vCustomShiftRightPath, %CustomShiftRightPath%
Gui, 9:Add, Button, x152 y335 w60 h22 g9ButtonBrowse6 v9ButtonBrowse6Temp, &Browse
Gui, 9:Add, Text, x12 y373 w75 h20 , Win + Left
Gui, 9:Add, DropDownList, x97 y370 w115 h21 R41 +AltSubmit vWinLeftAction Choose%WinLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x12 y396 w140 h20 -Multi -WantTab -WantReturn vCustomWinLeftPath, %CustomWinLeftPath%
Gui, 9:Add, Button, x152 y395 w60 h22 g9ButtonBrowse7 v9ButtonBrowse7Temp, &Browse
Gui, 9:Add, Text, x12 y433 w75 h20 , Win + Right
Gui, 9:Add, DropDownList, x97 y430 w115 h21 R41 +AltSubmit vWinRightAction Choose%WinRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x12 y456 w140 h20 -Multi -WantTab -WantReturn vCustomWinRightPath, %CustomWinRightPath%
Gui, 9:Add, Button, x152 y455 w60 h22 g9ButtonBrowse8 v9ButtonBrowse8Temp, &Browse
Gui, 9:Add, Button, x362 y494 w60 h30 v9HelpTemp, &Help
Gui, 9:Add, Button, x302 y494 w60 h30 v9CancelTemp, &Cancel
Gui, 9:Add, Button, x242 y494 w60 h30 Default v9OKtemp, &OK
Gui, 9:Add, Text, x222 y133 w75 h20 , Ctrl + Wup
Gui, 9:Add, DropDownList, x307 y130 w115 h21 R39 +AltSubmit vCtrlWupAction Choose%CtrlWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y156 w140 h20 -Multi -WantTab -WantReturn vCustomCtrlWupPath, %CustomCtrlWupPath%
Gui, 9:Add, Button, x362 y155 w60 h22 g9ButtonBrowse1a v9ButtonBrowse1aTemp, &Browse
Gui, 9:Add, Text, x222 y193 w75 h20 , Ctrl + Wdown
Gui, 9:Add, DropDownList, x307 y190 w115 h21 R39 +AltSubmit vCtrlWdownAction Choose%CtrlWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y216 w140 h20 -Multi -WantTab -WantReturn vCustomCtrlWdownPath, %CustomCtrlWdownPath%
Gui, 9:Add, Button, x362 y215 w60 h22 g9ButtonBrowse2a v9ButtonBrowse2aTemp, &Browse
Gui, 9:Add, Text, x222 y13 w75 h20 , Alt + Wup
Gui, 9:Add, DropDownList, x307 y10 w115 h20 R39 +AltSubmit vAltWupAction Choose%AltWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y37 w140 h20 -Multi -WantTab -WantReturn vCustomAltWupPath, %CustomAltWupPath%
Gui, 9:Add, Button, x362 y36 w60 h22 g9ButtonBrowse3a v9ButtonBrowse3aTemp, &Browse
Gui, 9:Add, Text, x222 y73 w75 h20 , Alt + Wdown
Gui, 9:Add, DropDownList, x307 y70 w115 h20 R39 +AltSubmit vAltWdownAction Choose%AltWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y97 w140 h20 -Multi -WantTab -WantReturn vCustomAltWdownPath, %CustomAltWdownPath%
Gui, 9:Add, Button, x362 y96 w60 h22 g9ButtonBrowse4a v9ButtonBrowse4aTemp, &Browse
Gui, 9:Add, Text, x222 y253 w75 h20 , Shift + Wup
Gui, 9:Add, DropDownList, x307 y250 w115 h21 R39 +AltSubmit vShiftWupAction Choose%ShiftWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y276 w140 h20 -Multi -WantTab -WantReturn vCustomShiftWupPath, %CustomShiftWupPath%
Gui, 9:Add, Button, x362 y275 w60 h22 g9ButtonBrowse5a v9ButtonBrowse5aTemp, &Browse
Gui, 9:Add, Text, x222 y313 w75 h20 , Shift + Wdown
Gui, 9:Add, DropDownList, x307 y310 w115 h21 R39 +AltSubmit vShiftWdownAction Choose%ShiftWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y336 w140 h20 -Multi -WantTab -WantReturn vCustomShiftWdownPath, %CustomShiftWdownPath%
Gui, 9:Add, Button, x362 y335 w60 h22 g9ButtonBrowse6a v9ButtonBrowse6aTemp, &Browse
Gui, 9:Add, Text, x222 y373 w75 h20 , Win + Wup
Gui, 9:Add, DropDownList, x307 y370 w115 h21 R39 +AltSubmit vWinWupAction Choose%WinWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y396 w140 h20 -Multi -WantTab -WantReturn vCustomWinWupPath, %CustomWinWupPath%
Gui, 9:Add, Button, x362 y395 w60 h22 g9ButtonBrowse7a v9ButtonBrowse7aTemp, &Browse
Gui, 9:Add, Text, x222 y433 w75 h20 , Win + Wdown
Gui, 9:Add, DropDownList, x307 y430 w115 h21 R39 +AltSubmit vWinWdownAction Choose%WinWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Highlight|Search: Clipboard|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 9:Add, Edit, x222 y456 w140 h20 -Multi -WantTab -WantReturn vCustomWinWdownPath, %CustomWinWdownPath%
Gui, 9:Add, Button, x362 y455 w60 h22 g9ButtonBrowse8a v9ButtonBrowse8aTemp, &Browse
Gui, 9:Font, CMaroon s9, Arial, 
Gui, 9:Add, Text, x12 y491 w230 h40 , Left / Right :  Mouse click`nWup / Wdown :  Scroll wheel
Gui, 9:Font, norm, 
CustomCtrlLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomCtrlRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomCtrlWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomCtrlWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomAltLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomAltRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomAltWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomAltWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomShiftLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomShiftRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomShiftWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomShiftWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomWinLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomWinRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomWinWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomWinWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
9ButtonBrowse1Temp_TT := "Browse for an executable"
9ButtonBrowse2Temp_TT := "Browse for an executable"
9ButtonBrowse3Temp_TT := "Browse for an executable"
9ButtonBrowse4Temp_TT := "Browse for an executable"
9ButtonBrowse5Temp_TT := "Browse for an executable"
9ButtonBrowse6Temp_TT := "Browse for an executable"
9ButtonBrowse7Temp_TT := "Browse for an executable"
9ButtonBrowse8Temp_TT := "Browse for an executable"
9ButtonBrowse1aTemp_TT := "Browse for an executable"
9ButtonBrowse2aTemp_TT := "Browse for an executable"
9ButtonBrowse3aTemp_TT := "Browse for an executable"
9ButtonBrowse4aTemp_TT := "Browse for an executable"
9ButtonBrowse5aTemp_TT := "Browse for an executable"
9ButtonBrowse6aTemp_TT := "Browse for an executable"
9ButtonBrowse7aTemp_TT := "Browse for an executable"
9ButtonBrowse8aTemp_TT := "Browse for an executable"
CtrlLeftAction_TT := "Choose an action to run on pressing Ctrl and Left mouse buttons"
CtrlRightAction_TT := "Choose an action to run on pressing Ctrl and Right mouse buttons"
CtrlWupAction_TT := "Choose an action to run on pressing Ctrl and Wheel-up mouse buttons"
CtrlWdownAction_TT := "Choose an action to run on pressing Ctrl and Wheel-down mouse buttons"
AltLeftAction_TT := "Choose an action to run on pressing Alt and Left mouse buttons"
AltRightAction_TT := "Choose an action to run on pressing Alt and Right mouse buttons"
AltWupAction_TT := "Choose an action to run on pressing Alt and Wheel-up mouse buttons"
AltWdownAction_TT := "Choose an action to run on pressing Alt and Wheel-down mouse buttons"
ShiftLeftAction_TT := "Choose an action to run on pressing Shift and Left mouse buttons"
ShiftRightAction_TT := "Choose an action to run on pressing Shift and Right mouse buttons"
ShiftWupAction_TT := "Choose an action to run on pressing Shift and Wheel-up mouse buttons"
ShiftWdownAction_TT := "Choose an action to run on pressing Shift and Wheel-down mouse buttons"
WinLeftAction_TT := "Choose an action to run on pressing Win and Left mouse buttons"
WinRightAction_TT := "Choose an action to run on pressing Win and Right mouse buttons"
WinWupAction_TT := "Choose an action to run on pressing Win and Wheel-up mouse buttons"
WinWdownAction_TT := "Choose an action to run on pressing Win and Wheel-down mouse buttons"
9OKtemp_TT := "Click to save changes"
9HelpTemp_TT := "Click to get help"
9CancelTemp_TT := "Click to save changes"
; Generated using SmartGUI Creator 4.0
Gui, 9:Show, h532 w432, Custom Hotkeys: Ctrl/Alt/Shift/Win
If (chkMod=1) { ; if ctrl
	GuiControl,9:Disable,9ButtonBrowse1aTemp
	GuiControl,9:Disable,9ButtonBrowse2aTemp
	GuiControl,9:Disable,CtrlWupAction
	GuiControl,9:Disable,CtrlWdownAction
	GuiControl,9:Disable,CustomCtrlWupPath
	GuiControl,9:Disable,CustomCtrlWdownPath
} else if (chkMod=2) { ; if alt
	GuiControl,9:Disable,9ButtonBrowse3aTemp
	GuiControl,9:Disable,9ButtonBrowse4aTemp
	GuiControl,9:Disable,AltWupAction
	GuiControl,9:Disable,AltWdownAction
	GuiControl,9:Disable,CustomAltWupPath
	GuiControl,9:Disable,CustomAltWdownPath
} else if (chkMod=3) { ; if shift
	GuiControl,9:Disable,9ButtonBrowse5aTemp
	GuiControl,9:Disable,9ButtonBrowse6aTemp
	GuiControl,9:Disable,ShiftWupAction
	GuiControl,9:Disable,ShiftWdownAction
	GuiControl,9:Disable,CustomShiftWupPath
	GuiControl,9:Disable,CustomShiftWdownPath
} else if (chkMod=4) { ; if win
	GuiControl,9:Disable,9ButtonBrowse7aTemp
	GuiControl,9:Disable,9ButtonBrowse8aTemp
	GuiControl,9:Disable,WinWupAction
	GuiControl,9:Disable,WinWdownAction
	GuiControl,9:Disable,CustomWinWupPath
	GuiControl,9:Disable,CustomWinWdownPath
}

return

9ButtonHelp:
Msgbox, 262208, Help: Customize Ctrl/Alt/Shift/Win, 16 hotkeys made of modifier keys (Ctrl, Alt, Shift and Win) are customizable for doing anything such as Speak, Google, Timer, Eject CD, Monitor Off, Always On Top, or running any application or command. Their actions can be specified here.`n`nFor example, to make any window "Always on top" with an [Alt+Wheel-up] hotkey, at 'Alt + Wup', choose 'Always on top'.`n`nNote: Choose 'Custom (define)' from the built-in functions (dropdown menu) before specifying an action in the Custom bar. `n`nTip 1: Some functions are better done with Wheel-up/down, while some are better with Left/Right click. It takes some time/patience/curiosity to find out.`n`nTip 2: Chrome users should avoid using Ctrl+Wheelup or Wheeldown as Chrome uses those for enlarging page size.
return


9ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
if CustomCtrlLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlLeftPath, %CustomCtrlLeftPath%
if CustomCtrlRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlRightPath, %CustomCtrlRightPath%
if CustomCtrlWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlWupPath, %CustomCtrlWupPath%
if CustomCtrlWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomCtrlWdownPath, %CustomCtrlWdownPath%
if CustomAltLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltLeftPath, %CustomAltLeftPath%
if CustomAltRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltRightPath, %CustomAltRightPath%
if CustomAltWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltWupPath, %CustomAltWupPath%
if CustomAltWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomAltWdownPath, %CustomAltWdownPath%
if CustomShiftLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftLeftPath, %CustomShiftLeftPath%
if CustomShiftRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftRightPath, %CustomShiftRightPath%
if CustomShiftWupPath
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftWupPath, %CustomShiftWupPath%
if CustomShiftWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomShiftWdownPath, %CustomShiftWdownPath%
if CustomWinLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinLeftPath, %CustomWinLeftPath%
if CustomWinRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinRightPath, %CustomWinRightPath%
if CustomWinWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinWupPath, %CustomWinWupPath%
if CustomWinWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomWinWdownPath, %CustomWinWdownPath%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlLeftAction, %CtrlLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlRightAction, %CtrlRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlWupAction, %CtrlWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CtrlWdownAction, %CtrlWdownAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltLeftAction, %AltLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltRightAction, %AltRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltWupAction, %AltWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, AltWdownAction, %AltWdownAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftLeftAction, %ShiftLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftRightAction, %ShiftRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftWupAction, %ShiftWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ShiftWdownAction, %ShiftWdownAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinLeftAction, %WinLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinRightAction, %WinRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinWupAction, %WinWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WinWdownAction, %WinWdownAction%
return

9ButtonBrowse1:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomCtrlLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomCtrlLeftPath
{
	GuiControl,9:,CustomCtrlLeftPath,%CustomCtrlLeftPath%
}
return

9ButtonBrowse2:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomCtrlRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomCtrlRightPath
{
	GuiControl,9:,CustomCtrlRightPath,%CustomCtrlRightPath%
}
return

9ButtonBrowse3:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomAltLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomAltLeftPath
{
	GuiControl,9:,CustomAltLeftPath,%CustomAltLeftPath%
}
return

9ButtonBrowse4:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomAltRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomAltRightPath
{
	GuiControl,9:,CustomAltRightPath,%CustomAltRightPath%
}
return

9ButtonBrowse5:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomShiftLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomShiftLeftPath
{
	GuiControl,9:,CustomShiftLeftPath,%CustomShiftLeftPath%
}
return

9ButtonBrowse6:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomShiftRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomShiftRightPath
{
	GuiControl,9:,CustomShiftRightPath,%CustomShiftRightPath%
}
return

9ButtonBrowse7:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomWinLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomWinLeftPath
{
	GuiControl,9:,CustomWinLeftPath,%CustomWinLeftPath%
}
return

9ButtonBrowse8:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomWinRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomWinRightPath
{
	GuiControl,9:,CustomWinRightPath,%CustomWinRightPath%
}
return


9ButtonBrowse1a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomCtrlWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomCtrlWupPath
{
	GuiControl,9:,CustomCtrlWupPath,%CustomCtrlWupPath%
}
return

9ButtonBrowse2a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomCtrlWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomCtrlWdownPath
{
	GuiControl,9:,CustomCtrlWdownPath,%CustomCtrlWdownPath%
}
return

9ButtonBrowse3a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomAltWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomAltWupPath
{
	GuiControl,9:,CustomAltWupPath,%CustomAltWupPath%
}
return

9ButtonBrowse4a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomAltWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomAltWdownPath
{
	GuiControl,9:,CustomAltWdownPath,%CustomAltWdownPath%
}
return

9ButtonBrowse5a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomShiftWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomShiftWupPath
{
	GuiControl,9:,CustomShiftWupPath,%CustomShiftWupPath%
}
return

9ButtonBrowse6a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomShiftWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomShiftWdownPath
{
	GuiControl,9:,CustomShiftWdownPath,%CustomShiftWdownPath%
}
return

9ButtonBrowse7a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomWinWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomWinWupPath
{
	GuiControl,9:,CustomWinWupPath,%CustomWinWupPath%
}
return

9ButtonBrowse8a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomWinWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomWinWdownPath
{
	GuiControl,9:,CustomWinWdownPath,%CustomWinWdownPath%
}
return

8ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
if CustomBackLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomBackLeftPath, %CustomBackLeftPath%
if CustomBackRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomBackRightPath, %CustomBackRightPath%
if CustomBackWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomBackWupPath, %CustomBackWupPath%
if CustomBackWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomBackWdownPath, %CustomBackWdownPath%
if CustomForwardLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomForwardLeftPath, %CustomForwardLeftPath%
if CustomForwardRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomForwardRightPath, %CustomForwardRightPath%
if CustomForwardWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomForwardWupPath, %CustomForwardWupPath%
if CustomForwardWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomForwardWdownPath, %CustomForwardWdownPath%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackLeftAction, %BackLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackRightAction, %BackRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackWupAction, %BackWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, BackWdownAction, %BackWdownAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardLeftAction, %ForwardLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardRightAction, %ForwardRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardWupAction, %ForwardWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ForwardWdownAction, %ForwardWdownAction%
return

8ButtonBrowse1:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomBackLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomBackLeftPath
{
	GuiControl,8:,CustomBackLeftPath,%CustomBackLeftPath%
}
return

8ButtonBrowse2:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomBackRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomBackRightPath
{
	GuiControl,8:,CustomBackRightPath,%CustomBackRightPath%
}
return

8ButtonBrowse3:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomForwardLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomForwardLeftPath
{
	GuiControl,8:,CustomForwardLeftPath,%CustomForwardLeftPath%
}
return

8ButtonBrowse4:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomForwardRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomForwardRightPath
{
	GuiControl,8:,CustomForwardRightPath,%CustomForwardRightPath%
}
return

8ButtonBrowse1a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomBackWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomBackWupPath
{
	GuiControl,8:,CustomBackWupPath,%CustomBackWupPath%
}
return

8ButtonBrowse2a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomBackWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomBackWdownPath
{
	GuiControl,8:,CustomBackWdownPath,%CustomBackWdownPath%
}
return

8ButtonBrowse3a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomForwardWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomForwardWupPath
{
	GuiControl,8:,CustomForwardWupPath,%CustomForwardWupPath%
}
return

8ButtonBrowse4a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomForwardWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomForwardWdownPath
{
	GuiControl,8:,CustomForwardWdownPath,%CustomForwardWdownPath%
}
return


CustomizeLeftRight:
Gui, 11:+owner1
;Gui, +Disabled
;Gui, 11:-MinimizeBox -MaximizeBox 
Gui, 11:+ToolWindow
Gui, 11:Font, s8, Tahoma
Gui, 11:Add, Edit, x12 y37 w140 h20 -Multi -WantTab -WantReturn vCustomLeftMiddlePath, %CustomLeftMiddlePath%
Gui, 11:Add, Text, x12 y13 w75 h20 , Left + Middle
Gui, 11:Add, Button, x152 y36 w60 h22 g11ButtonBrowse1 v11ButtonBrowse1Temp, &Browse
Gui, 11:Add, DropDownList, x97 y10 w115 h21 R41 +AltSubmit vLeftMiddleAction Choose%LeftMiddleAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Text, x12 y73 w75 h20 , Left + Right
Gui, 11:Add, DropDownList, x97 y70 w115 h21 R41 +AltSubmit vLeftRightAction Choose%LeftRightAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, DropDownList, x97 y130 w115 h21 R41 +AltSubmit vRightLeftAction Choose%RightLeftAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Edit, x12 y97 w140 h20 -Multi -WantTab -WantReturn vCustomLeftRightPath, %CustomLeftRightPath%
Gui, 11:Add, Button, x152 y96 w60 h22 g11ButtonBrowse2 v11ButtonBrowse2Temp, B&rowse
Gui, 11:Add, Text, x12 y133 w75 h20 , Right + Left
Gui, 11:Add, Edit, x12 y157 w140 h20 -Multi -WantTab -WantReturn vCustomRightLeftPath, %CustomRightLeftPath%
Gui, 11:Add, Button, x152 y156 w60 h22 g11ButtonBrowse3 v11ButtonBrowse3Temp, Bro&wse
Gui, 11:Add, Text, x12 y193 w75 h20 , Right + Middle
Gui, 11:Add, DropDownList, x97 y190 w115 h21 R41 +AltSubmit vRightMiddleAction Choose%RightMiddleAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: on Hover|Search: Highlight|Search: Clipboard|Speak: on Hover|Speak: Highlight|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic zoom (7/vista)|Elastic still zoom|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Edit, x12 y217 w140 h20 -Multi -WantTab -WantReturn vCustomRightMiddlePath, %CustomRightMiddlePath%
Gui, 11:Add, Button, x152 y216 w60 h22 g11ButtonBrowse4 v11ButtonBrowse4Temp, Brow&se
Gui, 11:Add, Button, x242 y247 w60 h30 Default v11OKtemp, &OK
Gui, 11:Add, Button, x362 y247 w60 h30 v11HelpTemp, &Help
Gui, 11:Add, Button, x302 y247 w60 h30 v11CancelTemp, &Cancel
Gui, 11:Add, Text, x222 y13 w75 h20 , Left + Wup
Gui, 11:Add, DropDownList, x307 y10 w115 h21 R37 +AltSubmit vLeftWupAction Choose%LeftWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Edit, x222 y37 w140 h20 -Multi -WantTab -WantReturn vCustomLeftWupPath, %CustomLeftWupPath%
Gui, 11:Add, Button, x362 y36 w60 h22 g11ButtonBrowse1a v11ButtonBrowse1aTemp, &Browse
Gui, 11:Add, Text, x222 y73 w75 h20 , Left + Wdown
Gui, 11:Add, DropDownList, x307 y70 w115 h21 R37 +AltSubmit vLeftWdownAction Choose%LeftWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Edit, x222 y97 w140 h20 -Multi -WantTab -WantReturn vCustomLeftWdownPath, %CustomLeftWdownPath%
Gui, 11:Add, Button, x362 y96 w60 h22 g11ButtonBrowse2a v11ButtonBrowse2aTemp, &Browse
Gui, 11:Add, Text, x222 y133 w75 h20 , Right + Wup
Gui, 11:Add, DropDownList, x307 y130 w115 h21 R37 +AltSubmit vRightWupAction Choose%RightWupAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Edit, x222 y157 w140 h20 -Multi -WantTab -WantReturn vCustomRightWupPath, %CustomRightWupPath%
Gui, 11:Add, Button, x362 y156 w60 h22 g11ButtonBrowse3a v11ButtonBrowse3aTemp, &Browse
Gui, 11:Add, Text, x222 y193 w75 h20 , Right + Wdown
Gui, 11:Add, DropDownList, x307 y190 w115 h21 R37 +AltSubmit vRightWdownAction Choose%RightWdownAction%, New snip|Kill magnifier|Invert color (7/vista)|Mouse (7/vista)|Keyboard (7/vista)|Text (7/vista)|ZoomIt: Type|ZoomIt: Live zoom|ZoomIt: Still zoom|ZoomIt: Draw|ZoomIt: Timer|ZoomIt: Black|ZoomIt: White|Notepad|Wordpad|Calculator|Paint|Search: Clipboard|Speak: Clipboard|Monitor off|Eject disc|Always on top|Aero Timer Web|Timer Tab|Zoom faster (7)|Zoom slower (7)|Elastic live zoom|Elastic still zoom (fixed)|Snip: Free (7/vista)|Snip: Rect (7/vista)|Snip: Window (7/vista)|Snip: Screen (7/vista)|Show/hide magnifier|Show/hide panel|Preview full screen (7)|Custom (define)|None
Gui, 11:Add, Edit, x222 y217 w140 h20 -Multi -WantTab -WantReturn vCustomRightWdownPath, %CustomRightWdownPath%
Gui, 11:Add, Button, x362 y216 w60 h22 g11ButtonBrowse4a v11ButtonBrowse4aTemp, &Browse
Gui, 11:Font, CMaroon s9, Arial
Gui, 11:Add, Text, x12 y247 w230 h30 , Left / Middle / Right :  Mouse click`nWup / Wdown :  Scroll wheel
Gui, 11:Font, norm, 
LeftMiddleAction_TT := "Choose an action to run on pressing Left and Middle mouse buttons"
LeftRightAction_TT := "Choose an action to run on pressing Left and Right mouse buttons"
LeftWupAction_TT := "Choose an action to run on pressing Left and Wheel-up mouse buttons"
LeftWdownAction_TT := "Choose an action to run on pressing Left and Wheel-down mouse buttons"
RightLeftAction_TT := "Choose an action to run on pressing Right and Left mouse buttons"
RightMiddleAction_TT := "Choose an action to run on pressing Right and Middle mouse buttons"
RightWupAction_TT := "Choose an action to run on pressing Right and Wheel-up mouse buttons"
RightWdownAction_TT := "Choose an action to run on pressing Right and Wheel-down mouse buttons"
CustomLeftMiddlePath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomLeftRightPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomLeftWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomLeftWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomRightLeftPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomRightMiddlePath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomRightWupPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
CustomRightWdownPath_TT := "If 'Custom (define)' is chosen above, specify here a program to run"
11ButtonBrowse1Temp_TT := "Browse for an executable"
11ButtonBrowse2Temp_TT := "Browse for an executable"
11ButtonBrowse3Temp_TT := "Browse for an executable"
11ButtonBrowse4Temp_TT := "Browse for an executable"
11ButtonBrowse1aTemp_TT := "Browse for an executable"
11ButtonBrowse2aTemp_TT := "Browse for an executable"
11ButtonBrowse3aTemp_TT := "Browse for an executable"
11ButtonBrowse4aTemp_TT := "Browse for an executable"
11OKtemp_TT := "Click to save changes"
11HelpTemp_TT := "Click to get help"
11CancelTemp_TT := "Click to save changes"
Gui, 11:Show, h285 w432, Customize Left and Right

; disable in all ahk because left and right / right and left dont work yet.
; GuiControl,11:Disable,LeftRightAction
; GuiControl,11:Disable,CustomLeftRightPath
; GuiControl,11:Disable,11ButtonBrowse2Temp

; GuiControl,11:Disable,RightLeftAction
; GuiControl,11:Disable,CustomRightLeftPath
; GuiControl,11:Disable,11ButtonBrowse3Temp

If (chkMod=5) { ; if Left
	GuiControl,11:Disable,11ButtonBrowse1Temp
;	GuiControl,11:Disable,LeftWupAction
;	GuiControl,11:Disable,LeftWdownAction
	GuiControl,11:Disable,LeftMiddleAction
;	GuiControl,11:Disable,11ButtonBrowse1aTemp
;	GuiControl,11:Disable,11ButtonBrowse2aTemp
;	GuiControl,11:Disable,CustomLeftWupPath
;	GuiControl,11:Disable,CustomLeftWdownPath
	GuiControl,11:Disable,CustomLeftMiddlePath
;	GuiControl,11:Disable,11ButtonBrowse3Temp ; disable right and left/left and right in both too
;	GuiControl,11:Disable,RightLeftAction ; disable ...
;	GuiControl,11:Disable,CustomRightLeftPath  ; disable ...
} else if (chkMod=6) { ; if Right
	GuiControl,11:Disable,11ButtonBrowse4Temp
;	GuiControl,11:Disable,RightWupAction
;	GuiControl,11:Disable,RightWdownAction
	GuiControl,11:Disable,RightMiddleAction
;	GuiControl,11:Disable,11ButtonBrowse3aTemp
;	GuiControl,11:Disable,11ButtonBrowse4aTemp
;	GuiControl,11:Disable,CustomRightWupPath
;	GuiControl,11:Disable,CustomRightWdownPath
	GuiControl,11:Disable,CustomRightMiddlePath
;	GuiControl,11:Disable,11ButtonBrowse2Temp ; disable right and left/left and right in both too
;	GuiControl,11:Disable,LeftRightAction ; disable ...
;	GuiControl,11:Disable,CustomLeftRightPath ; disable ...
}
Return

11ButtonHelp:
Msgbox, 262208, Help: Customize Left and Right, AeroZoom enhances mouse devices with Left and Right buttons by adding 8 more mouse hotkeys`, which can be customized here for doing tasks such as Speak, Google, Eject CD, ZoomIt, Monitor Off or running any command or application.`n`nNote: Choose 'Custom (define)' from the built-in functions (dropdown menu) before specifying an action in the Custom bar.`n`nTip 1: Some functions may not be suitable for Left or Right. Use other 'Custom Hotkeys' options in 'Tool > Preferences' instead.`n`nTip 2: Hold 'Left'/'Right' longer before release to avoid sending a click (of Left/Right) to the app behind.
return


11ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
if CustomLeftMiddlePath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomLeftMiddlePath, %CustomLeftMiddlePath%
if CustomLeftRightPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomLeftRightPath, %CustomLeftRightPath%
if CustomLeftWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomLeftWupPath, %CustomLeftWupPath%
if CustomLeftWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomLeftWdownPath, %CustomLeftWdownPath%
if CustomRightLeftPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomRightLeftPath, %CustomRightLeftPath%
if CustomRightMiddlePath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomRightMiddlePath, %CustomRightMiddlePath%
if CustomRightWupPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomRightWupPath, %CustomRightWupPath%
if CustomRightWdownPath 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CustomRightWdownPath, %CustomRightWdownPath%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftMiddleAction, %LeftMiddleAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftRightAction, %LeftRightAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftWupAction, %LeftWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, LeftWdownAction, %LeftWdownAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightLeftAction, %RightLeftAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightMiddleAction, %RightMiddleAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightWupAction, %RightWupAction%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, RightWdownAction, %RightWdownAction%
return

11ButtonBrowse1:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomLeftMiddlePath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomLeftMiddlePath
{
	GuiControl,11:,CustomLeftMiddlePath,%CustomLeftMiddlePath%
}
return

11ButtonBrowse2:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomLeftRightPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomLeftRightPath
{
	GuiControl,11:,CustomLeftRightPath,%CustomLeftRightPath%
}
return

11ButtonBrowse3:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomRightLeftPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomRightLeftPath
{
	GuiControl,11:,CustomRightLeftPath,%CustomRightLeftPath%
}
return

11ButtonBrowse4:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomRightMiddlePath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomRightMiddlePath
{
	GuiControl,11:,CustomRightMiddlePath,%CustomRightMiddlePath%
}
return

11ButtonBrowse1a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomLeftWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomLeftWupPath
{
	GuiControl,11:,CustomLeftWupPath,%CustomLeftWupPath%
}
return

11ButtonBrowse2a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomLeftWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomLeftWdownPath
{
	GuiControl,11:,CustomLeftWdownPath,%CustomLeftWdownPath%
}
return

11ButtonBrowse3a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomRightWupPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomRightWupPath
{
	GuiControl,11:,CustomRightWupPath,%CustomRightWupPath%
}
return

11ButtonBrowse4a:
Gui, 1:-AlwaysOnTop
FileSelectFile, CustomRightWdownPath, 3, , Select something to launch, 
If onTopBit
	Gui, 1:+AlwaysOnTop
if CustomRightWdownPath
{
	GuiControl,11:,CustomRightWdownPath,%CustomRightWdownPath%
}
return

11ButtonCancel:
11GuiClose:
11GuiEscape:

9ButtonCancel:
9GuiClose:
9GuiEscape:

8ButtonCancel:
8GuiClose:
8GuiEscape:

Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Destroy
return

; --
; Custom Hotkey (Part 3) End
; --

6ButtonCancel:
6GuiClose:
6GuiEscape:

If (OSver<6.1) { ; vista or xp uses the snipslider
	GuiControl,1:, SnipSlider, 1 ; restore slider to original position on cancel
}
onlyDownloadNirCmd = ; Button 6 requires this to skip displaying unrelated message

10ButtonCancel:
10GuiClose:
10GuiEscape:

7ButtonCancel:
7GuiClose:
7GuiEscape:

Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Gui, Destroy
return

4ButtonCancel:
4GuiClose:   ; On "Close" button press
4GuiEscape:   ; On ESC press
Gui, 1:-Disabled  ; Re-enable the main window (must be done prior to the next step).
Menu, ToolboxMenu, Uncheck, &Use ZoomIt as Magnifier
Menu, ViewsMenu, Disable, Sysinternals &ZoomIt
zoomit=0
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIt, 0
Gui, Destroy
return

6ButtonBrowse:
Gui, 1:-AlwaysOnTop
FileSelectFile, userNirCmdPath, 3, , Select NirCmd.exe, NirCmd v2.05+ (NirCmd.exe)
If onTopBit
	Gui, 1:+AlwaysOnTop
if userNirCmdPath
{
	GuiControl,6:,userNirCmdPath,%userNirCmdPath%
}
return

4ButtonBrowse:
Gui, 1:-AlwaysOnTop
FileSelectFile, userZoomItPath, 3, , Select ZoomIt.exe, ZoomIt v4.0+ (ZoomIt.exe)
If onTopBit
	Gui, 1:+AlwaysOnTop
if userZoomItPath
{
	GuiControl,4:,userZoomItPath,%userZoomItPath%
}
return

6ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
IfWinExist, AeroZoom Panel
	Menu, ToolboxMenu, Disable, &Save Captures
Gui, 1:Font, CRed,
GuiControl,1:Font,Txt, ; to apply the color change 
GuiControl,1:,Txt,- Please Wait -
Haystack = %userNirCmdPath%
Needle = http://
IfNotInString, Haystack, %Needle%
{
	IfNotExist, %userNirCmdPath%
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%userNirCmdPath%
		Gui, 1:Font, c666666
		GuiControl,1:Font,Txt,	
		GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
		;Gui,-Disabled
		IfWinExist, AeroZoom Panel
			Menu, ToolboxMenu, Enable, &Save Captures
		If (OSver<6.1) { ; vista or xp uses the snipslider
			GuiControl,1:, SnipSlider, 1 ; restore slider to original position on cancel
		}
		return
	}
	FileCopy, %userNirCmdPath%, %A_WorkingDir%\Data\NirCmd.exe
	IfNotExist, %userNirCmdPath%
	{
		Msgbox, 262192, ERROR, File copy failed:`n`n%userNirCmdPath%`n`nEnsure destination is not locked.
		Gui, 1:Font, c666666
		GuiControl,1:Font,Txt,	
		GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
		;Gui,-Disabled
		IfWinExist, AeroZoom Panel
			Menu, ToolboxMenu, Enable, &Save Captures
		If (OSver<6.1) { ; vista or xp uses the snipslider
			GuiControl,1:, SnipSlider, 1 ; restore slider to original position on cancel
		}
		return
	}
	goto, SkipNirCmdDownload
}
GuiControl,1:Disable,Bye
if not GuideDisabled
	Msgbox, 262208, IMPORTANT, Please do not close or use AeroZoom during download.`n`nIf you suspect the download failed and NirCmd.exe (30+ KB) is corrupt (sign: strange errors during snipping), do a reset in Tool > Preferences > Advanced Options.`n`nAlternatively, you can manually delete or put NirCmd.exe into:`n`n%A_WorkingDir%\Data
GuiControl,1:,Txt,- Downloading -
Gui, 1:-AlwaysOnTop 
;Gui,+Disabled ; To prevent user from moving panel. Now allow commented user to do so as download may take long.
RunWait, "%A_WorkingDir%\Data\3rdparty\wget.exe" -U "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+" --output-document="%A_WorkingDir%\Data\NirCmd.exe" "%userNirCmdPath%"
;UrlDownloadToFile, %userNirCmdPath%, %A_WorkingDir%\Data\NirCmd.exe
if (errorlevel<>0) {
	Msgbox, 262192, AeroZoom, Cannot download the file. Check Internet connection.`n`nYou may also manually put NirCmd.exe into:`n`n%A_WorkingDir%\Data
	FileDelete, %A_WorkingDir%\Data\NirCmd.exe
	Gui, 1:Font, c666666
	GuiControl,1:Font,Txt,	
	GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
	;Gui,-Disabled
	GuiControl,1:Enable,Bye
	IfWinExist, AeroZoom Panel
		Menu, ToolboxMenu, Enable, &Save Captures
	If (OSver<6.1) { ; vista or xp uses the snipslider
		GuiControl,1:, SnipSlider, 1 ; restore slider to original position on cancel
	}
	If onTopBit
		Gui, 1:+AlwaysOnTop
	return
}
If onTopBit
	Gui, 1:+AlwaysOnTop
SkipNirCmdDownload:
Gui, 1:Font, c666666
GuiControl,1:Font,Txt,	
GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
GuiControl,1:Enable,Bye
;Gui,-Disabled
IfWinExist, AeroZoom Panel
	Menu, ToolboxMenu, Enable, &Save Captures
if not onlyDownloadNirCmd
{
	Msgbox, 262144, AeroZoom, Success.
	goto, NirCmd
} else {
	Msgbox, 262144, AeroZoom, Success.
}
onlyDownloadNirCmd=
return

4ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
Menu, ToolboxMenu, Disable, &Use ZoomIt as Magnifier
Gui, 1:Font, CRed,
GuiControl,1:Font,Txt, ; to apply the color change 
GuiControl,1:,Txt,- Please Wait -

; The followings need to be the default hotkeys, i.e. Ctrl+3 (Timer) and Ctrl+2 (Draw) for the function to work.
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, DrawToggleKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, BreakTimerKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, ToggleKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, LiveZoomToggleKey
RegDelete, HKEY_CURRENT_USER, Software\Sysinternals\ZoomIt, EulaAccepted ; force user to reaccept EULA

Haystack = %userZoomItPath%
Needle = http://
IfNotInString, Haystack, %Needle%
{
	IfNotExist, %userZoomItPath%
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%userZoomItPath%
		Gui, 1:Font, c666666
		GuiControl,1:Font,Txt,	
		GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
		;Gui,-Disabled
		Menu, ToolboxMenu, Enable, &Use ZoomIt as Magnifier
		return
	}
	FileCopy, %userZoomItPath%, %A_WorkingDir%\Data\ZoomIt.exe
	IfNotExist, %userZoomItPath%
	{
		Msgbox, 262192, ERROR, File copy failed:`n`n%userZoomItPath%`n`nEnsure destination is not locked.
		Gui, 1:Font, c666666
		GuiControl,1:Font,Txt,	
		GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
		;Gui,-Disabled
		Menu, ToolboxMenu, Enable, &Use ZoomIt as Magnifier
		return
	}
	goto, SkipZoomItDownload
}
GuiControl,1:Disable,Bye
if not GuideDisabled
	Msgbox, 262208, IMPORTANT, Please do not close or use AeroZoom during download.`n`nIf you suspect the download failed and ZoomIt.exe (500+ KB) is corrupt (sign: strange errors during use), do a reset in Tool > Preferences > Advanced Options.`n`nAlternatively, you can manually delete or put ZoomIt.exe into:`n`n%A_WorkingDir%\Data
GuiControl,1:,Txt,- Downloading -
Gui, 1:-AlwaysOnTop
;Gui,+Disabled ; To prevent user from moving panel. Now allow commented user to do so as download may take long.
RunWait, "%A_WorkingDir%\Data\3rdparty\wget.exe" -U "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+" --output-document="%A_WorkingDir%\Data\ZoomIt.exe" "%userZoomItPath%"
;UrlDownloadToFile, %userZoomItPath%, %A_WorkingDir%\Data\ZoomIt.exe
if (errorlevel<>0) {
	Msgbox, 262192, AeroZoom, Cannot download the file. Check Internet connection.`n`nYou may also manually put zoomit.exe into:`n`n%A_WorkingDir%\Data
	FileDelete, %A_WorkingDir%\Data\ZoomIt.exe
	Gui, 1:Font, c666666
	GuiControl,1:Font,Txt,	
	GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
	;Gui,-Disabled
	GuiControl,1:Enable,Bye
	Menu, ToolboxMenu, Enable, &Use ZoomIt as Magnifier
	If onTopBit
		Gui, 1:+AlwaysOnTop
	return
}
If onTopBit
	Gui, 1:+AlwaysOnTop
SkipZoomItDownload:
Gui, 1:Font, c666666
GuiControl,1:Font,Txt,	
Menu, ToolboxMenu, Enable, &Use ZoomIt as Magnifier
GuiControl,1:,Txt, A e r o Z o o m ; v%verAZ%
GuiControl,1:Enable,Bye
;Gui,-Disabled
Msgbox, 262144, AeroZoom, Success.`n`nZoomIt will run in system tray alongside AeroZoom from now on.`n`nFunctions of ZoomIt such as pen color are accessible with slider and buttons on the AeroZoom Panel. Enable/disable this feature (ZoomIt Panel) anytime by clicking the small 'zoom' button near the bottom of the panel.`n`nElastic still zoom is also available now. You may press [Shift+Caps Lock] to try it after clicking OK. (Note: Elastic live zoom [Ctrl+Caps Lock] requires Vista or later.)`n`nYou may also define hotkeys to access any ZoomIt functions more conveniently at 'Tool > Preferences > Custom Hotkeys.`n`nStill/Live Zoom of ZoomIt is automatically used for wheel-zoom on systems without Aero (Windows 7 Home Basic/Starter) or older systems (Vista/XP).`n`nFor usage and help, press [Win]+[Alt]+[Q] anytime, or go to '? > Quick Instructions > ZoomIt'.
skipEulaChk=1
ZoomItFirstRun=1
goto, ZoomIt
return

ZoomItGuidance:
if not GuideDisabled
{
	Msgbox, 262144, This message will only be shown once, For first-timers, the hotkeys of ZoomIt have been remapped the same in all modes. Just remember: To adjust, [Modifier]+[Wheel-up/down]. To exit, [Modifier]+[Middle]. To leave a sub mode, [Esc]/right-click. (For Live Zoom, holding the modifier is required; for Still Zoom, it is optional.)`n`nCurrent modifier: %modDisp%`n`nAfter clicking OK, a list of all keyboard shortcuts of ZoomIt will be presented for once. It can be viewed anytime at '? > Quick Instructions > ZoomIt', or by pressing [Win]+[Alt]+[Q], Z.
	gosub, ZoomItInstButton
	ZoomItGuidance = 1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomItGuidance, 1
}
Sleep, 500
return

ExportConfig:
gosub, configGuidance
ExportPath=
Gui, 1:-AlwaysOnTop
FileSelectFile, ExportPath, S16, Data\ConfigBackup\ManualBackup.reg, Export config file to, Registry (*.reg)
If onTopBit
	Gui, 1:+AlwaysOnTop
if ExportPath {
	if A_IsAdmin ; invisible to user but requires admin right
	{
		RunWait, "%windir%\regedit.exe" /E "%ExportPath%" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
	}
	Else ; below would show a minimized cmd window for a second
	{
		RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%ExportPath%" /f,,min
	}
}
return

ImportConfig:
gosub, configGuidance
ImportPath=
Gui, 1:-AlwaysOnTop
FileSelectFile, ImportPath, , Data\ConfigBackup\AutoBackup.reg, Import config file from, Registry (*.reg)
If onTopBit
	Gui, 1:+AlwaysOnTop
if ImportPath
{
	IfExist, %ImportPath%
	{
		; Delete existing AeroZoom settings
		RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom
		if A_IsAdmin ; invisible to user but requires admin right
		{
			RunWait, "%windir%\regedit.exe" /S "%ImportPath%", ,min
		}
		Else ; below would show a minimized cmd window for a second
		{
			RunWait, "%windir%\system32\reg.exe" import "%ImportPath%" , ,min
		}
	}
	Else
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%ImportPath%
		return
	}
} else {
	return
}
Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
Gosub, SaveCurrentProfile
reload
return

RestoreDefaultSettings:
; this does not remove zoomit.exe and nircmd.exe (if exist)
; this is a lighter version in comparison to the Reset button in Advaced Options
Gui, 1:-AlwaysOnTop
If onTopBit
	Gui, 1:+AlwaysOnTop
if profileInUse {
	profileInUseDisplay = %profileInUse%
} else {
	profileInUseDisplay = None
}
Msgbox, 262212, Restore Default Settings [Current Profile: %profileInUseDisplay%], Restore AeroZoom to default settings?`n`nNote: This restores the current selected profile of AeroZoom only. To restore all profiles, as well as settings of Windows Magnifier, Snipping Tool, ZoomIt and NirCmd, use "Tool > Preferences > Advanced Options > Reset"
IfMsgbox, No
	return
; Delete existing AeroZoom settings
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom
; if quick profile is in use, restore the current quick profile to its default
If profileInUse {
	FileCopy, %A_WorkingDir%\Data\QuickProfiles\Default\Profile%profileInUse%.reg, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg, 1
	Gosub, LoadDefaultRegImportQuickProfile
}
Msgbox, 262208, Settings Restored, AeroZoom will now quit.
GoSub, CloseMagnifier
ExitApp
;restartRequired=
;reload
return


MouseCenteredZoom:
; Mouse-Centered Zoom
CoordMode, Mouse, Screen
MouseMove, (A_ScreenWidth // 2), (A_ScreenHeight // 2), 0
return

; Both QuickProfileSwitch and AutoConfigBackup
AutoConfigBackupSaveProfile:
; auto config backup
If EnableAutoBackup {
	if A_IsAdmin ; invisible to user but requires admin right
	{
		RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\ConfigBackup\Day%A_DD%_%A_OSVersion%_%A_ComputerName%_%A_UserName%.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
	}
	Else ; below would show a minimized cmd window for a second
	{
		RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\ConfigBackup\Day%A_DD%_%A_OSVersion%_%A_ComputerName%_%A_UserName%.reg" /f,,min
	}
}
; QuickProfileSwitch exports config to the respective profile#.reg whether AutoConfigBackup is enabled or not.
Gosub, SaveCurrentProfile
return

QuickProfile1:
If Not profileInUse {
	Msgbox, 262180, Switching from Disabled to Profile 1, By switching to a profile from a disabled state, current settings will be lost unless manually saved.`n`nClick Yes to continue, or No to cancel.
	IfMsgBox No
		return
} else {
	IfNotExist, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
		return
	}
	; save current setting to current profile before switching to another profile
	Gosub, SaveCurrentProfile
}
profileInUse = 1
; gosub, profileGuidance
Gosub, LoadDefaultRegImportQuickProfile
; in case the reg files have wrong values of profileInUse and profileNames, the below ensures it will work correctly
; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileGuidance, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName1, %profileName1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName2, %profileName2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName3, %profileName3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName4, %profileName4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName5, %profileName5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileInUse, 1
; Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Write current modifier to registry so that the checked modifier is correct on panel after restart
; RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x%chkMod%
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
; reload would not load the correct modifier exe; therefore AeroZoom.exe is rerun instead.
Run, %A_WorkingDir%\AeroZoom.exe
ExitApp
return

QuickProfile2:
If Not profileInUse {
	Msgbox, 262180, Switching from Disabled to Profile 2, By switching to a profile from a disabled state, current settings will be lost unless manually saved.`n`nClick Yes to continue, or No to cancel.
	IfMsgBox No
		return
} else {
	IfNotExist, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
		return
	}
	; save current setting to current profile before switching to another profile
	Gosub, SaveCurrentProfile
}
profileInUse = 2
; gosub, profileGuidance
Gosub, LoadDefaultRegImportQuickProfile
; in case the reg files have wrong values of profileInUse and profileNames, the below ensures it will work correctly
; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileGuidance, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName1, %profileName1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName2, %profileName2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName3, %profileName3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName4, %profileName4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName5, %profileName5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileInUse, 2
; Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Write current modifier to registry so that the checked modifier is correct on panel after restart
; RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x%chkMod%
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
; reload would not load the correct modifier exe; therefore AeroZoom.exe is rerun instead.
Run, %A_WorkingDir%\AeroZoom.exe
ExitApp
return

QuickProfile3:
If Not profileInUse {
	Msgbox, 262180, Switching from Disabled to Profile 3, By switching to a profile from a disabled state, current settings will be lost unless manually saved.`n`nClick Yes to continue, or No to cancel.
	IfMsgBox No
		return
} else {
	IfNotExist, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
		return
	}
	; save current setting to current profile before switching to another profile
	Gosub, SaveCurrentProfile
}
profileInUse = 3
; gosub, profileGuidance
Gosub, LoadDefaultRegImportQuickProfile
; in case the reg files have wrong values of profileInUse and profileNames, the below ensures it will work correctly
; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileGuidance, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName1, %profileName1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName2, %profileName2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName3, %profileName3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName4, %profileName4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName5, %profileName5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileInUse, 3
; Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Write current modifier to registry so that the checked modifier is correct on panel after restart
; RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x%chkMod%
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
; reload would not load the correct modifier exe; therefore AeroZoom.exe is rerun instead.
Run, %A_WorkingDir%\AeroZoom.exe
ExitApp
return

QuickProfile4:
If Not profileInUse {
	Msgbox, 262180, Switching from Disabled to Profile 4, By switching to a profile from a disabled state, current settings will be lost unless manually saved.`n`nClick Yes to continue, or No to cancel.
	IfMsgBox No
		return
} else {
	IfNotExist, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
		return
	}
	; save current setting to current profile before switching to another profile
	Gosub, SaveCurrentProfile
}
profileInUse = 4
; gosub, profileGuidance
Gosub, LoadDefaultRegImportQuickProfile
; in case the reg files have wrong values of profileInUse and profileNames, the below ensures it will work correctly
; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileGuidance, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName1, %profileName1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName2, %profileName2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName3, %profileName3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName4, %profileName4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName5, %profileName5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileInUse, 4
; Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Write current modifier to registry so that the checked modifier is correct on panel after restart
; RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x%chkMod%
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
; reload would not load the correct modifier exe; therefore AeroZoom.exe is rerun instead.
Run, %A_WorkingDir%\AeroZoom.exe
ExitApp
return

QuickProfile5:
If Not profileInUse {
	Msgbox, 262180, Switching from Disabled to Profile 5, By switching to a profile from a disabled state, current settings will be lost unless manually saved.`n`nClick Yes to continue, or No to cancel.
	IfMsgBox No
		return
} else {
	IfNotExist, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
	{
		Msgbox, 262192, ERROR, File does not exist:`n`n%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
		return
	}
	; save current setting to current profile before switching to another profile
	Gosub, SaveCurrentProfile
}
profileInUse = 5
; gosub, profileGuidance
Gosub, LoadDefaultRegImportQuickProfile
; in case the reg files have wrong values of profileInUse and profileNames, the below ensures it will work correctly
; RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileGuidance, 1
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName1, %profileName1%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName2, %profileName2%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName3, %profileName3%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName4, %profileName4%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName5, %profileName5%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileInUse, 5
; Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Write current modifier to registry so that the checked modifier is correct on panel after restart
; RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, Modifier, 0x%chkMod%
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
; reload would not load the correct modifier exe; therefore AeroZoom.exe is rerun instead.
Run, %A_WorkingDir%\AeroZoom.exe
ExitApp
return

QuickProfileDisable:
; save current setting to current profile before disabling profile
Gosub, SaveCurrentProfile

Menu, QuickProfileSwitch, Uncheck, 1. %profileName1%
Menu, QuickProfileSwitch, Uncheck, 2. %profileName2%
Menu, QuickProfileSwitch, Uncheck, 3. %profileName3%
Menu, QuickProfileSwitch, Uncheck, 4. %profileName4%
Menu, QuickProfileSwitch, Uncheck, 5. %profileName5%
Menu, QuickProfileSwitch, Check, Disable Quick Profiles	
Menu, QuickProfileSwitch, Disable, Disable Quick Profiles
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileInUse, 0
profileInUse = 0
; Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Save last AZ window position before exit so that it shows the GUI after restart
WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
GoSub, CloseMagnifier
restartRequired=
; reload would not load the correct modifier exe; therefore AeroZoom.exe is rerun instead.
Run, %A_WorkingDir%\AeroZoom.exe
ExitApp
return

QuickProfileSave1:
if A_IsAdmin ; invisible to user but requires admin right
{
	RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\QuickProfiles\Profile1.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
}
Else ; below would show a minimized cmd window for a second
{
	RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\QuickProfiles\Profile1.reg" /f,,min
}
return

QuickProfileSave2:
if A_IsAdmin ; invisible to user but requires admin right
{
	RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\QuickProfiles\Profile2.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
}
Else ; below would show a minimized cmd window for a second
{
	RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\QuickProfiles\Profile2.reg" /f,,min
}
return

QuickProfileSave3:
if A_IsAdmin ; invisible to user but requires admin right
{
	RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\QuickProfiles\Profile3.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
}
Else ; below would show a minimized cmd window for a second
{
	RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\QuickProfiles\Profile3.reg" /f,,min
}
return

QuickProfileSave4:
if A_IsAdmin ; invisible to user but requires admin right
{
	RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\QuickProfiles\Profile4.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
}
Else ; below would show a minimized cmd window for a second
{
	RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\QuickProfiles\Profile4.reg" /f,,min
}
return

QuickProfileSave5:
if A_IsAdmin ; invisible to user but requires admin right
{
	RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\QuickProfiles\Profile5.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
}
Else ; below would show a minimized cmd window for a second
{
	RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\QuickProfiles\Profile5.reg" /f,,min
}
return

QuickProfileRename1:
InputBox, ProfileUserInput1, Rename Profile 1, Please enter a name for profile 1., , 240, 100
if Not ErrorLevel {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName1, %ProfileUserInput1%
    Msgbox, 262144, Profile 1 Renamed, Profile 1 has been renamed to "%ProfileUserInput1%"
	Goto, RestartAZ
}
return

QuickProfileRename2:
InputBox, ProfileUserInput2, Rename Profile 2, Please enter a name for profile 2., , 240, 100
if Not ErrorLevel {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName2, %ProfileUserInput2%
    Msgbox, 262144, Profile 2 Renamed, Profile 2 has been renamed to "%ProfileUserInput2%"
	Goto, RestartAZ
}
return

QuickProfileRename3:
InputBox, ProfileUserInput3, Rename Profile 3, Please enter a name for profile 3., , 240, 100
if Not ErrorLevel {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName3, %ProfileUserInput3%
    Msgbox, 262144, Profile 3 Renamed, Profile 3 has been renamed to "%ProfileUserInput3%"
	Goto, RestartAZ
}
return

QuickProfileRename4:
InputBox, ProfileUserInput4, Rename Profile 4, Please enter a name for profile 4., , 240, 100
if Not ErrorLevel {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName4, %ProfileUserInput4%
    Msgbox, 262144, Profile 4 Renamed, Profile 4 has been renamed to "%ProfileUserInput4%"
	Goto, RestartAZ
}
return

QuickProfileRename5:
InputBox, ProfileUserInput5, Rename Profile 5, Please enter a name for profile 5., , 240, 100
if Not ErrorLevel {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, profileName5, %ProfileUserInput5%
    Msgbox, 262144, Profile 5 Renamed, Profile 5 has been renamed to "%ProfileUserInput5%"
	Goto, RestartAZ
}
return

MSPaint:
IfWinExist, ahk_class MSPaintApp
	WinActivate
else
	Run,"%windir%\system32\mspaint.exe",,
;Gui, %guiDestroy%
If onTopBit
{
	WinWait, ahk_class MSPaintApp,,3 ; Loop to ensure to wait until the program is run before setting it to Always on Top 
	WinSet, AlwaysOnTop, on, ahk_class MSPaintApp
}
return

Notepad:
IfWinExist, ahk_class Notepad
	WinActivate
else
	Run,"%windir%\system32\notepad.exe",,
;Gui, %guiDestroy%
If onTopBit
{
	WinWait, ahk_class Notepad,,3
	WinSet, AlwaysOnTop, on, ahk_class Notepad
}
return

WordPad:
IfWinExist, ahk_class WordPadClass
	WinActivate
else
{
	IfExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
		Run, %ProgramFiles%\Windows NT\Accessories\wordpad.exe
	IfNotExist, %ProgramFiles%\Windows NT\Accessories\wordpad.exe ; for vista's file virtualization
	{
		IfExist, C:\Program Files\Windows NT\Accessories\wordpad.exe
			Run, C:\Program Files\Windows NT\Accessories\wordpad.exe
	}
}
;Gui, %guiDestroy%
If onTopBit
{
	WinWait, ahk_class WordPadClass,,3
	WinSet, AlwaysOnTop, on, ahk_class WordPadClass
}
return

mscalc:
IfWinExist, ahk_class %calcClass%
{
	WinActivate
}
else
{
	IfExist, %windir%\System32\calc1.exe
		Run,"%windir%\system32\calc1.exe",,
	Else
		Run,"%windir%\system32\calc.exe",,
}
;Gui, %guiDestroy%
If onTopBit
{
	WinWait, ahk_class %calcClass%,,3 ; Loop to ensure to wait until the program is run before setting it to Always on Top 
	WinSet, AlwaysOnTop, on, ahk_class %calcClass%
}
return

configGuidance:
If not configGuidance
{
	if not GuideDisabled
	{
		Msgbox, 262144, This message will only be shown once, Although AeroZoom is portable, its settings are not loaded automatically after switching to another PC in order to prevent incompatibility issues between different Windows versions.`n`nIn case previous settings are preferred, AeroZoom automatically backs up settings up to last 30 days on exit in the following folder:`n`n%A_WorkingDir%\Data\ConfigBackup\`n`nThey can be manually imported at 'Az > Config File'.`n`nAdvice: If possible, do not import settings from a different Windows version. In any case, AeroZoom tries it best to avoid misbehavior. If misbehavior is observed, just reset AeroZoom to factory settings at 'Tool > Preferences > Advanced Options'.
		configGuidance = 1
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, configGuidance, 1
	}
}
return

;unicode (non-ANSI) version of AutoHotKey is required for searching Chinese texts
Google:
IfInString, A_ThisHotkey, LButton
	SendInput {LButton 1}^c ; send once only for Left click to make it double click
Else
	SendInput {LButton 2}^c
Sleep, %delayButton%
Run, http://%googleUrl%/search?&q=%clipboard%
return

GoogleHighlight:
SendInput ^c
Sleep, %delayButton%
Run, http://%googleUrl%/search?&q=%clipboard%
return

GoogleClipboard:
Sleep, %delayButton%
Run, http://%googleUrl%/search?&q=%clipboard%
return

SpeakIt:
IfNotExist, %A_WorkingDir%\Data\NirCmd.exe
	Goto, NirCmdDownloadAlt
IfInString, A_ThisHotkey, LButton
	SendInput {LButton 1}^c ; send once only for Left click to make it double click
Else
	SendInput {LButton 2}^c
Sleep, %delayButton%
Run, "%A_WorkingDir%\Data\NirCmd.exe" speak text %clipboard%,,min ; min is required to avoid nircmd help dialog from prompting at times
return

SpeakHighlight:
IfNotExist, %A_WorkingDir%\Data\NirCmd.exe
	Goto, NirCmdDownloadAlt
SendInput ^c
Sleep, %delayButton%
Run, "%A_WorkingDir%\Data\NirCmd.exe" speak text "%clipboard%",,min
return

SpeakClipboard:
IfNotExist, %A_WorkingDir%\Data\NirCmd.exe
	Goto, NirCmdDownloadAlt
Sleep, %delayButton%
Run, "%A_WorkingDir%\Data\NirCmd.exe" speak text "%clipboard%",,min
return

MonitorOff:
IfNotExist, %A_WorkingDir%\Data\NirCmd.exe
	Goto, NirCmdDownloadAlt
Run, "%A_WorkingDir%\Data\NirCmd.exe" monitor off,,min
return

OpenTray:
Run, "%A_WorkingDir%\Data\OpenTray.exe"
return

AlwaysOnTop:
Winset, AlwaysOnTop, Toggle, A
return

WebTimer:
RegRead,WebTimer1Msg,HKCU,Software\wandersick\AeroZoom,WebTimer1Msg
if errorlevel
{
	if not GuideDisabled
	{
		Msgbox, 262208, This message will only be shown once, Aero Timer Web is a beautiful timer web app by Chinese developer YuAo (www.imyuao.com)`n`nInternet connection is required for use.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WebTimer1Msg, 1
	}
}
Run, http://aerotimer.com
return

TimerTab:
RegRead,WebTimer2Msg,HKCU,Software\wandersick\AeroZoom,WebTimer2Msg
if errorlevel
{
	if not GuideDisabled
	{
		Msgbox, 262208, This message will only be shown once, Timer Tab is a multi-use web app (stopwatch + countdown timer + alarm clock) by developer Romuald Brillout (www.brillout.com)`n`nIt can be used online or offline with Google Chrome or Chrome Frame for IE.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, WebTimer2Msg, 1
	}
}
Run, www.timer-tab.com
return

ElasticZoom:
Process, Close, ZoomPad.exe ; prevent zoompad frame from appearing in zoomit
process, close, osd.exe ; prevent osd from showing
if (OSver=6.0 AND !zoomitStill) OR (OSver>=6.1 AND zoomitLive=1) { ; elastic zoom with zoomit live zoom
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	IfWinExist, ahk_class MagnifierClass ; ZoomIt Live Zoom
	{
		sendinput ^{Up} ; zoom deeper if already in live zoom
	} else {
		sendinput ^4
	}
		KeyWait %hotkeyMod%
		sendinput ^4
} else if (OSver<6 OR zoomitStill) { ; elastic zoom with zoomit still zoom
	Process, Exist, zoomit.exe
	If not errorlevel
	{
		Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
		return
	}
	IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
		goto, zoomit
	IfWinExist, ahk_class ZoomitClass ; ZoomIt Still Zoom
	{
		sendinput {esc} ; exit if already in zoom
	} else {
		WinHide, AeroZoom Panel
		sendinput ^1
		WinWait, ahk_class ZoomitClass,,5
		gosub, ZoomItColor
		KeyWait %hotkeyMod%
		sendinput {esc}
		WinShow, AeroZoom Panel
	}
} else if (OSver>6) {
	if numPadAddBit
		SendInput #{NumpadAdd} ; elastic zoom with win 7 magnifier
	else
		SendInput #{+}
	KeyWait %hotkeyMod%
	if numPadSubBit
		SendInput #{NumpadSub}
	else
		SendInput #{-}
}
return

ElasticStillZoom:
; elastic zoom with zoomit still zoom
Process, Exist, zoomit.exe
If not errorlevel
{
	Msgbox, 262192, ERROR, ZoomIt is not running or zoomit.exe is missing.`n`nPlease click 'Tool > Use ZoomIt as Magnifier'.
	return
}
IfNotExist, %A_WorkingDir%\Data\ZoomIt.exe
	goto, zoomit
IfWinExist, ahk_class ZoomitClass ; ZoomIt Still Zoom
{
	sendinput {esc} ; exit if already in zoom
} else {
	Process, Close, ZoomPad.exe ; prevent zoompad frame from appearing in zoomit
	process, close, osd.exe ; prevent osd from showing in 'picture'
	WinHide, AeroZoom Panel
	sendinput ^1
	WinWait, ahk_class ZoomitClass,,5
	gosub, ZoomItColor
	KeyWait %hotkeyMod%
	sendinput {esc}
	WinShow, AeroZoom Panel
}
return

ZoomFaster: ; this needs to perform better before it can promoted
if (OSver<6.1) {
	return
}

IfWinExist, AeroZoom Panel
	ExistAZ=1
RegRead,zoomIncRaw,HKCU,Software\Microsoft\ScreenMagnifier,ZoomIncrement
if (zoomIncRaw=0x19) {
	if ExistAZ
		GuiControl,, ZoomInc, 2
	zoomInc=2
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x32
} else if (zoomIncRaw=0x32) {
	if ExistAZ
		GuiControl,, ZoomInc, 3
	zoomInc=3
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
} else if (zoomIncRaw=0x64) {
	if ExistAZ
		GuiControl,, ZoomInc, 4
	zoomInc=4
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x96
} else if (zoomIncRaw=0x96) {
	if ExistAZ
		GuiControl,, ZoomInc, 5
	zoomInc=5
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0xc8
} else if (zoomIncRaw=0xc8) {
	if ExistAZ
		GuiControl,, ZoomInc, 6
	zoomInc=6
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x190
}
ExistAZ=

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
	GoSub, CloseMagnifier ; !!!!!! If magnifier is running, rerun Magnifier to apply the setting
	sleep, %delayButton%
	Run,"%windir%\system32\magnify.exe",,Min
} else {
	hideOrMinLast= ; if not defined, use default settings
}

Gosub, MagWinRestore
return

ZoomSlower:
if (OSver<6.1) {
	return
}
IfWinExist, AeroZoom Panel
	ExistAZ=1
	
RegRead,zoomIncRaw,HKCU,Software\Microsoft\ScreenMagnifier,ZoomIncrement
if (zoomIncRaw=0x32) {
	if ExistAZ
		GuiControl,, ZoomInc, 1
	zoomInc=1
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x19
} else if (zoomIncRaw=0x64) {
	if ExistAZ
		GuiControl,, ZoomInc, 2
	zoomInc=2
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x32
} else if (zoomIncRaw=0x96) {
	if ExistAZ
		GuiControl,, ZoomInc, 3
	zoomInc=3
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x64
} else if (zoomIncRaw=0xc8) {
	if ExistAZ
		GuiControl,, ZoomInc, 4
	zoomInc=4
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0x96
} else if (zoomIncRaw=0x190) {
	if ExistAZ
		GuiControl,, ZoomInc, 5
	zoomInc=5
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\ScreenMagnifier, ZoomIncrement, 0xc8
}
ExistAZ=

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
	GoSub, CloseMagnifier ; !!!!!! If magnifier is running, rerun Magnifier to apply the setting
	sleep, %delayButton%
	Run,"%windir%\system32\magnify.exe",,Min
} else {
	hideOrMinLast= ; if not defined, use default settings
}
Gosub, MagWinRestore
return

RunUACoff:
RunWait, *Runas "%A_WorkingDir%\Data\DisableUAC.exe" ; disable UAC
If (errorlevel=100) { ; if success and reboot is pending
	Exitapp
}
return

RunAsAdmin:
Gui, 1:Font, CRed, 
GuiControl,1:Font,Txt,
GuiControl,1:,Txt,- Please Wait -
; GoSub, CloseMagnifier ; this fails under limited acc with UAC on
Process, Exist, magnify.exe
if errorlevel
	Msgbox, 262192, AeroZoom, Please locate Magnifier and close it now, then press OK to continue.
Run, *Runas "%A_WorkingDir%\AeroZoom.exe"
Exitapp
return ; this is unneeded

TogglePaintKill:
if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
	return
}
RegRead,legacyKill,HKCU,Software\wandersick\AeroZoom,legacyKill
if (legacyKill=1) {
	legacyKill=2
	GuiControl,,KillMagnifier,&Paint
	Menu, OptionsMenu, Check, Legacy: Change Kill to Paint
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, legacyKill, 2
} else {
	legacyKill=1
	GuiControl,,KillMagnifier,Kil&l
	Menu, OptionsMenu, Uncheck, Legacy: Change Kill to Paint
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, legacyKill, 1
}

;Msgbox, 262208, AeroZoom, AeroZoom will now restart to apply new settings.
; Save last AZ window position before exit so that it shows the GUI after restart
;WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
;GoSub, CloseMagnifier
;restartRequired=
;reload

return

ZoomItLive:
if zoomitLive
{
	zoomitLive=
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitLive, 0
	Menu, ToolboxMenu, Uncheck, &Wheel with ZoomIt (Live)
	IfWinExist, ahk_class MagnifierClass ; restore zoom level (if zoomed in)
	{
		sendinput ^4 ; Side-note: WinActivate unzooms too!
	}
} else {
	gosub, ZoomItLiveMsg
	if (OSver>=6.2) {
		WinClose, ahk_class MagUIClass ; Try to gracefully close magnify.exe first as Windows 8 Magnifier supports (and REQUIRES) a graceful exit now.
		if Big4Buttons
			Process, WaitClose, magnify.exe, 5 ; if it does not gracefully exit in 5 secs (wait longer as the 4 big buttons and zoomInc needs a graceful exit more than other functions)
		Else
			Process, WaitClose, magnify.exe, 1 ; if it does not gracefully exit in 1 secs
		Big4Buttons=
	}
	Process, Close, magnify.exe ; cursor would be gone if magnifier is running (bug). and who needs 2 magnifiers at the same time?
	zoomitLive=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitLive, 1
	Menu, ToolboxMenu, Check, &Wheel with ZoomIt (Live)
	zoomitStill=
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitStill, 0
	Menu, ToolboxMenu, Uncheck, &Wheel with ZoomIt (Still)
	gosub, resetZoom ; restore zoom level (if zoomed in)
	Process, Exist, ZoomIt.exe
	if not errorlevel
		goto, zoomit
}
return

ZoomitStill:
if zoomitStill
{
	zoomitStill=
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitStill, 0
	Menu, ToolboxMenu, Uncheck, &Wheel with ZoomIt (Still)
	IfWinExist, ahk_class ZoomitClass ; restore zoom level (if zoomed in)
	{
		sendinput {esc}
	}
} else {
	zoomitStill=1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitStill, 1
	Menu, ToolboxMenu, Check, &Wheel with ZoomIt (Still)
	If (OSver>6) {
		zoomitLive=
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitLive, 0
		Menu, ToolboxMenu, Uncheck, &Wheel with ZoomIt (Live)
	}
	gosub, resetZoom ; restore zoom level (if zoomed in)
	Process, Exist, ZoomIt.exe
	if not errorlevel
		goto, zoomit
}
return

CloseMagnifier:
Process, Exist, magnify.exe
if errorlevel
{
	if (OSver<6) ; xp
	{
		IfExist, %windir%\system32\taskkill.exe ; not for xp home
		{
			RunWait, "%windir%\system32\taskkill.exe" /im magnify.exe,,Min
		}
		Else ;supports non-eng systems
		{
			;WinClose, ahk_class #32770, 2nd focus ; this is unreliable as the hidden texts is differrent in non-en systems
			WinClose, ahk_class #32770 ; this may cloose non-magnifier windows too, beware.
		}
		Process, WaitClose, magnify.exe, 5 ; required to ensure it has exited reliably
	} else {
		if (OSver>=6.2) {
			WinClose, ahk_class MagUIClass ; Try to gracefully close magnify.exe first as Windows 8 Magnifier supports (and REQUIRES) a graceful exit now.
			if Big4Buttons
				Process, WaitClose, magnify.exe, 5 ; if it does not gracefully exit in 5 secs (wait longer as the 4 big buttons and zoomInc needs a graceful exit more than other functions)
			Else
				Process, WaitClose, magnify.exe, 1 ; if it does not gracefully exit in 1 secs
			Big4Buttons=
		}
		Process, Close, magnify.exe ; (not good for xp as it leaves empty space at the top)
	}
}
return

MagWinBeforeRestore:
; check if a last magnifier window is available and record its status
; so that after it restores it will remain hidden/minimized/normal

; hideOrMinLast : hide (1) or minimize (2) or do neither (3)
; chkMin/MinMax -1 = minimized  0 = normal  1 = maximized  not defined = magnify.exe not running
if (OSver>6) {
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
}
return

MagWinRestore:

If (OSver>6) {
	Process, Exist, magnify.exe
	if errorlevel ; without this clicking the slider takes a long time to apply.
		WinWait, ahk_class MagUIClass,,3 
	; Hide or minimize or normalize magnifier window
	If not hideOrMinLast { ; if last window var not defined, use the default setting defined in Advanced Options
		if (hideOrMin=1) {
			WinMinimize, ahk_class MagUIClass ; Minimize first before hiding to remove the floating magnifier icon
			if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
				WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
		} else if (hideOrMin=2) {
			WinMinimize, ahk_class MagUIClass
		}
	} else if (hideOrMinLast=1) { ; if last window var defined, use the setting of it
		WinMinimize, ahk_class MagUIClass
		if (OSver<6.2) ; On Windows 8, WinHide is not suggested. Always minimize.
			WinHide, ahk_class MagUIClass ; Winhide seems to cause weird issues, experimental only (update: now production)
	} else if (hideOrMinLast=2) {
		WinMinimize, ahk_class MagUIClass
	}
}
return

CaptureOptions:
Gui, 10:+owner1
Gui, 10:+ToolWindow
Gui, 10:Font, s8, Tahoma

Gui, 10:Add, Text, x22 y133 w110 h20 , Default snip type
Gui, 10:Add, DropDownList, x170 y130 w82 h20 R4 +AltSubmit vSnipMode Choose%SnipMode%, Free-form|Rectangular|Window|Screen
Gui, 10:Add, Text, x22 y163 w142 h20 , Format for 'Save Captures'
;if SnipToClipboard ; if checkbox was checked
;{
;	Checked=Checked1
;}
;else
;{
;	Checked=Checked0
;}
;Gui, 10:Add, CheckBox, %Checked% -Wrap x142 y30 w110 h20 vSnipToClipboard, Save to &Clipboard

SnipToDiskCheckbox=%NirCmd%
if SnipToDiskCheckbox ; if checkbox was checked
{
	Checked=Checked1
	CheckboxDisable=
}
else
{
	Checked=Checked0
	CheckboxDisable=+Disabled
}

Gui, 10:Add, CheckBox, %Checked% -Wrap x22 y30 w120 h20 gSnipToDiskCheckbox vSnipToDiskCheckbox, Save &Captures
Gui, 10:Add, Edit, %CheckboxDisable% x22 y50 w180 h20 -Multi -WantTab -WantReturn vSnipSaveDir, %SnipSaveDir%
Gui, 10:Add, Button, %CheckboxDisable% x202 y49 w50 h22 g10ButtonBrowse1 v10ButtonBrowse1Temp, &Browse
Gui, 10:Add, DropDownList, %CheckboxDisable% x192 y160 w60 h20 R4 +AltSubmit vSnipSaveFormatNo Choose%SnipSaveFormatNo%, BMP|GIF|JPEG|TIFF|PNG
if PrintScreenEnhanceCheckbox ; if checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}
Gui, 10:Add, CheckBox, %Checked% %CheckboxDisable% -Wrap x22 y340 w230 h20 gPrintScreenEnhanceCheckbox vPrintScreenEnhanceCheckbox, &Enhance Print Screen button*
Gui, 10:Add, GroupBox, x12 y10 w250 h210 , Before capture
Gui, 10:Add, Text, x22 y192 w150 h20 , Delay before capture (in ms)
Gui, 10:Add, Edit, x192 y190 w60 h20 +Center +Limit5 -Multi +Number -WantTab -WantReturn vSnipDelayTemp,
Gui, 10:Add, UpDown, x224 y190 w18 h20 vSnipDelay Range0-99999, %SnipDelay%
Gui, 10:Add, GroupBox, x12 y230 w250 h100 , After capture
if SnipRunBeforeCommandCheckbox ; if checkbox was checked
{
	Checked=Checked1
	CheckboxDisable=
}
else
{
	Checked=Checked0
	CheckboxDisable=+Disabled
}
Gui, 10:Add, CheckBox, %Checked% -Wrap x22 y80 w230 h20 gSnipRunBeforeCommandCheckbox vSnipRunBeforeCommandCheckbox, &Run a file/command
Gui, 10:Add, Edit, %CheckboxDisable% x22 y100 w180 h20 -Multi -WantTab -WantReturn vSnipRunBeforeCommand, %SnipRunBeforeCommand%
Gui, 10:Add, Button, %CheckboxDisable% x202 y99 w50 h22 g10ButtonBrowse3 v10ButtonBrowse3Temp, &Browse
if SnipRunCommandCheckbox ; if checkbox was checked
{
	Checked=Checked1
	CheckboxDisable=
}
else
{
	Checked=Checked0
	CheckboxDisable=+Disabled
}
Gui, 10:Add, CheckBox, %Checked% -Wrap x22 y250 w130 h20 gSnipRunCommandCheckbox vSnipRunCommandCheckbox, &Run a file/command
Gui, 10:Add, Edit, %CheckboxDisable% x22 y270 w180 h20 -Multi -WantTab -WantReturn vSnipRunCommand, %SnipRunCommand%
Gui, 10:Add, Button, %CheckboxDisable% x202 y269 w50 h22 g10ButtonBrowse2 v10ButtonBrowse2Temp, &Browse
if SnipPasteCheckbox ; if checkbox was checked
{
	Checked=Checked1
}
else
{
	Checked=Checked0
}
Gui, 10:Add, CheckBox, %Checked% %CheckboxDisable% -Wrap x160 y250 w100 h20 vSnipPasteCheckbox, &Paste capture
Gui, 10:Add, Text, x22 y303 w130 h20 , Snipping Tool Editor state
Gui, 10:Add, DropDownList, x172 y300 w80 h20 R3 +AltSubmit vSnipWin Choose%SnipWin%, Hide|Minimize|Show
If SnippingToolExists
{
	Gui, 10:Add, Button, x82 y370 w60 h30 Default v10OKtemp, &OK
	Gui, 10:Add, Button, x142 y370 w60 h30 v10Canceltemp, &Cancel
	Gui, 10:Add, Button, x202 y370 w60 h30 gSnippingToolOptions vSettingsTemp, &More
} else {
	Gui, 10:Add, Button, x142 y370 w60 h30 Default v10OKtemp, &OK
	Gui, 10:Add, Button, x202 y370 w60 h30 v10Canceltemp, &Cancel
}
SnipSaveDir_TT := "Folder to save captures"
SnipToClipboard_TT := "Save to clipboard (Snipping Tool)"
SnipToDiskCheckbox_TT := "Save capture as file automatically"
10ButtonBrowse1Temp_TT := "Browse for a folder"
SnipSaveFormatNo_TT := "Save in this picture format"
SnipDelayTemp_TT := "Delay before the shooting action (1 second = 1000 milliseconds)"
SnipDelay_TT := "Delay before the shooting action (in milliseconds)"
SnipRunBeforeCommandCheckbox_TT := "Run a command/file (until it exits) before capture"
SnipRunBeforeCommand_TT := "Type a command or file path"
10ButtonBrowse3Temp_TT := "Browse for a file"
SnipRunCommandCheckbox_TT := "Run a command/file after capture"
SnipRunCommand_TT := "Type a command or file path"
10ButtonBrowse2Temp_TT := "Browse for a file"
SnipWin_TT := "If you don't use the editor, hide/minimize it after capture, or show it if you do."
PrintScreenEnhanceCheckbox_TT := "Enhance PrintScreen with 'Save Captures', 'Run a file/command (after capture)' and 'Paste capture'."
10OKtemp_TT := "Click to save changes"
10CancelTemp_TT := "Click to save changes"
SettingsTemp_TT := "Snipping Tool Program Settings"
Gui, 10:Show, h411 w276, AeroSnip Options
If !SnippingToolExists
{
	GuiControl,10:Disable, SnipMode
	GuiControl,10:Disable, SnipDelayTemp
	GuiControl,10:Disable, SnipRunBeforeCommandCheckbox
	GuiControl,10:Disable, SnipWin
	GuiControl,10:Disable, PrintScreenEnhanceCheckbox
	RegRead,PrintScreenMsg2,HKCU,Software\wandersick\AeroZoom,PrintScreenMsg2
	if errorlevel
	{
		if not GuideDisabled
		{
			Msgbox,262208,This message will only be shown once,Snipping Tool is not available for your system, therefore some unavailable options have been greyed out.`n`nOnly the following are configurable:`n`n1. Save Captures`n2. Run a command or file (after capture)`n3. Paste capture
			RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, PrintScreenMsg2, 1
		}
	}
}
Return

SnipToDiskCheckbox:
GuiControl,10:Enable, SnipSaveDir
GuiControl,10:Enable, 10ButtonBrowse1Temp
GuiControl,10:Enable, SnipSaveFormatNo
If SnippingToolExists
	GuiControl,10:Enable, PrintScreenEnhanceCheckbox
return

SnipRunCommandCheckbox:
GuiControl,10:Enable, SnipRunCommand
GuiControl,10:Enable, 10ButtonBrowse2Temp
GuiControl,10:Enable, SnipPasteCheckbox
return

SnipRunBeforeCommandCheckbox:
GuiControl,10:Enable, SnipRunBeforeCommand
GuiControl,10:Enable, 10ButtonBrowse3Temp
return

PrintScreenEnhanceCheckbox:
RegRead,PrintScreenMsg,HKCU,Software\wandersick\AeroZoom,PrintScreenMsg
if errorlevel
{
	if not GuideDisabled
	{
		Msgbox,262208,This message will only be shown once,When this is turned on, the following settings will be effective for the Print Screen button.`n`n1. Save Captures`n2. Run a command or file (after capture)`n3. Paste capture
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, PrintScreenMsg, 1
	}
}
Gui, 10:Font, s8 Bold, Tahoma
GuiControl,10:,SnipToDiskCheckbox,Save &Captures
GuiControl, 10:Font, SnipToDiskCheckbox
GuiControl,10:,SnipPasteCheckbox,Paste capture
GuiControl, 10:Font, SnipPasteCheckbox
GuiControl,10:,SnipRunCommandCheckbox,&Run a file/command
GuiControl, 10:Font, SnipRunCommandCheckbox
Gui, 10:Font, s8 Bold, Tahoma
return

10ButtonBrowse1:
Gui, 1:-AlwaysOnTop
FileSelectFolder, SnipSaveDir, , 3, Select a folder to save captures
If onTopBit
	Gui, 1:+AlwaysOnTop
if SnipSaveDir
{
	GuiControl,10:,SnipSaveDir,%SnipSaveDir%
}
return

10ButtonBrowse2:
Gui, 1:-AlwaysOnTop
FileSelectFile, SnipRunCommand, 3, , Select a file to run after capture
If onTopBit
	Gui, 1:+AlwaysOnTop
if SnipRunCommand
{
	GuiControl,10:,SnipRunCommand,%SnipRunCommand%
}
return

10ButtonBrowse3:
Gui, 1:-AlwaysOnTop
FileSelectFile, SnipRunBeforeCommand, 3, , Select a file to run before capture
If onTopBit
	Gui, 1:+AlwaysOnTop
if SnipRunBeforeCommand
{
	GuiControl,10:,SnipRunBeforeCommand,%SnipRunBeforeCommand%
}
return

SnippingToolOptions:
SnippingToolSetting=1
RegRead,SnippingToolSettingMsg,HKCU,Software\wandersick\AeroZoom,SnippingToolSettingMsg
if errorlevel
{
	if not GuideDisabled
	{
		Msgbox,262208,This message will only be shown once,Please do not disable 'Always copy snips to the Clipboard' setting if you use the 'Save Captures' option.`n`nLoading may take a while, please be patient and do not press any button until the Options dialog shows.
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnippingToolSettingMsg, 1
	}
}
Gui, Destroy
gosub, SnippingTool
WinWait, ahk_class #32770
IfWinExist, Snipping Tool Options
	WinWaitClose, Snipping Tool Options
Else
	WinWaitClose, ahk_class #32770
WinShow, AeroZoom Panel
return

10ButtonOK:
Gui, 1:-Disabled  ; Re-enable the main window
Gui, Submit ; required to update the user-submitted variable
Gui, Destroy
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipMode, %SnipMode%
if (SwitchSlider=3) {
	GuiControl,1:,SnipMode,%SnipMode%
}
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipSaveFormatNo, %SnipSaveFormatNo%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipWin, %SnipWin%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipDelay, %SnipDelay%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, PrintScreenEnhanceCheckbox, %PrintScreenEnhanceCheckbox%
;RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipToClipboard, %SnipToClipboard%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipRunBeforeCommandCheckbox, %SnipRunBeforeCommandCheckbox%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipRunCommandCheckbox, %SnipRunCommandCheckbox%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipPasteCheckbox, %SnipPasteCheckbox%

if SnipSaveDir 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipSaveDir, %SnipSaveDir%
if SnipRunBeforeCommand
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipRunBeforeCommand, %SnipRunBeforeCommand%
if SnipRunCommand
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipRunCommand, %SnipRunCommand%

If (SnipSaveFormatNo=1) {
	SnipSaveFormat=bmp
} else if (SnipSaveFormatNo=2) {
	SnipSaveFormat=gif
} else if (SnipSaveFormatNo=3) {
	SnipSaveFormat=jpg
} else if (SnipSaveFormatNo=4) {
	SnipSaveFormat=tiff
} else {
	SnipSaveFormat=png
}

If not NirCmd ; required to remove 0. otherwise the <> matching will not work sometimes.
	NirCmd=
if not SnipToDiskCheckbox 
	SnipToDiskCheckbox=


If (SnipToDiskCheckbox<>NirCmd) {
	goto, NirCmd
}
return


SnipFree:
SnipModeOnce=1
Goto, SnippingTool
return

SnipRect:
SnipModeOnce=2
Goto, SnippingTool
return

SnipWin:
SnipModeOnce=3
Goto, SnippingTool
return

SnipScreen:
SnipModeOnce=4
Goto, SnippingTool
return

EnsureAutoCopyToClipboard:
; ensure this setting is not disabled externally in snipping tool if 'save captures' is enabled
If NirCmd
{
	RegRead,AutoCopyToClipboard,HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool,AutoCopyToClipboard
	If not (AutoCopyToClipboard=0x1) {
		Process, Exist, SnippingTool.exe
		If errorlevel
			Process, Close, SnippingTool.exe
		RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\TabletPC\Snipping Tool, AutoCopyToClipboard, 0x1
	}
}
return

SnipBarUpdate: ; a g-label is required for the variable to update immediately
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipMode, %SnipMode%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipModeOSD, %SnipMode%
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIncTextOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomitColorOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CaptureDiskOSD
If (OSD=1)
	Run, "%A_WorkingDir%\Data\OSD.exe"
return

CaptureDiskOSD:
Gosub, NirCmd
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIncTextOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomitColorOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipModeOSD
If NirCmd
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CaptureDiskOSD, 1
Else
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CaptureDiskOSD, 2
If (OSD=1)
	Run, "%A_WorkingDir%\Data\OSD.exe"
return

ZoomItColorPreview:
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomitColor, %ZoomitColor%
RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomitColorOSD, %ZoomitColor%
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, ZoomIncTextOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, SnipModeOSD
RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, CaptureDiskOSD
If (OSD=1)
	Run, "%A_WorkingDir%\Data\OSD.exe"
return

ZoomItColor:
If (ZoomitColor=1) {
	sendinput r
} else if (ZoomitColor=2) {
	sendinput g
} else if (ZoomitColor=3) {
	sendinput b
} else if (ZoomitColor=4) {
	sendinput y
} else if (ZoomitColor=5) {
	sendinput p
} else if (ZoomitColor=6) {
	sendinput o
}
return

ZoomItPanelViaButton:
If (OSD=1) {
	if zoomitPanel
		Run, "%A_WorkingDir%\Data\OSD.exe" WinMagPanel
	Else
		Run, "%A_WorkingDir%\Data\OSD.exe" ZoomItPanel
}

ZoomitPanel:
if zoomitPanel
{
	Gui, Font, s8 Norm, Arial
	GuiControl,,ZoomItButton,&zoom
	GuiControl, Font, ZoomItButton
	Gui, Font, s10 Norm, Tahoma
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitPanel, 0
	if (OSver<6.1) OR (OSver>=6.1 AND !A_IsAdmin AND EnableLUA) { ; reload is required to update the top 4 buttons as non-win-7 OSes dont get them.
		Gui, 1:Font, CRed,
		GuiControl,1:Font,Txt, ; to apply the color change
		GuiControl,1:,Txt,- Please Wait -
		GuiControl,Disable,Bye
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		reload
		return
	}
	zoomitPanel=
	GuiControl, Disable, ZoomItColor
	GuiControl, Hide, ZoomItColor
	If (OSver>=6.1) {
		If !(!A_IsAdmin AND EnableLUA) { ; if Win 7 + Limited Account + UAC, Kill is impossible, so zoom rate slider is unavailable.
			Menu, FileMenu, Uncheck, Switch to &Zoom Rate Slider
		}
		Menu, FileMenu, Uncheck, Switch to &Magnify Slider
	}
	If SnippingToolExists
	{
		Menu, FileMenu, Uncheck, Switch to &AeroSnip Slider
	}
	If (OSver<6.1) {
		Menu, FileMenu, Uncheck, Switch to Save-Capture Slider
	}
	Menu, FileMenu, Rename, Go to Windows Magnifier &Panel, Go to ZoomIt &Panel
	if (SwitchSlider=1) {
		GuiControl, Enable, ZoomInc
		GuiControl, Show, ZoomInc
		Menu, FileMenu, Check, Switch to &Zoom Rate Slider
	} else if (SwitchSlider=2) {
		GuiControl, Enable, Magnification
		GuiControl, Show, Magnification
		Menu, FileMenu, Check, Switch to &Magnify Slider
	} else if (SwitchSlider=3) {
		GuiControl, Enable, SnipMode
		GuiControl, Show, SnipMode
		Menu, FileMenu, Check, Switch to &AeroSnip Slider
	} else if (SwitchSlider=4) {
		GuiControl, Enable, SnipSlider
		GuiControl, Show, SnipSlider
		Menu, FileMenu, Check, Switch to Save-Capture Slider
	}
	ZoomItButton_TT := "ZoomIt/Windows Magnifier Panel Switch"
	if not (KeepSnip=1) { ; if KeepSnip is not set in the Advanced Options
		If (OSver<6) OR (EditionID="HomeBasic" OR EditionID="Starter") {
			GuiControl,, &Draw, &Paint
		} else {
			GuiControl,, &Draw, &Snip
		}
		if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
			GuiControl,, Tim&er, &Paint
			KillMagnifier_TT := "Kill magnifier process [Win+Shift+K]"
		} else {
			if (legacyKill=1) {
				; Change text 'Timer' to 'Kill'
				GuiControl,, Tim&er, Kil&l
				;GuiControl,, Paus&e, Kil&l
			} else {
				GuiControl,, Tim&er, &Paint
				;GuiControl,, Paus&e, &Paint
			}
			if (legacyKill=1) {
				KillMagnifier_TT := "Kill magnifier process [Win+Shift+K]"
			} else {
				KillMagnifier_TT := "Create and edit drawings"
			}
		}
		if (OSver<6 OR EditionID="HomeBasic" OR EditionID="Starter") {
			Draw_TT := "Create and edit drawings"
		} else {
			Draw_TT := "Copy a portion of screen for annotation [Win+Alt+F/R/W/S]"
		}
		GuiControl,, ShowMagnifier, &Mag
		ShowMagnifier_TT := "Show/hide magnifier [Win+Shift+``]"
		GuiControl,, Color, Color &Inversion
		Color_TT := "Turn on/off color inversion [Win+Alt+I]"
		GuiControl,, Mouse, &Mouse %MouseCurrent% > %MouseNext%
		Mouse_TT := "Follow the mouse pointer [Win+Alt+M]"
		GuiControl,, Keyboard, &Keyboard %KeyboardCurrent% > %KeyboardNext%
		Keyboard_TT := "Follow the keyboard focus [Win+Alt+K]"
		GuiControl,, Text, Te&xt %TextCurrent% > %TextNext%
		Text_TT := "Have magnifier follow the text insertion point [Win+Alt+T]"
		GuiControl,, Calc, %customCalcMsg%
		if not customCalcPath
		{
			if (customCalcMsg = "&Calc" OR customCalcMsg = "Calc" OR customCalcMsg = "C&alc" OR customCalcMsg = "Ca&lc" OR customCalcMsg = "Cal&c")
			{
				Calc_TT := "Show calculator" ; show tooltip only if the button is for launching the caluculator, not user-defined
			}
		}
		GuiControl,, Type, %customTypeMsg%
		if not customEdPath
		{
			if (customTypeMsg = "T&ype" OR customTypeMsg = "Type" OR customTypeMsg = "&Type" OR customTypeMsg = "Ty&pe" OR customTypeMsg = "Typ&e")
			{
				Type_TT := "Input text"
			}
		}
	}
} else {
	if !zoomit
		gosub, zoomit
	; WinWaitClose, ZoomIt Enhancements Setup, , 3 ; to wait for gosub and not continue immediately
	Gui, Font, s8 Bold, Arial
	GuiControl,,ZoomItButton,&zoom
	GuiControl, Font, ZoomItButton
	Gui, Font, s10 Norm, Tahoma
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitPanel, 1
	if (OSver<6.1) OR (OSver>=6.1 AND !A_IsAdmin AND EnableLUA) { ; reload is required to update the top 4 buttons as non-win-7 OSes (or Win7+Limited Mode+UAC) dont get them.
		Gui, 1:Font, CRed,
		GuiControl,1:Font,Txt, ; to apply the color change
		GuiControl,1:,Txt,- Please Wait -
		GuiControl,Disable,Bye
		WinGetPos, lastPosX, lastPosY, , , AeroZoom Panel,
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosX, %lastPosX%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, lastPosY, %lastPosY%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, reload, 1
		Gosub, SaveCurrentProfile
		reload
		return
	}
	zoomitPanel=1
	If (OSver>=6.1) {
		If !(!A_IsAdmin AND EnableLUA) { ; if Win 7 + Limited Account + UAC, Kill is impossible, so zoom rate slider is unavailable.
			Menu, FileMenu, Uncheck, Switch to &Zoom Rate Slider
		}
		Menu, FileMenu, Uncheck, Switch to &Magnify Slider
		GuiControl, Disable, ZoomInc
		GuiControl, Hide, ZoomInc
		GuiControl, Disable, Magnification
		GuiControl, Hide, Magnification
	} else {
		Menu, FileMenu, Uncheck, Switch to Save-Capture Slider
		GuiControl, Disable, SnipSlider
		GuiControl, Hide, SnipSlider
	}
	If SnippingToolExists
	{
		Menu, FileMenu, Uncheck, Switch to &AeroSnip Slider
		GuiControl, Disable, SnipMode
		GuiControl, Hide, SnipMode
	}
	Menu, FileMenu, Rename, Go to ZoomIt &Panel, Go to Windows Magnifier &Panel
	GuiControlGet, SliderExists, , ZoomItColor
	if errorlevel ;if slider not created yet
		Gui, Add, Slider, TickInterval1 Range1-6 x12 y3 w120 h24 vZoomItColor gZoomItColorPreview, %ZoomItColor%
	Else
		GuiControl, Enable, ZoomItColor
		GuiControl, Show, ZoomItColor
	ZoomItColor_TT := "Pen color: (1) Red / (2) Green / (3) Blue / (4) Yellow / (5) Pink / (6) Orange"
	ZoomItButton_TT := "ZoomIt/Windows Magnifier Panel Switch"
	if not (KeepSnip=1) { ; if KeepSnip is not set in the Advanced Options
		if (!A_IsAdmin AND EnableLUA AND OSver>6.0) {
			GuiControl,1:, &Paint, Tim&er
		} else {
			if (legacyKill=1) {
				; Change text 'Kill' to 'Timer'
				GuiControl,1:, Kil&l, Tim&er
			} else {
				GuiControl,1:, &Paint, Tim&er
			}
		}
		If (OSver<6) OR (EditionID="HomeBasic" OR EditionID="Starter") {
			GuiControl,1:, &Paint, &Draw
		} else {
			GuiControl,1:, &Snip, &Draw
		}
		KillMagnifier_TT := "ZoomIt: Break timer [Ctrl+3]"
		Draw_TT := "ZoomIt: Draw [Ctrl+2]"
		GuiControl,, Color, Zoom (&Still)
		Color_TT := "ZoomIt: Still zoom [Ctrl+1]"
		GuiControl,, Mouse, Zoom (&Live)
		Mouse_TT := "ZoomIt: Live zoom [Ctrl+2]"
		GuiControl,, Keyboard, Board (&White)
		Keyboard_TT := "ZoomIt: White board [Ctrl+2, W]"
		GuiControl,, Text, Board (&Black)
		Text_TT := "ZoomIt: Black board [Ctrl+2, K]"
		GuiControl,, Calc, &Help
		Calc_TT := "ZoomIt: Hotkey list [Win+Alt+Q, Z]"
		GuiControl,, ShowMagnifier, O&ption
		ShowMagnifier_TT := "ZoomIt: ZoomIt Options"
		GuiControl,, KillMagnifier, Tim&er
		KillMagnifier_TT := "ZoomIt: Break timer [Ctrl+3]"
		GuiControl,, Draw, &Draw ; Change text 'Snip' to 'Draw'	
		Draw_TT := "ZoomIt: Draw [Ctrl+2]"
		GuiControl,, Type, T&ype
		Type_TT := "ZoomIt: Type [Ctrl+2, T]"
	}
}
return

ZoomItLiveMsg:
If (OSver>=6.1 AND (EditionID="HomeBasic" OR EditionID="Starter")) ; no need to show the msg for win 7 home basic/starter
	return
RegRead,zoomitLiveMsg,HKCU,Software\wandersick\AeroZoom,zoomitLiveMsg
if errorlevel
{
	If (OSver>=6.1) AND !(!A_IsAdmin AND EnableLUA)
	{
		zoomitLiveTempMsg=`n`nAlso, there is a problem with the Full Screen view of Windows Magnifier and the Live Zoom mode of ZoomIt working together, where the cursor is lost after zooming out. As a workaround, AeroZoom will kill the magnifier (in affected situations only) right after 'Live Zoom' is triggered. (If you do want to use Live Zoom with AeroZoom on Windows, you may also go to 'Tool > Preferences > Advanced Options', uncheck 'Run Magnifier on AZ start'.)
	}
	If (OSver>=6.1 AND EditionID<>"Starter" AND EditionID<>"HomeBasic")
		zoomitLiveTempMsg2=`n`nIf you are already using Windows 7 Home Premium or above and have Aero, it is suggested not using this as Windows Magnifier's own full-screen zoom is already great.
	if not GuideDisabled
	{
		Msgbox, 262208, This message will only be shown once, This option is not recommended for Windows Home editions (e.g. Windows 7 Home Premium), but Home Basic and Starter of Windows 7, and Home Premium and above editions of Vista.`n`nDue to the old magnifier in Vista or the lack of Aero in elementary OS editions, full-screen zoom is unavailable. However, you can use this so that AeroZoom adds wheel-zoom capability to ZoomIt's Live Zoom function which is full-screen and is usable on those platforms (where all 'elastic zoom' modes are also handled by ZoomIt).`n`nNote: A black screen may show if Aero is unavailable. In that case, please use 'Tool > Wheel with ZoomIt (Still)' instead.%zoomitLiveTempMsg2%%zoomitLiveTempMsg%
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, zoomitLiveMsg, 1
	}
}
return

WorkaroundFullScrLiveZoom: ; solves the bug stated above by killing magnifier
if (OSver>=6.1 AND EditionID<>"Home Basic" AND EditionID<>"Starter") {
	RegRead,MagnificationMode,HKCU,Software\Microsoft\ScreenMagnifier,MagnificationMode
	if (MagnificationMode=0x2) {
		if (OSver>=6.2) {
			WinClose, ahk_class MagUIClass ; Try to gracefully close magnify.exe first as Windows 8 Magnifier supports (and REQUIRES) a graceful exit now.
			if Big4Buttons
				Process, WaitClose, magnify.exe, 5 ; if it does not gracefully exit in 5 secs (wait longer as the 4 big buttons and zoomInc needs a graceful exit more than other functions)
			Else
				Process, WaitClose, magnify.exe, 1 ; if it does not gracefully exit in 1 secs
			Big4Buttons=
		}
		Process, Close, magnify.exe
	}
}
return

W7HBCantRun2MagMsg:
If (OSver>=6.1 AND (EditionID="Starter" OR EditionID="HomeBasic")) ; if win7 home basic/starter, cannot have 2 magnifiers zoom in together
{
	If zoomitLive {
		If not W7HBCantRun2MagMsg
		{
			if not GuideDisabled
			{
				Msgbox, 262208, Information (This message will only be shown once), 'Live Zoom' of ZoomIt is currently on. Running 2 magnifiers (ZoomIt and Windows Magnifier) together under Basic Editions of Windows (e.g. Home Basic/Starter) will cause problems, so it is disencouraged.`n`nIf you really need to use Windows Magnifier, please disable 'Live Zoom' first at 'Tool > Wheel-Zoom by ZoomIt."
				W7HBCantRun2MagMsg=1
				RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\wandersick\AeroZoom, W7HBCantRun2MagMsg, 1
			}
			; Exit
		}
	}
}
return

LockPC:

IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
	Run, "%A_WorkingDir%\Data\NirCmd.exe" lockws
Else
	goto, NirCmdDownloadAlt

return

SleepPC:
Msgbox, 262180, Sleep, Are you sure to put this PC to sleep?
IfMsgBox Yes
{
	IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
		Run, "%A_WorkingDir%\Data\NirCmd.exe" standby
	Else
		goto, NirCmdDownloadAlt
}
return

HibernatePC:
Msgbox, 262180, Hibernate, Are you sure to hibernate this PC?
IfMsgBox Yes
{
	IfExist, %A_WorkingDir%\Data\NirCmd.exe ; NirCmd is checked but could be missing
		Run, "%A_WorkingDir%\Data\NirCmd.exe" hibernate
	Else
		goto, NirCmdDownloadAlt
}
return

RebootPC:
Msgbox, 262180, Reboot, Are you sure to reboot this PC?
IfMsgBox Yes
	Run, %windir%\System32\shutdown.exe -r -t 0
return

ShutDownPC:
Msgbox, 262180, Shut Down, Are you sure to shut down this PC?
IfMsgBox Yes
	Run, %windir%\System32\shutdown.exe -s -t 0
return

SaveCurrentProfile:
; If QuickProfileSwitch is enabled, export config to the respective profile#.reg (eg before reload)
If profileInUse {
	if A_IsAdmin ; invisible to user but requires admin right
	{
		RunWait, "%windir%\regedit.exe" /E "%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg" "HKEY_CURRENT_USER\Software\wandersick\AeroZoom", ,min
	}
	Else ; below would show a minimized cmd window for a second
	{
		RunWait, "%windir%\system32\reg.exe" export "HKEY_CURRENT_USER\Software\wandersick\AeroZoom" "%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg" /f,,min
	}
}
return

LoadDefaultRegImportQuickProfile:

; If QuickProfileSwitch is enabled, import config from the respective profile#.reg
If profileInUse {

	; Delete existing AeroZoom settings
	RegDelete, HKEY_CURRENT_USER, Software\wandersick\AeroZoom

	IfExist, %A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg
	{
		if A_IsAdmin ; invisible to user but requires admin right
		{
			RunWait, "%windir%\regedit.exe" /S "%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg", ,min
		}
		Else ; below would show a minimized cmd window for a second
		{
			RunWait, "%windir%\system32\reg.exe" import "%A_WorkingDir%\Data\QuickProfiles\Profile%profileInUse%.reg" , ,min
		}
	}
	Else
	{
		Msgbox, 262192, ERROR, Profile%profileInUse%.reg does not exist:`n`n%A_WorkingDir%\Data\QuickProfiles\.
		return
	}
	
}
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

;WinHide WinShow is preferred than below because unlike win7, 'bottom' is still in front of the desktop in vista/xp:

;WinSet, Bottom,,AeroZoom Panel
;...
;If onTopBit
;	WinSet, AlwaysOnTop, On, AeroZoom Panel
;Else
;	WinActivate, AeroZoom Panel

; Drag the borders to move the panel.
; http://www.autohotkey.com/forum/viewtopic.php?p=64185#64185 ; thanks to SKAN
uiMove:
PostMessage, 0xA1, 2,,, A 
Return

; detect right click on gui
GuiContextMenu:
; only enable it for win 7
if (OSver>=6.1 AND !(!A_IsAdmin AND EnableLUA))
	gosub, SwitchMiniMode
return

; ------------------------------------------
; Some random unorganized notes for internal use:

; First step: use LButton as base, make a copy of it. uncomment LButton & Wheelup, LButton & WheelDown, LButton & MButton in the copy. Then use the copy as base for all other ahk.

; * For each modifier.ahk, search for '~LButton & ' and replace it with '~RButton &' '~MButton &' '~XButton1 &' '~XButton2 &'  '!' '^' '+' '#'
; * For middle.ahk, uncomment mbutton & rbutton (and del ~LButton & MButton)
;   replace mbutton:: with ~MButton & LButton:: and delete some lines there
; * (cancelled line) Search ;; for X1 and X2, but theres no need to do anything on them now. they are the same as others
; * For each modifier except MButton, because the zoom has taken mod+wup/wdown, the hotkey customization bit is not usable. remove the duplicated modifier.
;   e.g. in Ctrl ahk, comment/del ~^Wheelup and ~^Wheeldown due to hotkey customization (~^LButton and ~^RButton can be kept though)
; * in RButton ahk (already done for LButton), remove as well the custom hotkey mod+mbutton (since Custom Hotkey for Left/Right includes the Mbutton)
;   e.g. In RButton ahk, comment/del custom hotkey's "~RButton & MButton::" (the 2nd one, not the 1st one), ensure uncomment "~LButton & MButton::", (vice versa in LButton ahk but should be done if used as base)
;        In all other ahk except LButton/RButton, ensure uncomment both

; Before release
; - Set read-only flag for Readme and Tips, bat vbs
; - Be sure to update the updater.bat search terms
; - Check setup.ahk for more things (e.g. update verAZ)
; - Update verAZ in setup.ahk and all mod ahk
; - Update Product version in .ahk.ini (no need scripts that need AutoHotKey_L Unicode )
; - Update src (Readme, etc.) in ahk.7z (removed to redirect people to Github)
; - Empty configbackup folder
; - Delete ZoomIt.exe, NirCmd.exe
; - Delete all comments before compiling

; Remember to create separate x64 executables (note: .ahk and _x64.ahk are exactly the same scripts. just compile them with different compilers)
; .ahk.ini aren't used for e.g. AeroZoom_Mouse*.ahk scripts because Compile AHK II doesnt seem to support 64bit AutoHotkey_L Unicode (or 32bit AutoHotkey_L Unicode). Custom icons is not required except for AeroZoom.exe and Setup.exe anyway.
; (OUTDATED, use batch file to compile now. See 8/1/2012 notes below) Compile x64 main files with AutoHotkey_L 64bit unicode (during ahk installation choose Unicode 64bit)
; (OUTDATED) Compile x86 main files with AutoHotkey_L 32bit unicode in order to google in Chinese, Japanese, etc. (during ahk installation choose Unicode 32bit)
; Compile only ZoomPad, OpenTray, DisableUAC, OSD, Setup, AeroZoom.exe with original 32bit AutoHotkey to keep size small...(not AutoHotkey_L's ANSI mode) (It seems Compile AHK II only supports it for setting metadata)
; (OUTDATED) * note: compiling across x64 and x86 requires 2 systems. (or 2 VMs) -- no longer the case with new AutoHotkey_L which comes with a new compiler with such capability
; Test all functions and modifier executables under x86 and x64 systems. Compiling all ahk at once causes problems at times.

; When a new version of AeroZoom is installed, any found old copy is upgraded. This is usually fine except new default settings won't apply as old settings are respected. So it's recommended to do a reset in 'Tool > Preferences > Advanced Options > Reset' anyway.
; Programmer's note: don't change some important key functions (e.g. default no and order of Custom Hotkey items). Upgrading will still cause problems. Create a new variable in that case.
; ------------------------------------------

; NEW METHOD 8/1/2012 (or compileAll.bat)

;cd /d C:\Program Files\AutoHotkey\Compiler
;Ahk2Exe.exe /in AeroZoom_MouseL_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseR_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseM_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseX1_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseX2_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Alt_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Ctrl_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Win_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Shift_x64.ahk /bin "Unicode 64-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseL.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseR.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseM.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseX1.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_MouseX2.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Alt.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Ctrl.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Win.ahk /bin "Unicode 32-bit.bin"
;Ahk2Exe.exe /in AeroZoom_Shift.ahk /bin "Unicode 32-bit.bin"

; EmailBugs: :D
; Run, mailto:wandersick+aerozoom@gmail.com?subject=AeroZoom %verAZ% Bug Report&body=Please describe your problem.
; return

; (c) Copyright 2009-2015 AeroZoom by a wandersick | http://wandersick.blogspot.com
