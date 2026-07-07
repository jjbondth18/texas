extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("ReplayEquityTablePanel") != -1)
	assert(source.find("Color(0.018, 0.012, 0.044, 0.56)") != -1)
	assert(source.find("Color(0.035, 0.025, 0.080, 0.42)") != -1)
	assert(source.find("Color(0.10, 0.055, 0.16, 0.50)") != -1)
	assert(source.find("Color(0.06, 0.16, 0.24, 0.62)") != -1)
