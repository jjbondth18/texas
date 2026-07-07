extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var replay_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("ReplayPokerTableScreenScene") != -1)
	assert(replay_source.find("ReplayPokerControls") != -1)
	assert(replay_source.find("ControlZone/MainButtons") != -1)
	assert(replay_source.find("ControlZone/RaiseControlPanel") != -1)
	assert(source.find("BACK TO DETAIL") != -1)
	assert(replay_source.find("\"BACK TO REPLAYS\"") == -1)
