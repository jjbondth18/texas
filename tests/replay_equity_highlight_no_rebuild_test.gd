extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("var _equity_cells: Array = []") != -1)
	assert(source.find("func _update_equity_highlight(active_phase: String) -> void:") != -1)
	assert(source.find("_style_equity_cell(cell, is_header, key == normalized_phase)") != -1)
	assert(source.find("recreate_nodes=false") != -1)
	assert(source.find("_clear_children(_equity_table_grid)") != -1)
