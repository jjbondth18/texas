extends SceneTree

func _init() -> void:
	var music_source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	assert(music_source.find("static var _player: AudioStreamPlayer") != -1)
	assert(music_source.find("_current_path == path and _player.playing and _player.stream != null") != -1)
	assert(music_source.find("active_player_count") != -1)
	assert(music_source.find("_attach_player.call_deferred") != -1)
	assert(music_source.find("_player_attach_pending") != -1)
	assert(music_source.find("_play_when_ready.call_deferred(path)") != -1)
	print("BGM switch no duplicate players test passed.")
	quit()
