extends SceneTree

func _init() -> void:
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var context_source: String = FileAccess.get_file_as_string("res://scripts/app/table_launch_context.gd")

	_require(home_source.find("\"room_code\": room_code") != -1, "Launch context from Home must include room_code.")
	_require(context_source.find("static var room_code") != -1 and context_source.find("\"room_code\": room_code") != -1, "TableLaunchContext must persist room_code.")
	_require(table_source.find("Room Code: %s") != -1, "Poker table must display/log the private room code.")
	print("Private room table info code test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
