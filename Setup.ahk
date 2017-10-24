; AeroZoom by WanderSick | http://wandersick.blogspot.com
;
; This is the Setup. See main script for more.
;
; ------------------------------------------
; Some unorganized notes for internal use:
;
; ** Compile this with AutoHotKey Basic (as it does not need to query WMI anymore)
; ** RunAsHighest for ONLY this script and AeroZoom ahk. (All mod scripts w/o manifest)
; So this setup.exe uses the current user's profile to install (in case of AsHighest/AsInvoker, not the elevated user's (in case of AsAdmin)
; Running AeroZoom with admin rights is better under win7 (due to OS limitations). So the elevated user might share settings
; with the standard user as both would share the same registry user hive that way. (This problem assumes running from a standard user account,
; for admin accounts with/without UAC on, no problem.)
;
; For unattended install, set unattendAZ=1, see below or setup.exe /?
; (Also, a MSI may be available on the web site above)

; Uninstallation will automatically take place instead if an installed copy is found in %targetDir%
; * No need to compile this with UAC RunAsAdmin manifest or name it setup.exe as the installation does not depend on admin rights *
; * To name it setup.exe yet not get auto elevation in Standard User accounts, try asInvoker/asHighest. The latter elevates in admin
;   accounts with UAC on, but the former does not (unless UAC is off, then admin rights always).

; The following switches can be set by either setup.exe /unattendAZ=1 or, in a command prompt, set unattendAZ=1

; /unattendAZ=1 : for unattended installation/uninstallation using setup.exe
;                 (also used by menu 'Tool > Uninstall AeroZoom from this Computer' although it wont allow uninstallation)
;                 to suspress all dialogs. no running executables is closed -- so that would fail if its trying to delete itself
;                 so it doesnt do that. in that case it would prompt user to uninstall in Program and Features (i.e. below, unattendAZ=2)
;            =2 : for uninstallation in Program and Features. will present uninstallation dialogs (attended)
;                 to users when they uninstall using Program and Features.
;                 cancelled --> the most obvious different from 1 is it includes using AT.exe to schedule deletion of this setup.exe
;                 also it wont check for working directory
;     undefined : for setup.exe to install/uninstall in attended mode. (most usual)

; /programfiles : install into Program Files for all users

; e.g. Setup.exe /unattendAZ=1 /programfiles

	; MSI installer making steps: (cancelled as MSI created this way does not work with UAC on)
	; 1. Embed these files in a batch file for Batch To Exe Converter 1.5: 
	; AeroZoom_Task.bat, AeroZoom_Task_Body.xml 7z.exe, 7z.dll, AeroZoom.7z (the whole AeroZoom folder compressed), setup.exe (this ahk file after being compiled.)
	; 2. Batch To Exe Converter Settings:
	; Invisible application, Temporary directory (Submit current directory), Overwrite existing files
	; 3. Batch file content:

	; @echo off
	; "setup.exe" /unattendAZ=1
	; goto :EOF

	; 4. AHK content: This file and uncomment the following line in around line 53
	; RunWait, 7z.exe -y x AeroZoom.7z -o"%localappdata%\WanderSick\",%A_ScriptDir%
	; Comment the following line around line 54
	; FileCopyDir, %A_WorkingDir%, %localappdata%\WanderSick\AeroZoom, 1
	
	; 5. Use Exe To Msi Converter Free (1.0) by QwertyLabs to convert.
	; Specify no switch
	; Other tools/versions may not work without specific settings
	; For v3.1, check 'Do not Register Package (suppress Uninstall)'
	
	; 6. Since v1 displays exe2msi and QwentyLabs as Product Name. Use Orca to correct it.
	
	; When creating an single-file installer, remove the missing component check below

verAZ = 3.0
	
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Missing component check
IfNotExist, %A_WorkingDir%\Data
{
	Msgbox, 262192, AeroZoom, Missing essential components.`n`nPlease download the legitimate version from wandersick.blogspot.com.
	ExitApp
}

targetDir=%localappdata%
If %1% {
	Loop, %0%  ; For each parameter:
	{
		param := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
		If (param="/unattendAZ=1")
			unattendAZ=1
		Else if (param="/unattendAZ=2")
			unattendAZ=2
		Else if (param="/programfiles")
		{
			targetDir=%programfiles%
			setupAllUsers=1
		}
		Else
		{
			Msgbox, 262192, AeroZoom Setup, Supported parameters:`n`n - Unattended setup : /unattendAZ=1`n - Install for all users : /programfiles`n`nFor example: Setup.exe /programfiles /unattendaz=1`n`nNote:`n - If setup finds a copy in the target location, uninstallation will be carried out instead.`n - If you install into Program Files folder, be sure you're running it with administrator rights.
			ExitApp
		}
	}
}

; check path to AeroZoom_Task.bat
IfExist, %A_WorkingDir%\AeroZoom_Task.bat
	TaskPath=%A_WorkingDir%
IfExist, %A_WorkingDir%\Data\AeroZoom_Task.bat
	TaskPath=%A_WorkingDir%\Data

IfWinExist, ahk_class AutoHotkeyGUI, AeroZoom ; Check if a portable copy is running
	ExistAZ=1
; Install / Unisntall
regKey=SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AeroZoom
IfNotExist, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe
{
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Installer , Install AeroZoom in the following location?`n`n%targetDir%\WanderSick\AeroZoom`n`nNote:`n - For portable use, just run AeroZoom.exe. Setup is unneeded.`n - To install silently or to all users, run Setup.exe /? to see how.`n - To remove a copy that was installed to all users, run Setup.exe /programfiles
		IfMsgBox No
		{
			Exitapp
		}
	}
	Gosub, KillProcess
	; Remove existing directory
	FileRemoveDir, %targetDir%\WanderSick\AeroZoom\Data, 1
	FileRemoveDir, %targetDir%\WanderSick\AeroZoom, 1
	; Copy AeroZoom to %targetDir%

	FileCreateDir, %targetDir%\WanderSick\AeroZoom
	; RunWait, 7z.exe -y x AeroZoom.7z -o"%targetDir%\WanderSick\",%A_ScriptDir%
	FileCopyDir, %A_WorkingDir%, %targetDir%\WanderSick\AeroZoom, 1

	; Create shortcut to Start Menu (Current User)
	IfExist, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe
	{
		If setupAllUsers
		{
			FileCreateShortcut, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe, %A_ProgramsCommon%\AeroZoom.lnk, %targetDir%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation and snipping tool,,
			FileCreateShortcut, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe, %A_DesktopCommon%\AeroZoom.lnk, %targetDir%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation and snipping tool,,
		}
		Else
		{
			FileCreateShortcut, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe, %A_Programs%\AeroZoom.lnk, %targetDir%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation and snipping tool,,
			FileCreateShortcut, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe, %A_Desktop%\AeroZoom.lnk, %targetDir%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation and snipping tool,,
		}
	}
	; if a shortcut is in startup, re-create it to ensure its not linked to the portable version's path
	; ** this method (create shortcut) to run aerozoom at startup is now deprected because the shortcut wont seem to run when uac is on
	; ** and it requires elevation unlike the 'create task' method
	IfExist, %A_Startup%\*AeroZoom*.*
	{
		FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
		FileDelete, %A_Startup%\*AeroZoom*.*
		;IfExist, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe
		;	FileCreateShortcut, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe, %A_Startup%\AeroZoom.lnk, %targetDir%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation and snipping tool,,
	}
	if A_IsAdmin
	{
		IfExist, %A_StartupCommon%\*AeroZoom*.* ; this is unnecessary as AeroZoom wont put shortcuts in all users startup but it will be checked too 
		{
			FileSetAttrib, -R, %A_StartupCommon%\*AeroZoom*.*
			FileDelete, %A_StartupCommon%\*AeroZoom*.*
			;IfExist, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe
			;	FileCreateShortcut, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe, %A_StartupCommon%\AeroZoom.lnk, %targetDir%\WanderSick\AeroZoom\,, AeroZoom`, the smooth wheel-zoom`, keyboard-free presentation and snipping tool,,
		}
	}
	if A_IsAdmin
	{
		RunWait, "%TaskPath%\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min
		if (errorlevel=4) { ; if task exists, recreate it to ensure it links to the correct aerozoom.exe
			if setupAllUsers
			{
				RunWait, "%TaskPath%\AeroZoom_Task.bat" /cretask /programfiles,"%A_WorkingDir%\",min
			} else {
				RunWait, "%TaskPath%\AeroZoom_Task.bat" /cretask /localappdata,"%A_WorkingDir%\",min
			}
			if (errorlevel=3) {
				RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 1
			}
		}
	}
	; Write uninstall entry to registry 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayIcon, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe,0
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayName, AeroZoom %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallDate, %A_YYYY%%A_MM%%A_DD%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, HelpLink, http://wandersick.blogspot.com
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, URLInfoAbout, http://wandersick.blogspot.com
	
	; ******************************************************************************************
	; ******************************************************************************************
	; ******************************************************************************************
	; ******************************************************************************************
	
	
	If setupAllUsers
		RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %targetDir%\WanderSick\AeroZoom\setup.exe /unattendAZ=2 /programfiles
	Else
		RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, UninstallString, %targetDir%\WanderSick\AeroZoom\setup.exe /unattendAZ=2
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, InstallLocation, %targetDir%\WanderSick\AeroZoom
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, DisplayVersion, %verAZ%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, %regKey%, Publisher, WanderSick
	; Calc folder size
	; SetBatchLines, -1  ; Make the operation run at maximum speed.
	EstimatedSize = 0
	Loop, %targetDir%\WanderSick\AeroZoom\*.*, , 1
	EstimatedSize += %A_LoopFileSize%
	EstimatedSize /= 1024
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, %regKey%, EstimatedSize, %EstimatedSize%
	IfExist, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe
	{
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}	
		Msgbox, 262144, AeroZoom, Successfully installed.`n`nAccess the uninstaller in 'Control Panel\Programs and Features' or run Setup.exe again. ; 262144 = Always on top
	} else {
		IfEqual, unattendAZ, 1
		{
			ExitApp, 1
		}
		Msgbox, 262192, AeroZoom, Installation failed.`n`nPlease ensure this folder is accessible:`n`n%targetDir%\WanderSick\AeroZoom
	}
} else {
	; if unattend switch is on, skip the check since user must be running the uninstaller from control panel
	; not from AeroZoom program
	IfNotEqual, unattendAZ, 1
	{
		MsgBox, 262180, AeroZoom Uninstaller , Uninstall AeroZoom and delete its perferences from the following location?`n`n%targetDir%\WanderSick\AeroZoom
		IfMsgBox No
		{
			Exitapp
		}
	}
	Gosub, KillProcess
	; begin uninstalling
	; remove startup shortcuts
	IfExist, %A_Startup%\*AeroZoom*.*
	{
		FileSetAttrib, -R, %A_Startup%\*AeroZoom*.*
		FileDelete, %A_Startup%\*AeroZoom*.*
	}
	if A_IsAdmin ; unnecessary as stated above
	{
		IfExist, %A_StartupCommon%\*AeroZoom*.*
		{
			FileSetAttrib, -R, %A_StartupCommon%\*AeroZoom*.*
			FileDelete, %A_StartupCommon%\*AeroZoom*.*
		}
	}
	; remove task
	if A_IsAdmin
	{
		RunWait, "%TaskPath%\AeroZoom_Task.bat" /deltask,"%A_WorkingDir%\",min
		RunWait, "%TaskPath%\AeroZoom_Task.bat" /check,"%A_WorkingDir%\",min
		if (errorlevel=5) {
			RegWrite, REG_SZ, HKCU, Software\WanderSick\AeroZoom, RunOnStartup, 0
		}
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
	;FileMove, %targetDir%\WanderSick\AeroZoom\Data\uninstall.bat, %temp%, 1 ; prevent deletion of this as it will be used
	FileSetAttrib, -R, %A_Programs%\AeroZoom.lnk 
	FileDelete, %A_Programs%\AeroZoom.lnk ; normally this is the only shortcut that has to be deleted
	FileSetAttrib, -R, %A_ProgramsCommon%\AeroZoom.lnk
	FileDelete, %A_ProgramsCommon%\AeroZoom.lnk
	FileSetAttrib, -R, %A_Desktop%\AeroZoom.lnk
	FileDelete, %A_Desktop%\AeroZoom.lnk
	FileSetAttrib, -R, %A_DesktopCommon%\AeroZoom.lnk
	FileDelete, %A_DesktopCommon%\AeroZoom.lnk
	FileSetAttrib, -R, %targetDir%\WanderSick\AeroZoom\*.*
	FileRemoveDir, %targetDir%\WanderSick\AeroZoom\Data, 1
	FileRemoveDir, %targetDir%\WanderSick\AeroZoom, 1
	FileCreateDir, %targetDir%\WanderSick\AeroZoom\Data
	;FileMove, %temp%\uninstall.bat, %targetDir%\WanderSick\AeroZoom\Data\, 1 ; prevent deletion of this as it will be used to schedule deletion of this setup.exe with AT
	;IfEqual, unattendAZ, 2
	;	Sleep, 1000
	IfNotExist, %targetDir%\WanderSick\AeroZoom\AeroZoom.exe ; i.e. if the removal was successful
	{
		;IfEqual, unattendAZ, 2 ; schedule to delete this setup.exe (and uninstall.bat) in a few mins since it cant delete itself
		;{
		;	if A_IsAdmin
		;	{
		;		If setupAllUsers
		;			Run, "%comspec%" /c uninstall.bat /schedule /programfiles,%targetDir%\WanderSick\AeroZoom\Data ; abort if non-admin as at.exe requires admin right
		;		Else
		;			Run, "%comspec%" /c uninstall.bat /schedule,%targetDir%\WanderSick\AeroZoom\Data ; abort if non-admin as at.exe requires admin right
		;	}
		;}
		IfEqual, unattendAZ, 1
		{
			ExitApp, 0
		}
		if ExistAZ
		{
			Msgbox, 262208, AeroZoom, Successfully uninstalled.`n`nPlease exit or restart AeroZoom manually for completion. ; to alert users of weird behaviours if still using AeroZoom
		} else {
			Msgbox, 262144, AeroZoom, Successfully uninstalled.
		}
	} else {
		IfEqual, unattendAZ, 1
		{
			ExitApp, 1
		}
		Msgbox, 262192, AeroZoom, Uninstalled partially.`n`nPlease remove this folder manually:`n`n%targetDir%\WanderSick\AeroZoom
	}
}

ExitApp
return

KillProcess: ; may not work for RunAsInvoker for Administrators accounts with UAC on. RunAsHighest will solve that, while letting Standard user accounts install to the correct profile.
Process, Close, magnify.exe
Process, Close, zoomit.exe
Process, Close, zoomit64.exe
Process, Close, wget.exe
Process, Close, AeroZoom.exe
Process, Close, AeroZoom_Alt.exe
Process, Close, AeroZoom_Ctrl.exe
Process, Close, AeroZoom_MouseL.exe
Process, Close, AeroZoom_MouseM.exe
Process, Close, AeroZoom_MouseR.exe
Process, Close, AeroZoom_MouseX1.exe
Process, Close, AeroZoom_MouseX2.exe
Process, Close, AeroZoom_Shift.exe
Process, Close, AeroZoom_Win.exe
Process, Close, ZoomPad.exe
return
