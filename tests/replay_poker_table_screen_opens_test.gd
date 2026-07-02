extends RefCounted

func run() -> void:
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var scene_source: String = FileAccess.get_file_as_string("res://scenes/screens/replay_poker_table_screen.tscn")
	assert(home_source.find("ReplayPokerTableScreenScene") != -1)
	assert(home_source.find("ReplayPokerTableScreenScene.instantiate()") != -1)
	assert(home_source.find("_replay_poker_table_screen.set_replay_context") != -1)
	assert(scene_source.find("ReplayPokerTableScreen") != -1)
	assert(scene_source.find("res://scripts/screens/replay_poker_table_screen.gd") != -1)
