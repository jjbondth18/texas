extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("\"Seat\"") != -1)
	assert(source.find("\"Player\"") != -1)
	assert(source.find("\"Preflop\"") != -1)
	assert(source.find("\"Flop\"") != -1)
	assert(source.find("\"Turn\"") != -1)
	assert(source.find("\"River\"") != -1)
	assert(source.find("\"Final\"") != -1)
