extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_add_replay_players") != -1)
	assert(source.find("sort_custom") != -1)
	assert(source.find("seat_index") != -1)
	assert(source.find("starting_stack") != -1)
	assert(source.find("ending_stack") != -1)
	assert(source.find("hole_cards") != -1)
