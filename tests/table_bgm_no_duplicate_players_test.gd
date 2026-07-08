extends SceneTree

func _init() -> void:
	var music_source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	_require(music_source.find("static var _player: AudioStreamPlayer") != -1, "MusicService should own one static BGM player.")
	_require(music_source.find("if _current_path == path and _player.playing") != -1, "MusicService should not restart an already playing track.")
	_require(music_source.find("active_player_count") != -1, "MusicService should expose duplicate-player test helper.")
	print("Table BGM no duplicate players test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
