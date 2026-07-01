extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	_assert(source.find("const TABLE_SEAT_JOIN_ORDER_9P := [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "PlayerStatus must use canonical table order.")
	_assert(source.find("active_players.sort_custom(func(a, b): return _seat_order_rank") != -1, "PlayerStatus must sort by seat-order rank, not turn order.")
	_assert(source.find("if next_order == _seat_order:\n\t\treturn") != -1, "Turn changes must not reorder existing rows.")
	_assert(source.find("_tween.tween_property(self, \"position:x\", target_x, duration)") != -1, "Active row should slide horizontally without changing layout order.")
	_assert(source.find("return 12.0 if is_left else -10.0") != -1, "Active offset should move rows toward the table.")
	_assert(source.find("var target_x: float = _active_offset() if is_turn else 0.0") != -1, "Inactive rows should return to neutral x position.")
	print("Player status active offset contract test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
