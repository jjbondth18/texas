extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	assert(source.find("var _seat_order: Array[int] = []") != -1)
	assert(source.find("active_players.sort_custom(func(a, b): return int(a.get(\"seat_index\", a.get(\"seat_id\", 0))) < int(b.get(\"seat_index\", b.get(\"seat_id\", 0))))") != -1)
	assert(source.find("if next_order == _seat_order:\n\t\treturn") != -1)
	assert(source.find("if pill.get_index() != i:\n\t\t\t_rows_container.move_child(pill, i)") != -1)
	assert(source.find("occupied and raw_status != \"empty\" and has_player") != -1)
