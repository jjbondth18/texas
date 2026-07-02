extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("ReplayPokerTableHeader") == -1)
	assert(source.find("REPLAY MODE") != -1)
	assert(source.find("Step %d / %d") != -1)
	assert(source.find("BACK TO DETAIL") != -1)
	assert(source.find("BACK TO REPLAYS") != -1)
	assert(source.find("HIDE TIMELINE") != -1)
	assert(source.find("_top_right_action_bar.offset_left = -540.0") != -1)
	assert(source.find("_top_right_action_bar.offset_top = 24.0") != -1)
	assert(source.find("_top_right_action_bar.offset_right = -24.0") != -1)
