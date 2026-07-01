extends SceneTree

const MockTableSimulation := preload("res://scripts/demo/mock_table_simulation.gd")


func _init() -> void:
	var expected := [5, 8, 2, 6, 4, 9, 1, 7, 3]
	_assert(MockTableSimulation.TABLE_SEAT_JOIN_ORDER_9P == expected, "Mock table seat order must match the UI contract.")
	_assert(MockTableSimulation.table_seat_join_order_9p() == expected, "Seat order helper must expose the same objective order.")
	for seat_id in range(1, 10):
		_assert(MockTableSimulation.visual_position_for_seat_index(seat_id, 5) == seat_id, "Visual position must not rotate around local seat.")
		_assert(MockTableSimulation.visual_position_for_seat_index(seat_id, 8) == seat_id, "Visual position must remain objective for every client.")

	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_assert(server_source.find("const TABLE_SEAT_JOIN_ORDER_9P = [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "Server must keep the canonical 9P seat order constant.")
	_assert(server_source.find("const PUBLIC_SEAT_JOIN_ORDER = TABLE_SEAT_JOIN_ORDER_9P") != -1, "Public seat order must alias the canonical 9P contract.")
	print("Table seat join order contract test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
