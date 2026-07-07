extends RefCounted

func run() -> void:
	var screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var helper_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(helper_source.find("MODE_PERCEIVED") != -1)
	assert(screen_source.find("PERCEIVED") != -1)
	assert(screen_source.find("_make_equity_mode_button") != -1)
	assert(helper_source.find("_perceived_rows") != -1)
	assert(helper_source.find("_perceived_player_equity_label") != -1)
	assert(helper_source.find("Opponents combined") == -1)
	assert(screen_source.find("Perceived - each player knows only their own cards.") != -1)
