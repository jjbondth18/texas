extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")

	_require(server_source.find("const HAND_RESULT_SHOWDOWN_MS = 5000") != -1, "Showdown result should display for 5 seconds.")
	_require(server_source.find("const HAND_RESULT_FOLD_MS = 2500") != -1, "Fold win result should display for 2.5 seconds.")
	_require(server_source.find("return \"hand_result\"") != -1, "Server should expose hand_result state.")
	_require(table_source.find("room_state in [\"waiting_ready\", \"starting_countdown\"]") != -1, "Ready UI should not appear during hand_result.")
	print("Public showdown result before next hand test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
