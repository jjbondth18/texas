extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(home_source.find("MusicServiceScript.play_home_bgm(self)") != -1, "Home should request home BGM.")
	_require(home_source.find("func _hide_replay_fullscreen_overlay") != -1 and home_source.find("MusicServiceScript.play_home_bgm(self)") != -1, "Leaving replay fullscreen should restore home BGM.")
	_require(table_source.find("MusicServiceScript.play_home_bgm(self)") != -1, "Returning from table should request home BGM.")
	print("Home BGM restored after exit table test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
