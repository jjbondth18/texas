@echo off
setlocal

REM Change this if Godot is not available on PATH.
set GODOT_EXE=godot

"%GODOT_EXE%" --path "%~dp0.."
