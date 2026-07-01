extends SceneTree

func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var ready_body: String = _function_body(table_source, "func _should_show_public_ready_entry")

	_require(ready_body.find("not _server_seat_confirmed") != -1, "Ready button must require confirmed server seat.")
	_require(ready_body.find("_server_local_seat_index < 0") != -1, "Ready button must stay hidden while local seat is -1.")
	_require(ready_body.find("_real_public_player_count_from_flow() >= 1") != -1, "Ready button should appear after the creator is seated.")
	print("Public ready button requires seated test passed.")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start: int = source.find(signature)
	if start < 0:
		return ""
	var next_func: int = source.find("\nfunc ", start + signature.length())
	if next_func < 0:
		return source.substr(start)
	return source.substr(start, next_func - start)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
