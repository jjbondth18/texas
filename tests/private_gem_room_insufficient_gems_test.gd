extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("this.ensureCanAffordRoom(client, room)") != -1, "Private room code join must check gem affordability before joining.")
	_require(server_source.find("insufficient_gems") != -1, "Private Gem room must be able to reject insufficient Gems.")
	print("Private Gem room insufficient gems test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
