extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_state_source: String = FileAccess.get_file_as_string("res://server/src/table_state.ts")

	_require(server_source.find("const TABLE_SEAT_JOIN_ORDER_9P = [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "Public seat join order must match design.")
	_require(server_source.find("const PUBLIC_SEAT_JOIN_ORDER = TABLE_SEAT_JOIN_ORDER_9P") != -1, "Public seat assignment must alias the canonical table order.")
	_require(server_source.find("private firstAvailablePublicSeat(room: Room)") != -1, "Server should centralize public auto-seat assignment.")
	_require(server_source.find("for (const seatIndex of PUBLIC_SEAT_JOIN_ORDER)") != -1, "Server should scan objective public seat order.")
	_require(table_state_source.find("readonly maxSeats = 10") != -1, "Server table must have objective seats 0-9 available.")
	print("Public objective seat assignment test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
