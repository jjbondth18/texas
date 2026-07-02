extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_current_equity_phase") != -1)
	assert(source.find("key == normalized_phase") != -1)
	assert(source.find("is_active_phase") != -1)
	assert(source.find("showdown") != -1)
	assert(source.find("return \"final\"") != -1)
