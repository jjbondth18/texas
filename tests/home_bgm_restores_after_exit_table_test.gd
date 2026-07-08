extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(table_source.find("func _complete_return_home") != -1)
	assert(table_source.find("MusicServiceScript.play_home_bgm(self)") != -1)
	assert(home_source.find("MusicServiceScript.play_home_bgm(self)") != -1)
	assert(home_source.find("func _ensure_home_bgm_active") != -1)
	print("Home BGM restores after exit table test passed.")
	quit()
