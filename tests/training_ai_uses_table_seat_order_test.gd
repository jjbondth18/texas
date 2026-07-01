extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/local_mock_backend.gd")
	_assert(source.find("const TABLE_SEAT_JOIN_ORDER_9P := [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "Local mock backend must define the canonical 9P order.")
	_assert(source.find("for seat_id in TABLE_SEAT_JOIN_ORDER_9P:") != -1, "Training AI should derive occupied AI seats from the canonical order.")
	_assert(source.find("if seat_id == 5:") != -1, "Training AI should leave local seat 5 for the player.")
	_assert(source.find("ai_seat_ids.append(seat_id)") != -1, "Training AI should occupy seat 8, then 2, then 6, following the contract.")
	_assert(source.find("for ordered_seat_id in TABLE_SEAT_JOIN_ORDER_9P:") != -1, "Public mock/warm-up seats should also use the canonical order.")
	print("Training AI table seat order test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
