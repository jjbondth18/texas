extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("_deterministic_monte_carlo") != -1)
	assert(source.find("1.0 / float(max(winning_seats.size(), 1))") != -1)
	assert(source.find("active_players") != -1)
	assert(source.find("objective") != -1)
