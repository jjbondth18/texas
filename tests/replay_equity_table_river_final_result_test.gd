extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("_final_label") != -1)
	assert(source.find("_objective_final_value") != -1)
	assert(source.find('return "split" if winner_seats.size() > 1 else "win"') != -1)
	assert(source.find('return "loss"') != -1)
	assert(source.find('return "%.1f%%" % (float(value) * 100.0)') != -1)
	assert(source.find("return \"Split\"") != -1)
	assert(source.find("return \"Win\"") != -1)
	assert(source.find("return \"Loss\"") != -1)
	assert(source.find("return \"Folded\"") != -1)
	assert(source.find("needed_board_cards: int = 5 - known_board.size()") != -1)
