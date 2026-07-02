extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_playback_state_for_step") != -1)
	assert(source.find("_replay_board_for_street") != -1)
	assert(source.find("\"board_cards\": board_cards") != -1)
	assert(source.find("ReplayTableBoard") != -1)
	assert(source.find("BOARD\\n%s") != -1)
