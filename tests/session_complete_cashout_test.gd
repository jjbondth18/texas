extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("session_complete_cash_out") != -1, "Session complete exit must use a distinct wallet transaction reason.")
	_require(server_source.find("room.sessionComplete || room.table.phase === \"session_complete\"") != -1, "Session complete reason must be selected from room/table state.")
	print("Session complete cashout test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
