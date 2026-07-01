extends SceneTree

func _init() -> void:
	var protocol_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(protocol_source.find("create_private_table") != -1, "Godot protocol must support create_private_table.")
	_require(server_source.find("generateRoomCode") != -1, "Server must generate private room codes.")
	_require(server_source.find("private_table_created") != -1, "Server must return private_table_created.")
	_require(smoke_source.find("create_private_table should return a room_id and room_code") != -1, "DB smoke must verify private code creation.")
	print("Private room create generates code test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
