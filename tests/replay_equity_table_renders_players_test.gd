extends RefCounted

func run() -> void:
	var screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var helper_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(screen_source.find("ReplayEquityTableScript.build_table") != -1)
	assert(screen_source.find("ReplayEquityTablePanel") != -1)
	assert(helper_source.find("_sorted_players") != -1)
	assert(helper_source.find("seat_index") != -1)
	assert(helper_source.find("result.slice(0, min(9, result.size()))") != -1)
