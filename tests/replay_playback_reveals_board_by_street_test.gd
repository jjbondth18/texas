extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_board_for_street") != -1)
	assert(source.find("community.get(\"flop\", [])") != -1)
	assert(source.find("community.get(\"turn\", [])") != -1)
	assert(source.find("community.get(\"river\", [])") != -1)
	assert(source.find("force_full_board") != -1)
	assert(source.find("_replay_street_event_label") != -1)
