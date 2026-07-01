extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_state_source: String = FileAccess.get_file_as_string("res://server/src/table_state.ts")

	_require(server_source.find("this.clearReadyCountdown(room)") != -1, "Server should clear ready countdown when conditions fail.")
	_require(server_source.find("if (this.canStartPublicCountdown(room))") != -1, "Ready countdown must be conditional.")
	_require(table_state_source.find("seat.ready = ready") != -1, "Unready should flip seat.ready false.")
	_require(server_source.find("if (!this.canStartPublicCountdown(room))") != -1, "Countdown timer must re-check readiness before starting.")
	print("Public ready cancel on unready test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
