extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	assert(source.find("static var _pending_stream: AudioStream") != -1)
	assert(source.find("static var _pending_play_request := false") != -1)
	assert(source.find("_create_player_deferred.call_deferred") != -1)
	assert(source.find("root.add_child.call_deferred(player)") != -1)
	assert(source.find("not _player.is_inside_tree()") != -1)
	assert(source.find("player.tree_entered.connect(_on_player_tree_entered)") != -1)
	assert(source.find("_flush_pending_play.call_deferred()") != -1)
	assert(source.find("_warn_missing_resource_once") != -1)
	assert(source.find("_missing_resource_warnings.has(path)") != -1)
	assert(source.find("root.add_child(_player)") == -1)
