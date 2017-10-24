@echo off
setlocal
:: ****************************************************************
:: Sub: ChoiceYN
:: Version: 1.0
:: Creation Date: 2/11/2009
:: Last Modified: 2/11/2009
:: Author: wanderSick@C7PE 
:: Email: wanderSick@gmail.com
:: Web: wanderSick.blogspot.com
:: Supported OS: 2K/XP/Vista/7
:: Description: Properly fall back to set /p for systems without choice.exe
::              Differentiate choice.exe from Win 9x and 2003/Vista/7
::              Set /p also returns errorlevels
::              Gives 2 choices, YN; for other choices, use ChoiceMulti
:: Usage: See /? or /h
:: ****************************************************************

if "%~1"=="/?" (goto help) else if /i "%~1"=="" (goto help) else (goto _choiceYn)

:help

echo.
echo :: ChoiceYN 1.0 by wanderSick (wanderSick.blogspot.com)
echo.
echo  [Usage]
echo.
echo  call _choiceYN "Message" [Default Choice] [Timeout]
echo.
echo  %%1 = message shown for choice.exe
echo  %%2 = optional default choice, e.g. %%defErrAct%% * 
echo  %%3 = optional time in seconds before applying default choice *
echo.
echo   * not applicable to "set /p"
echo.
echo  [Examples]
echo.
echo  1) Displays "An update is available. Get it now? [Y,N]"
echo.
echo     :: call _choiceYn "An update is available. Get it now? [Y,N]"
echo.
echo  2) Same as 1st, except that after 5 seconds, default answer "N" is supplied.
echo.
echo     :: call _choiceYn "An update is available. Get it now? [Y,N]" N 5
echo.
echo  [Returns]
echo.
echo  %%errorlevel%% EQU 0 means Y
echo  %%errorlevel%% NEQ 0 means N
echo.
goto :EOF

:_choiceYn

:: if choice.exe (win98/95/nt) exists.
:: detects if user specified default choice and time
if not "%~2"=="" (@if not "%~3"=="" set choiceYnOpt=/T:%~2,%~3 )
choice %choiceYnOpt%/C:YN /N %1 2>nul
if "%errorlevel%"=="2" exit /b 100
if "%errorlevel%"=="1" exit /b 0

:: if choice.exe (win2003/vista/win7) exists
if not "%~2"=="" (@if not "%~3"=="" set choiceYnOpt=/T %~3 /D %~2 )
choice %choiceYnOpt%/C YN /N /M %1 2>nul
if "%errorlevel%"=="2" exit /b 100
if "%errorlevel%"=="1" exit /b 0

:: if neither exists (win2000/xp)
set /p choiceYn=%1
if /i "%choiceYn%"=="Y" exit /b 0
if /i "%choiceYn%"=="N" exit /b 100
goto _choiceYn

endlocal
goto :EOF