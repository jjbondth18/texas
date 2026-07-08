extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("gem_session_complete_cash_out") != -1, "Gem table session complete must cash out with gem_session_complete_cash_out.")
	print("Gem table session complete cashout test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
