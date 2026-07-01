extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_assert(table_source.find("for ordered_seat_id in MockTableSimulation.table_seat_join_order_9p():") != -1, "Warm-up AI should scan the canonical table seat order.")
	_assert(table_source.find("if int(ordered_seat_id) == MockTableSimulation.LOCAL_SEAT_INDEX:") != -1, "Warm-up AI should skip the local player's seat 5.")
	_assert(table_source.find("\"Warm-up AI %d\" % (activated + 1)") != -1, "Warm-up AI names should follow the assigned order.")
	_assert(table_source.find("_table_flow_seat_array_index(int(ordered_seat_id))") != -1, "Warm-up AI should assign by seat_id, not array order.")
	print("Warm-up AI table seat order test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
