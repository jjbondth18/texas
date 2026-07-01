extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	_assert(source.find("active_players.sort_custom(func(a, b): return _seat_order_rank") != -1, "PlayerStatus must sort rows explicitly.")
	_assert(source.find("return seat_index if seat_index > 0 else 999") != -1, "PlayerStatus rows must rank by ascending seat_index.")
	_assert(source.find("TABLE_SEAT_JOIN_ORDER_9P") == -1, "PlayerStatus must not use 5,8,2,6 join order.")
	_assert(source.find("occupied and raw_status != \"empty\" and has_player") != -1, "PlayerStatus should skip empty seats.")
	print("Player status sorted by seat index test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
