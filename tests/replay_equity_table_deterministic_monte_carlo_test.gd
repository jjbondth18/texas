extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("MONTE_CARLO_TRIALS") != -1)
	assert(source.find("PERCEIVED_MONTE_CARLO_TRIALS") != -1)
	assert(source.find("rng.seed = int(abs(seed_text.hash()))") != -1)
	assert(source.find(":objective") != -1)
	assert(source.find(":perceived:") != -1)
