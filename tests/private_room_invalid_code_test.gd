extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(server_source.find("normalizeRoomCode") != -1, "Server must normalize room codes.")
	_require(server_source.find("throw new Error(\"room_not_found\")") != -1, "Server must reject unknown private room codes.")
	_require(home_source.find("Room not found.") != -1, "Home UI must map room_not_found to a clear message.")
	_require(smoke_source.find("join_private_table\", room_code: \"ZZZZ\"") != -1, "DB smoke must verify invalid private room code.")
	print("Private room invalid code test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
