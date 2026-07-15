extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("_fold_phase_by_seat") != -1)
	assert(source.find("_folded_before_phase") != -1)
	assert(source.find('return "folded"') != -1)
	assert(source.find("return \"Folded\"") != -1)
	assert(source.find("active_players") != -1)
