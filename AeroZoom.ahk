; AeroZoom by wandersick | https://tech.wandersick.com
;
; This is the redirector. See main script for more.

#SingleInstance force
#NoTrayIcon

; The following is only set in this script but not the scripts inside \Data in order to fix the Working Directory for them.
; Setup.ahk is not set too because the msi installer is one-file and would not see \Data
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Missing component check
IfNotExist, %A_WorkingDir%\Data
{
	Msgbox, 262192, AeroZoom, Missing essential program files. Please reinstall.
	ExitApp
}

; Check if WizMouse is running
RegRead,WizMouseChk,HKCU,Software\WanderSick\AeroZoom,WizMouseChk
if not WizMouseChk {
	Process, Exist, WizMouse.exe
	if errorlevel
	{
		Msgbox, 262160, Notice (This message will be shown once only), WizMouse is found running on this system.`n`nWizMouse is only semi-compatible with AutoHotkey--the language AeroZoom is based on.`n`nFrom the WizMouse doc: "Some users reported that rehooking may cause issues with AutoHotkey so now it can be disabled. Note that AutoHotkey (Add: AeroZoom) must be started AFTER WizMouse for them to work together correctly."`n`nTo work around it, please use one of the following tip.`n`nTip 1: Clicking on any Ctrl/Shift/Alt/Left/Right/Middle/F/B button on the AeroZoom Panel restarts (brings back) AeroZoom.`n`nTip 2: (Since v3.2) Clicking the tray icon 3 times does it too.`n`nTip 3: Go to WizMouse's Settings and check 'Left click tray icon to enable/disable', so that left-clicking WizMouse's tray icon quickly disables WizMouse and enables AeroZoom, or vice versa.
	}
	RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, WizMouseChk, 1
	WizMouseChk=1
}


RegRead,OSver,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentVersion
if (OSver>6) { ; if newer than vista
	; Check if WMC is running
	RegRead,WmcChk,HKCU,Software\WanderSick\AeroZoom,WmcChk
	if not WmcChk {
		Process, Exist, ehshell.exe
		if errorlevel
		{
			Msgbox, 262160, Notice (This message will be shown once only), Windows Media Center is found running on this system.`n`nThere's a Windows bug that hides the cursor when both Windows Magnifier and Windows Media Center are running and in full screen. This version of AeroZoom provides a workaround--the 'Kill magnifier' hotkey Win+Shift+K to end the Magnifier process so that the cursor shows in such case.`n`nIf mouse is preferred over keyboard, we may also call the AeroZoom panel then press 'Kill'. An easier way of doing it is customize a hotkey action, e.g. the middle mouse button, so that we can just hold it to kill magnifier. To do that, go to 'Tool > Custom Hotkeys > Holding Middle' and set its action to 'Kill magnifier'.
		}
		RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\WanderSick\AeroZoom, WmcChk, 1
		WmcChk=1
	}
}

; check if OS is x64
if ProgramW6432
	goto, x64

; Retrieve last time's checked radio button from Registry

RegRead,chkModRaw,HKCU,Software\WanderSick\AeroZoom,Modifier
if (chkModRaw=0x1) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Ctrl.exe",,
} else if (chkModRaw=0x2) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Alt.exe",,
} else if (chkModRaw=0x3) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Shift.exe",,
} else if (chkModRaw=0x4) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Win.exe",,
} else if (chkModRaw=0x5) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseL.exe",,
} else if (chkModRaw=0x6) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseR.exe",,
} else if (chkModRaw=0x7) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseM.exe",,
} else if (chkModRaw=0x8) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseX1.exe",,
} else if (chkModRaw=0x9) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseX2.exe",,
} else {
	; Run the left mouse button version by default
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseL.exe",,
}

ExitApp

; AutoHotkey_L supports x64 for better performance
; However AeroZoom were forced to support x64 (by creating separate executables) anyway
; to solve its bug under x64 OS... e.g. SnippingTool.exe isn't available in C:\Windows\SysWOW64... Can't schedule tasks.

x64:

RegRead,chkModRaw,HKCU,Software\WanderSick\AeroZoom,Modifier
if (chkModRaw=0x1) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Ctrl_x64.exe",,
} else if (chkModRaw=0x2) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Alt_x64.exe",,
} else if (chkModRaw=0x3) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Shift_x64.exe",,
} else if (chkModRaw=0x4) {
	Run,"%A_WorkingDir%\Data\AeroZoom_Win_x64.exe",,
} else if (chkModRaw=0x5) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseL_x64.exe",,
} else if (chkModRaw=0x6) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseR_x64.exe",,
} else if (chkModRaw=0x7) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseM_x64.exe",,
} else if (chkModRaw=0x8) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseX1_x64.exe",,
} else if (chkModRaw=0x9) {
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseX2_x64.exe",,
} else {
	; Run the left mouse button version by default
	Run,"%A_WorkingDir%\Data\AeroZoom_MouseL_x64.exe",,
}

ExitApp