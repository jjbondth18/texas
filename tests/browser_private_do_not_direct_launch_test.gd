extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var browser_create := _function_body(source, "func _create_public_chip_table_from_browser")
	_require(browser_create.contains("_show_public_table_setup()"), "Browser Create must show setup first")
	_require(not browser_create.contains("_open_backend_table"), "Browser Create must not directly enter a table")
	var friends_panel := _function_body(source, "func _build_friends_room_panel")
	_require(friends_panel.contains("_show_private_room_setup"), "Private Create must show setup first")
	_require(not friends_panel.contains("_open_backend_table(_friends_room_context)"), "Private Create must not directly enter a table")
	print("Browser/private do not direct launch test passed.")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start: int = source.find(signature)
	if start < 0:
		return ""
	var next: int = source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
