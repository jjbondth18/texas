extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_add_replay_actions") != -1)
	assert(source.find("_action_line") != -1)
	assert(source.find("_street_label") != -1)
	assert(source.find("Preflop") != -1)
	assert(source.find("Showdown") != -1)
