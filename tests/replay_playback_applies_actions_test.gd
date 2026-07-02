extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_apply_replay_action_to_state") != -1)
	assert(source.find("pot_after") != -1)
	assert(source.find("player_stack_after") != -1)
	assert(source.find("bet_to") != -1)
	assert(source.find("\"small_blind\"") != -1)
	assert(source.find("\"timeout_auto_fold\"") != -1)
