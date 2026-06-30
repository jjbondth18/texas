extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("func _on_join_pressed(room_id: String)"), "Table Browser join handler must exist")
	_require(source.contains("_start_table_launch_transition(\"Joining public table...\""), "Join existing public table must use launch transition")
	_require(source.contains("_join_public_chip_table_after_wallet_check(room_id)"), "Join existing public table must join the specified table")
	_require(not _join_handler_contains(source, "_show_public_table_setup"), "Join existing public table must not open create setup")
	_require(source.contains("_show_toast(\"Not enough wallet chips.\")"), "Join existing public table must show insufficient wallet chips")
	print("Table Browser join existing test passed.")
	quit(0)


func _join_handler_contains(source: String, needle: String) -> bool:
	var start := source.find("func _on_join_pressed(room_id: String)")
	var end := source.find("func _create_public_chip_table_from_browser", start)
	if start < 0 or end < 0:
		return false
	return source.substr(start, end - start).contains(needle)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
