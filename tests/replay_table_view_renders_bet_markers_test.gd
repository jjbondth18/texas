extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_add_replay_table_bet_marker") != -1)
	assert(source.find("ReplayBetMarker%d") != -1)
	assert(source.find("_replay_bet_marker_position") != -1)
	assert(source.find("_replay_bet_marker_style") != -1)
	assert(source.find("REPLAY_BET_MARKER_SIZE") != -1)
