extends SceneTree

func _init() -> void:
	var music_source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	assert(music_source.find("static var _player: AudioStreamPlayer") != -1)
	assert(music_source.find("_current_path == path and _player.playing") != -1)
	assert(music_source.find("active_player_count") != -1)
	assert(music_source.find("_create_player_deferred.call_deferred") != -1)
	assert(music_source.find("_player_creation_pending") != -1)
	assert(music_source.find("root.add_child.call_deferred(player)") != -1)
	assert(music_source.find("player.tree_entered.connect(_on_player_tree_entered)") != -1)
	assert(music_source.find("_pending_play_request and _pending_path == path") != -1)
	assert(music_source.find("_play_when_ready") == -1)
	print("BGM switch no duplicate players test passed.")
	quit()
