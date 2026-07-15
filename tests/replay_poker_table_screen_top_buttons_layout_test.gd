extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find('secondary_row.name = "ReplaySecondaryActions"') != -1)
	assert(source.find("secondary_row.alignment = BoxContainer.ALIGNMENT_END") != -1)
	assert(source.find('secondary_row.add_theme_constant_override("separation", 12)') != -1)
	assert(source.find('_make_replay_button("BACK TO DETAIL", Vector2(146, 36))') != -1)
	assert(source.find('_make_replay_button("HIDE TIMELINE", Vector2(146, 36))') != -1)
	assert(source.find("_top_right_action_bar.visible = false") != -1)
	assert(source.find("_top_right_action_bar.offset_left") == -1)
	assert(source.find("\"BACK TO REPLAYS\"") == -1)
	assert(source.find("BACK TO DETAIL") < source.find("HIDE TIMELINE"))
