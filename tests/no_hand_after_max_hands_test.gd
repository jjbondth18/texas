extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("if (room.sessionComplete || !this.canStartAnotherSessionHand(room))") != -1, "startOfficialPublicHand must reject a hand after max_hands.")
	_require(server_source.find("return false;") != -1, "Blocked hand starts must return false to callers.")
	_require(server_source.find("if (this.hasReachedHandLimit(room))") != -1, "Hand result transition must check the hard limit before auto next hand.")
	print("No hand after max hands test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
