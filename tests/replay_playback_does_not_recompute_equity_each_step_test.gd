extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("var _equity_cache: Dictionary = {}") != -1)
	assert(source.find("func _build_equity_cache() -> void:") != -1)
	assert(source.find("ReplayEquityTableScript.build_table(_record, \"preflop\"") != -1)
	assert(source.find("_update_equity_highlight(_current_equity_phase())") != -1)
	assert(source.find("equity_recomputed=false") != -1)
