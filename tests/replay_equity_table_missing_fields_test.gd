extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("No equity data.") != -1)
	assert(source.find("return \"N/A\"") != -1)
	assert(source.find("return \"-\"") != -1)
	assert(source.find("players.is_empty()") != -1)
	assert(source.find("hole_cards.size() != 2") != -1)
