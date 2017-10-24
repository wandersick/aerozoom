; Run this as admin and compile this with RunAsAdmin

RegRead,OSver,HKLM,SOFTWARE\Microsoft\Windows NT\CurrentVersion,CurrentVersion
if (OSver<6.0) {
	Msgbox,262208,AeroZoom UAC Tool,You are using an earlier OS. You don't need this.
}

retry:
RegRead,EnableLUA,HKLM,SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System,EnableLUA
if not EnableLUA
{
	Msgbox,262208,AeroZoom UAC Tool,UAC is already disabled. You don't need to run this.
	Exitapp
}

RegWrite,REG_DWORD,HKLM,SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System,EnableLUA,0x0
if errorlevel
{
	Msgbox,262197,ERROR,Problem updating the registry.
	IfMsgBox Retry
		goto, retry
}
else
{
	Msgbox,262212,Success,Please reboot to apply the new setting so that AeroZoom can run in full functionality mode.`n`nWould you like to restart PC now?
	IfMsgBox Yes
	{
		Shutdown, 2
		Exitapp, 100 ; let AeroZoom know a reboot is pending.
	}
}