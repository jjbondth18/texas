extends SceneTree

func _init() -> void:
	var room_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(room_source.find("private_table_created") != -1, "private table creation path should exist")
	_require(room_source.find("visibility: \"private\"") != -1, "private rooms should use private visibility")
	_require(room_source.find("dealer_id: room.dealerId") != -1, "private table snapshot should reuse dealer_id table snapshot")
	print("Private room snapshot dealer id test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
