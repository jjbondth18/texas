extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_initial_replay_player_states") != -1)
	assert(source.find("starting_stack") != -1)
	assert(source.find("current_bet") != -1)
	assert(source.find("\"status\"] = \"active\"") != -1)
	assert(source.find("cards_text") != -1)
