extends RefCounted

func run() -> void:
	var screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var helper_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(helper_source.find("MODE_OBJECTIVE") != -1)
	assert(screen_source.find("_equity_mode: String = ReplayEquityTableScript.MODE_OBJECTIVE") != -1)
	assert(screen_source.find("OBJECTIVE") != -1)
	assert(helper_source.find("_objective_rows") != -1)
	assert(screen_source.find("Objective - all hole cards known.") != -1)
