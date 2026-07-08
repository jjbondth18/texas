extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var music_source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	assert(music_source.find("HOME_BGM_PATH := \"res://assets/music/bgm1.ogg\"") != -1)
	assert(home_source.find("MusicServiceScript.play_home_bgm(self)") != -1)
	assert(home_source.find("call_deferred(\"_ensure_home_bgm_active\")") != -1)
	print("Home BGM plays on start test passed.")
	quit()
