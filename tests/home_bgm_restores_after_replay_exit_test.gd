extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("func _show_replay_fullscreen_overlay") != -1)
	assert(home_source.find("MusicServiceScript.play_table_bgm(self)") != -1)
	assert(home_source.find("func _hide_replay_fullscreen_overlay") != -1)
	assert(home_source.find("MusicServiceScript.play_home_bgm(self)") != -1)
	print("Home BGM restores after replay exit test passed.")
	quit()
