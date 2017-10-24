#SingleInstance force

; The following is only set in this script but not the scripts inside \Data in order to fix the Working Directory for them.
; Setup.ahk is not set too because the msi installer is one-file and would not see \Data
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Missing component check
IfNotExist, %A_WorkingDir%\Data
{
	Msgbox, 262192, AeroZoom, Missing essential program files. Please reinstall.
	ExitApp
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