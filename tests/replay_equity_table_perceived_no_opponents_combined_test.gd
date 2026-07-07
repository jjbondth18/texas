extends RefCounted

func run() -> void:
	var helper_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	var screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var docs_source: String = FileAccess.get_file_as_string("res://docs/replay_record_architecture.md")
	assert(helper_source.find("Opponents combined") == -1)
	assert(helper_source.find("_opponent_range_label") == -1)
	assert(screen_source.find("Opponents combined") == -1)
	assert(screen_source.find("player-view estimate for") == -1)
	assert(docs_source.find("There is no `Opponents combined` row.") != -1)
