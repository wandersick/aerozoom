@echo off
:: *********************************************************
:: Name: Check for Update (Subscript for AeroZoom)
:: Version: 0.7
:: Creation Date: 4/9/2009
:: Last Modified: 24/11/2009
:: Author: wandersick
:: Email: wandersick@gmail.com
:: Web: wandersick.blogspot.com
:: Supported OS: Windows 2000 or later
:: *********************************************************
:: Description: Used to check for new version using Google.
:: Return Codes: 0 (success) 1 (no update) 2 (net error)
:: *********************************************************

setlocal ENABLEDELAYEDEXPANSION

:: debugging options
:: set debug=1
:: set debug2=1
if defined debug echo :: Debugging mode 1 is ON.
if defined debug2 echo on&set debug=1&echo :: Debugging mode 2 is ON.

:: grab directory where this is run
set workDir1=%cd%\
:: if user is using Enhanced Command Prompt Portable, first go back to its root for a quicker location of swi
if defined ECPP popd
:: grab directory where this resides
for /f "usebackq tokens=* delims=" %%i in (`dir /a /b /s %~nx0 2^>nul`) do @set workDir2=%%~dpi
if "%workDir2%"=="" echo.&echo  ** ERROR: Working directory incorrect and cannot be corrected. &echo.&echo  "%~nx0" cannot be found in "%CD%".&echo.&goto :EOF
:: this line is required to keep macro of ECPP working.
if defined ECPP pushd Exe
:: if they don't equal, correct the working dir by changing to the dir where this is found
if /i "%workDir1%" NEQ "%workDir2%" (
	set pushdBit=1
	pushd "%workDir2%"
)

set updateReturn=255

:: set path for "pushd %pathTemp%" and cscript
set PATH=%PATH%;%CD%;%CD%\3rdparty
set vbsPath=%CD%
set pathTemp=%temp%

:: declarations
set searchItems="ws.az.32b" "ws.az.33" "ws.az.35" "ws.az.40"

:: set to %temp% to make it work on read-only medium
set pathTemp=%temp%

:: web site to check update on.
set webSite=wandersick.blogspot.com

:: detect if system doesn't support "cscript"
cscript >nul 2>&1
if "%errorlevel%"=="9009" set noWSH=1

:: detect if system has WSH disabled unsigned scripts
:: if useWINSAFER = 1, the TrustPolicy below is ignored and use SRP for this option instead. So check if = 0.
:: if TrustPolicy = 0, allow both signed and unsigned; if = 1, warn on unsigned; if = 2, disallow unsigned.
for /f "usebackq tokens=3 skip=2" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v UseWINSAFER 2^>nul`) do (
	@if "%%a" EQU "0" (
		@for /f "usebackq tokens=3 skip=2" %%i in (`reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v TrustPolicy 2^>nul`) do (
			@if "%%i" GEQ "2" (
				set noWSH=1
			)
		)
	)
)

:: if noWSH is defined, quit script
:: /quiet is used to quit instead of pausing at this message
if defined noWSH (
	@if /i "%1"=="/quiet" (
		goto :EOF
	) else (
		echo.&echo :: There's a problem with Windows Scripting Host. Can't continue.&echo.&pause&goto :EOF
	)
)
:_update

echo.&echo.&echo                             .. Please wait ..

pushd "%pathTemp%"

:: REMINDER: keep "* Final" on server

for %%i in (%searchItems%) do (
	del UpdateAZ.tmp /F /Q >nul 2>&1
	wget --output-document=UpdateAZ.tmp --include-directories=www.google.com --accept=html -t2 -E -e robots=off -T 8 -U "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+" http://www.google.com/search?as_q=^&hl=en-US^&num=10^&as_epq=%%~i^&as_oq=^&as_eq=^&lr=^&cr=^&as_ft=i^&as_filetype=^&as_qdr=all^&as_occt=any^&as_dt=i^&as_sitesearch=%webSite% >nul 2>&1
	@if !errorlevel! NEQ 0 (
		echo.&echo :: An error occured during update check^^^! Verify Internet connectivity.&echo.&echo :: Going back in a few seconds...&((timeout /T 7 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1))
	)
	REM check if the downloaded page is empty (i.e. actually not downloaded)
	@for /f "usebackq tokens=* delims=" %%a in (`type UpdateAZ.tmp`) do set udContent=%%a
	find /i "did not match any documents" "UpdateAZ.tmp" >nul 2>&1
	@if !errorlevel! EQU 0 (
		set updateFound=false
	) else (
		@if "!udContent!"=="" (
			set updateFound=error
		) else (
			set updateFound=true&goto updateFound
		)
	)
)
:updateFound
if defined debug echo updateFound: %updateFound%
if /i "%updateFound%"=="false" (
	set updateReturn=1
	@if not defined noWSH cscript //nologo "%vbsPath%\msgbox_updateNotFound.vbs"
	@if defined noWSH (
		echo 
		echo.&echo                         **  No update was found **&echo.&echo.&echo :: You may check manually at %website%&echo.&echo :: Going back in a few seconds...&((timeout /T 7 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1))
	)
) else if /i "%updateFound%"=="error" (
	set updateReturn=2
	@if not defined noWSH cscript //nologo "%vbsPath%\msgbox_updateError.vbs"
	@if defined noWSH (
		echo 
		echo.&echo :: An error occured during update check^^^! Verify Internet connectivity.&echo.&echo :: Going back in a few seconds...&((timeout /T 7 >nul 2>&1) || (ping -n 6 -l 2 127.0.0.1 >nul 2>&1))
	)
) else if /i "%updateFound%"=="true" (
	REM flashes taskbar
	REM start "" "_winflash_wget.exe"
	set updateReturn=0
	@if not defined noWSH cscript //nologo "%vbsPath%\msgbox_updateFound.vbs"
	@if defined noWSH (
		echo 
		call _choiceYn ":: A new version seems available. Visit %website% now? [Y,N]" N 20
		@if !errorlevel! EQU 0 start http://%website%
	)
)
:: return from temp folder
popd
:: return from work dir correction
if defined pushdBit popd&set pushdBit=
:: these has to be on the same line or return codes will be 255
endlocal&exit /b %updateReturn%