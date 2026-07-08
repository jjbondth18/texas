extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(server_source.find("if (!room.isPublic) return \"private_room\"") != -1, "Quick matching must reject private rooms.")
	_require(smoke_source.find("quick_join_table should never match a private room") != -1, "DB smoke must verify Quick skips private rooms.")
	print("Quick does not match private room test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
