@echo off
setlocal
:: ****************************************************************
:: Sub: ChoiceMulti
:: Version: 1.0
:: Creation Date: 2/11/2009
:: Last Modified: 2/11/2009
:: Author: wanderSick@C7PE 
:: Email: wanderSick@gmail.com
:: Web: wanderSick.blogspot.com
:: Supported OS: 2K/XP/Vista/7
:: Description: Properly fall back to set /p for systems without choice.exe
::              Differentiate choice.exe from Win 9x and 2003/Vista/7
::              Set /p also returns errorlevels.
::              Defineable number of choices; for YN choices, use ChoiceYN
:: Usage: See /? or /h
:: ****************************************************************

if "%~1"=="/?" (goto help) else if /i "%~1"=="" (goto help) else (goto _choiceMulti)

:help

echo.
echo :: ChoiceMulti 1.0 by wanderSick (wanderSick.blogspot.com)
echo.
echo  [Usage]
echo.
echo call _choiceMulti /msg "description" [/button "choices"] [/time "sec"]
echo                   [/default "choice"] [/errorlevel 1-9] 
echo                   [/choice "1" ["2"] ["3"] ["4"]...["9"]]
echo.
echo  /msg - the line users see when they are asked for input.
echo  /button - instead of ascending numbers, users can enter any of these
echo            specified to go to the choice. *1 *2
echo  /time - timeout after specified seconds (used with /default) *1 *2
echo  /default - default answer (used with /time) *1 *2
echo  /errorlevel - outputs errorlevels just as choice.exe. either this or
echo                /choice has to be set *1 *4
echo  /choice - when users makes a choice, what is carried out. either this or
echo            /errorlevel has to be set *1 *3 *4
echo.
echo  *1 optional
echo  *2 not applicable for "set /p" (you give up set /p support by setting it)
echo  *3 /choice must be the last switch, otherwise it would not run properly.
echo  *4 maximum supported choices: 9
:: due to arguments being %1-%9 without shift. may add more in future versions
echo.
echo  [Examples]
echo.
echo  1) "1" performs "echo 1", "2" performs "echo 2":
echo.
echo     :: call _choiceMulti /msg "Choose: [1,2]" /choice "echo 1" "echo 2"
echo.
echo  2) Same as 1st, except that after 5 seconds, default answer "1" is supplied.
echo.
echo     :: call _choiceMulti /msg "Choose: [1,2]" /Default 1 /Time 5 /choice
echo        "echo 1" "echo 2"
echo.
echo  3) Same as 1st, except button of choice 1,2 is swapped with A,B.
echo     "Set /p" would fail here; ensure the target system has choice.exe.
echo.
echo     :: call _choiceMulti /msg "Choose: [A,B]" /button AB /choice "echo 1"
echo        "echo 2"
echo.
echo  * /button is [optional]. when not set, numbering and ascending order,
echo    e.g. 123456789 are assumed to keep compatibility with set /p. If set /p
echo    is unneeded, then anything can be set, e.g. letters and descending order.
echo.
echo  4) This is the most common. Do nothing but errorlevels just as choice.exe.
echo.
echo     :: call _choiceMulti /msg "Choose: [1,2]" /errorlevel 2
echo.
echo  [Returns]
echo.
echo  ^%errorlevel^% 0-9, depends on user choice.
echo.
goto :_choiceMultiEnd

:_choiceMulti

:: process arguments

if /i "%~1"=="/msg" set choiceMultiMsg=%~2
if /i "%~1"=="/time" set choiceMultiTime=%~2
if /i "%~1"=="/default" set choiceMultiDefChoice=%~2
if /i "%~1"=="/button" set choiceMultiButton=%~2
if /i "%~1"=="/errorlevel" set errBit=1&set errBitNum=%~2
:: /choice must be the last switch because %1 to %9 are shifted to contain the content of choices
if /i "%~1"=="/choice" (
	set choiceBit=1
	shift & goto _choiceMultiArgEnd
	)
if "%~2" NEQ "" shift & goto _choiceMulti

:_choiceMultiArgEnd
set choiceMultiCount=0

if defined errBit @if defined choiceBit echo.&echo :: ERROR: /choice and /errorlevel can't be used together!&echo.&goto _choiceMultiEnd
:: automatically numbers and sets user-defined choices from /choice switch
:: e.g. /choice choice1 choice2 becomes set choiceMultiUserChoice1=choice1, set choiceMultiUserChoice2=choice2
:: make use of the 'call' technique

:: if user specifies just errorlevel outputs, supply "type nul" as the choice
if defined errBit (
	@for /l %%i in (1,1,%errBitNum%) do set choiceMultiUserChoice%%i="type nul"
) else (
	@for /l %%i in (1,1,9) do call set choiceMultiUserChoice%%i=%%%%i%
	)

:: count number of choices and save to choiceMultiCount
for /f "usebackq tokens=1,2 delims==" %%i in (`set choiceMultiUserChoice`) do @if "%%i" NEQ "" set /a choiceMultiCount+=1

:: calculate the choiceMultiButton value for use with choice.exe (not set /p, however), if user did not specify it
if not defined choiceMultiButton @for /l %%i in (1,1,%choiceMultiCount%) do call set choiceMultiButton=%%choiceMultiButton%%%%i

:_choiceMultiStart

:: if choice.exe (win98/95/nt) exists.
:: check if user defined /time and /default
if defined choiceMultiDefChoice (@if defined choiceMultiTime set choiceMultiOpt=/T:%choiceMultiDefChoice%,%choiceMultiTime% )
choice %choiceMultiOpt%/C:%choiceMultiButton% /N "%choiceMultiMsg%" 2>nul
:: errorlevel 9009 means no choice.exe; 255 means syntax error, i.e. try the next version of choice.exe
:: 9 is the max supported choices by this batch
if %errorlevel% LEQ 9 goto _choiceMultiErrorlevel

:: if choice.exe (win2003/vista/win7) exists
if defined choiceMultiDefChoice (@if defined choiceMultiTime set choiceMultiOpt=/T %choiceMultiTime% /D %choiceMultiDefChoice% )
choice %choiceMultiOpt%/C %choiceMultiButton% /N /M "%choiceMultiMsg%" 2>nul
if %errorlevel% LEQ 9 goto _choiceMultiErrorlevel

:: if neither exists (win2000/xp)
:_choiceMultiSetP
set choiceMultiSetP=
set /p choiceMultiSetP=%choiceMultiMsg%
:: detects if user specified an invalid answer
set choiceMultiSetPValid=0
:: compares the token 1 of "set choiceMultiUserChoice" with user input, i.e. if choiceMultiUserChoice1==choiceMultiUserChoice1 echo token 2
for /f "usebackq tokens=1,2 delims==" %%i in (`set choiceMultiUserChoice`) do (
	if "%%i"=="choiceMultiUserChoice%choiceMultiSetP%" %%~j&&set /a choiceMultiSetPValid+=1
	)
:: if user chose any of the valid answers, choiceMultiSetPValid becomes 1 and the loop is ended.
if %choiceMultiSetPValid% NEQ 1 goto _choiceMultiStart

:: endlocal and exit /b must reside on the same line in order to pass the error number to exit before endlocal.
endlocal & exit /b %choiceMultiSetP%

:_choiceMultiEnd
endlocal
goto :EOF

:_choiceMultiErrorlevel
:: this is used instead of the 'smarter' way used in _choiceMultiSetP because errorlevels need to be checked in descending order
:: if not defined, skip the line, otherwise it returns error if undefined
if not defined choiceMultiUserChoice9 goto _choiceMultiErr8
:: for loop to strip off the quotes (%%~i) that wraps each choiceMultiUserChoice*
for %%i in (%choiceMultiUserChoice9%) do @if "%errorlevel%"=="9" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr8
if not defined choiceMultiUserChoice8 goto _choiceMultiErr7
for %%i in (%choiceMultiUserChoice8%) do @if "%errorlevel%"=="8" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr7
if not defined choiceMultiUserChoice7 goto _choiceMultiErr6
for %%i in (%choiceMultiUserChoice7%) do @if "%errorlevel%"=="7" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr6
if not defined choiceMultiUserChoice6 goto _choiceMultiErr5
for %%i in (%choiceMultiUserChoice6%) do @if "%errorlevel%"=="6" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr5
if not defined choiceMultiUserChoice5 goto _choiceMultiErr4
for %%i in (%choiceMultiUserChoice5%) do @if "%errorlevel%"=="5" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr4
if not defined choiceMultiUserChoice4 goto _choiceMultiErr3
for %%i in (%choiceMultiUserChoice4%) do @if "%errorlevel%"=="4" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr3
if not defined choiceMultiUserChoice3 goto _choiceMultiErr2
for %%i in (%choiceMultiUserChoice3%) do @if "%errorlevel%"=="3" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr2
if not defined choiceMultiUserChoice2 goto _choiceMultiErr1
for %%i in (%choiceMultiUserChoice2%) do @if "%errorlevel%"=="2" %%~i & endlocal & exit /b %errorlevel%
:_choiceMultiErr1
if not defined choiceMultiUserChoice1 echo.&echo  ** Error! No choice defined.&echo.&pause&goto :EOF
for %%i in (%choiceMultiUserChoice1%) do @if "%errorlevel%"=="1" %%~i & endlocal & exit /b %errorlevel%

:: I found that when /msg contains a question mark it is considered an additional argument,
:: even if quoted, e.g. "which choice?" vs "which choice", making it inaccurate to assume a number
:: (need more investigation)