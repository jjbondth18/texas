extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_build_replay_playback_steps") != -1)
	assert(source.find("_is_replay_player_action") != -1)
	assert(source.find("_replay_system_event_line") != -1)
	assert(source.find("\"kind\": \"event\"") != -1)
	assert(source.find("\"kind\": \"action\"") != -1)
