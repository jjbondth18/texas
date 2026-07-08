extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(home_source.find("func _show_replay_fullscreen_overlay") != -1, "Home should manage replay fullscreen overlay.")
	_require(home_source.find("MusicServiceScript.play_table_bgm(self)") != -1, "Replay fullscreen playback should switch to table BGM.")
	print("Table BGM plays on replay table test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
