extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var create_handler := _function_body(source, "func _create_public_chip_table_from_browser")
	_require(create_handler.contains("_show_public_table_setup()"), "Browser Create must show setup first")
	_require(not create_handler.contains("_start_table_launch_transition"), "Browser Create must not directly launch a table")
	_require(source.contains("_confirm_public_table_setup"), "Public setup confirm must handle table creation")
	print("Browser create does not direct launch test passed.")
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
