extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var scene_source: String = FileAccess.get_file_as_string("res://scenes/screens/replay_poker_table_screen.tscn")
	assert(scene_source.find("Seat1Panel") != -1)
	assert(scene_source.find("Seat9Panel") != -1)
	assert(scene_source.find("CommunityBoard") != -1)
	assert(scene_source.find("PotDisplay") != -1)
	assert(source.find("PokerSeat") != -1)
	assert(source.find("current_bet") != -1)
	assert(source.find("cards") != -1)
	assert(source.find("is_turn") != -1)
