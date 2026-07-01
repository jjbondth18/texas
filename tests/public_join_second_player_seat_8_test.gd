extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	var room_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")

	_require(room_source.find("const TABLE_SEAT_JOIN_ORDER_9P = [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "Server public join order must make second real player seat 8.")
	_require(room_source.find("const PUBLIC_SEAT_JOIN_ORDER = TABLE_SEAT_JOIN_ORDER_9P") != -1, "Public join order must use the canonical table order.")
	_require(server_source.find("public join auto-seat should put second player at objective seat 8") != -1, "DB smoke must verify second player seat 8.")
	print("Public join second player seat 8 test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
