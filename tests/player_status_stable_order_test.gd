extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	assert(source.find("var _seat_order: Array[int] = []") != -1)
	assert(source.find("TABLE_SEAT_JOIN_ORDER_9P") == -1)
	assert(source.find("active_players.sort_custom(func(a, b): return _seat_order_rank") != -1)
	assert(source.find("return seat_index if seat_index > 0 else 999") != -1)
	assert(source.find("if next_order == _seat_order:\n\t\treturn") != -1)
	assert(source.find("if pill.get_index() != i:\n\t\t\t_rows_container.move_child(pill, i)") != -1)
	assert(source.find("occupied and raw_status != \"empty\" and has_player") != -1)
