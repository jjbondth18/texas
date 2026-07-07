extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_top_right_action_bar.anchor_left = 1.0") != -1)
	assert(source.find("_top_right_action_bar.anchor_top = 0.0") != -1)
	assert(source.find("_top_right_action_bar.anchor_right = 1.0") != -1)
	assert(source.find("_top_right_action_bar.anchor_bottom = 0.0") != -1)
	assert(source.find("_top_right_action_bar.offset_left = -312.0") != -1)
	assert(source.find("_top_right_action_bar.offset_top = 10.0") != -1)
	assert(source.find("_top_right_action_bar.offset_right = -20.0") != -1)
	assert(source.find("_top_right_action_bar.offset_bottom = 52.0") != -1)
	assert(source.find("\"BACK TO REPLAYS\"") == -1)
	assert(source.find("BACK TO DETAIL") < source.find("HIDE TIMELINE"))
	assert(source.find("right_panel.position = Vector2(2240, 150)") != -1)
