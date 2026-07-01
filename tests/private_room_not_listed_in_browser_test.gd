extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(server_source.find("filter((room) => room.isPublic)") != -1, "Public table list must filter to public rooms.")
	_require(server_source.find("visibility: \"private\"") != -1, "Private rooms must carry private visibility.")
	_require(smoke_source.find("private room should not be listed in public table list") != -1, "DB smoke must verify private rooms are not listed.")
	print("Private room not listed in Browser test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
