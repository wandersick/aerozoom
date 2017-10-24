@echo off

:: for use with the AeroZoom main script. by wandersick
:: requires: AeroZoom_Task_Body.xml

:: AeroZoom installs into program files (x86) instead of program files in x64 OS
:: but there's no need to check for that using '%programw6432%' in this script as the use of setup.exe (x86) should make it redirect to program files (x86) automatically

:: BE CAREFUL: since %programfiles% would expand to C:\Program Files (x86) in x64 OS. If it is inside an if, i.e. if (%programfiles%...). after it expands, script will break
:: %CD% can expand to Program Files as well when toggling tasks in AeroZoom Tool menu
set targetDir=%CD%
if /i "%~2"=="/programfiles" set targetDir=%programfiles%\WanderSick\AeroZoom
if /i "%~2"=="/localappdata" set targetDir=%localappdata%\WanderSick\AeroZoom

If exist "AeroZoom_Task_Body.xml" (
	set TaskPath=.
) else if exist "Data\AeroZoom_Task_Body.xml" (
	set TaskPath=Data
)

if /i "%~1"=="/cretask" goto :createtask
:: to fix a bug of zh-CN\schtasks.exe.mui in Windows 7 Simplified Chinese http://t.co/EmSj8w1
chcp 437
schtasks /query | find /i "AeroZoom_%Username%"
:: if exist, delete it and exit with code 2
if %errorlevel% NEQ 0 (
	if /i "%~1"=="/check" exit /b 5
	if /i not "%~1"=="/deltask" goto :createTask
) else (
	if /i "%~1"=="/check" exit /b 4
)
schtasks /delete /TN "AeroZoom_%Username%" /F
if %errorlevel%==0 exit /b 2
:: if there is a problem, exit with code 1
exit /b 1

:: dynamically create / delete task to run AeroZoom on startup (for the current user only)

:: why this script?
:: strange! win7 cant start up aerozoom (due to uac? when uac is off it is ok)
:: and using schtasks method is simply better because it wont ask for elevation. (thx to /RL HIGHEST)

:: schtasks can't specify working directory. can't seem to /u without requiring a password
:: using /xml can solve these problems, hence this script contains lots of ^<'s and requires AeroZoom_Task_Body.xml

:: accepted parameters: /cretask -- create task always. if already exist, overwrite
::                      /deltask -- delete task always. if dont exist, still delete but return error. thats normal.
::                      /check   -- check if exist.
::                   no paramter -- dynamically delete if exist and create if not exist

:: second parameter: /programfiles or /localappdata 
:: by default this script creates task for the aerozoom.exe under the working directory (e.g. portable version)
:: but there are times user may be installing aerozoom which requires recreation of the task for the aerozoom.exe in the program files or localappdata
:: note even if aerozoom is installed for all users in programfiles, this /programfiles switch wont affect all users but the current one

:: return code explanation: 1: problem creating/deleting tasks/task does not exist while deleting.
::                          2: task deleted.
::                          3: task created.
::                          4: task exists
::                          5: task does not exist

:createTask
title Creating AeroZoom Task
echo ^<?xml version="1.0" encoding="UTF-16"?^> 	> "%temp%\AeroZoom_Task.xml"
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> 	>> "%temp%\AeroZoom_Task.xml"
echo  ^<Triggers^> 	>> "%temp%\AeroZoom_Task.xml"
echo    ^<LogonTrigger^>	 >> "%temp%\AeroZoom_Task.xml"
echo      ^<Enabled^>true^</Enabled^>		>> "%temp%\AeroZoom_Task.xml"
echo      ^<UserId^>%computername%\%username%^</UserId^>	 >> "%temp%\AeroZoom_Task.xml"
type "%TaskPath%\AeroZoom_Task_Body.xml"		>> "%temp%\AeroZoom_Task.xml"
echo.	 >> "%temp%\AeroZoom_Task.xml"
echo      ^<Command^>%targetDir%\AeroZoom.exe^</Command^>	 >> "%temp%\AeroZoom_Task.xml"
echo      ^<WorkingDirectory^>%targetDir%\^</WorkingDirectory^>	 >> "%temp%\AeroZoom_Task.xml"
echo    ^</Exec^>		>> "%temp%\AeroZoom_Task.xml"
echo  ^</Actions^>		>> "%temp%\AeroZoom_Task.xml"
echo ^</Task^>		>> "%temp%\AeroZoom_Task.xml"
:: to allow each user create their own task name
SCHTASKS /Create /TN "AeroZoom_%Username%" /IT /XML "%temp%\AeroZoom_Task.xml" /F
if %errorlevel%==0 exit /b 3
:: if there is a problem, exit with code 1
exit /b 1