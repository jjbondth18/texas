extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_state_source: String = FileAccess.get_file_as_string("res://server/src/table_state.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")

	_require(server_source.find("waiting_ready") != -1, "Public room must expose waiting_ready state.")
	_require(server_source.find("ready_count: this.publicReadyCount(room)") != -1, "Snapshots must include ready count.")
	_require(table_state_source.find("ready: boolean") != -1, "Seat model must store ready independently.")
	_require(table_state_source.find("seat.ready = ready") != -1, "Ready command must update seat ready flag.")
	_require(table_source.find("WAITING FOR READY") != -1, "UI should show Waiting for Ready.")
	_require(table_source.find("READY") != -1 and table_source.find("UNREADY") != -1, "UI should expose Ready/Unready.")
	_require(table_source.find("_toggle_server_public_ready") != -1, "Ready button must send ready command.")
	print("Public ready system test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
