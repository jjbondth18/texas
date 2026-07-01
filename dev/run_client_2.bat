@echo off
setlocal

REM Change this if Godot is not available on PATH.
set GODOT_EXE=godot

"%GODOT_EXE%" --path "%~dp0.." -- --dev-player-id=dev_player_2 --dev-player-name=DevPlayer2 --dev-save-suffix=p2
