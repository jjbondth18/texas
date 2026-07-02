extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_top_right_action_bar.offset_top = 16.0") != -1)
	assert(source.find("_top_right_action_bar.offset_right = -24.0") != -1)
	assert(source.find("BACK TO DETAIL") < source.find("BACK TO REPLAYS"))
	assert(source.find("BACK TO REPLAYS") < source.find("HIDE TIMELINE"))
	assert(source.find("right_panel.position = Vector2(2240, 150)") != -1)
