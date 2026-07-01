extends SceneTree


func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(table_source.find("SESSION COMPLETE") != -1, "Session complete panel must exist.")
	_require(table_source.find("_handle_server_session_complete_state") != -1, "Server session_complete snapshot must show the session panel.")
	_require(table_source.find("Final Stacks") != -1, "Session complete panel must list final stacks.")
	_require(table_source.find("EXIT TABLE") != -1, "Session complete panel must expose Exit Table.")
	print("Session complete panel test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
