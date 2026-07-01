@echo off
setlocal

REM Put your Godot executable path here, for example:
REM set "GODOT_EXE=C:\Users\jjbon\Downloads\Godot_v4.4.1-stable_win64.exe"
set "GODOT_EXE="
set "GODOT_FROM_PATH=0"

if "%GODOT_EXE%"=="" (
	for /f "delims=" %%G in ('where godot 2^>nul') do (
		set "GODOT_EXE=%%G"
		set "GODOT_FROM_PATH=1"
		goto :found_godot
	)
)

:found_godot
if "%GODOT_EXE%"=="" (
	echo Godot executable not found.
	echo Please edit this file and set GODOT_EXE to your Godot.exe path.
	pause
	exit /b 1
)

if "%GODOT_FROM_PATH%"=="0" if not exist "%GODOT_EXE%" (
	echo Godot executable not found: %GODOT_EXE%
	echo Please edit this file and set GODOT_EXE to your Godot.exe path.
	pause
	exit /b 1
)

echo Launching Texas client 1...
"%GODOT_EXE%" --path "%~dp0.."
if errorlevel 1 pause
