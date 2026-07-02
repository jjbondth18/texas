extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var playback_pos: int = source.find("_open_replay_playback")
	assert(playback_pos != -1)
	var store_pos: int = source.find("func _build_store_panel")
	var playback_source: String = source.substr(playback_pos, store_pos - playback_pos)
	assert(source.find("Read-only hand playback") != -1)
	assert(playback_source.find("FOLD") == -1)
	assert(playback_source.find("CHECK") == -1)
	assert(playback_source.find("CALL") == -1)
	assert(playback_source.find("RAISE") == -1)
	assert(playback_source.find("ADD CHIPS") == -1)
	assert(playback_source.find("START AI WARM-UP") == -1)
	assert(source.find("_set_replay_playback_layout(true)") != -1)
