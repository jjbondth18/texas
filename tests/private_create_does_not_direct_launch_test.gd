extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var private_mode_handler := _function_body(source, "func _on_mode_selected")
	_require(private_mode_handler.contains("set_state(LobbyState.FRIENDS_ROOM)"), "Private card must open Friends Room page first")
	_require(not private_mode_handler.contains("_open_backend_table(_local_backend.create_friends_room"), "Private card must not directly launch a private table")
	var friends_panel := _function_body(source, "func _build_friends_room_panel")
	_require(friends_panel.contains("_show_private_room_setup"), "Friends Room Create must show setup first")
	_require(not friends_panel.contains("_open_backend_table(_friends_room_context)"), "Friends Room Create must not directly launch a table")
	print("Private create does not direct launch test passed.")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
