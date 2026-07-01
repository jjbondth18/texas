extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(server_source.find("throw new Error(\"table_full\")") != -1, "Server must reject full private rooms.")
	_require(home_source.find("Room is full.") != -1, "Home UI must map table_full to a clear message.")
	_require(smoke_source.find("table_full\", () => manager.handle(\"private_full_third\"") != -1, "DB smoke must verify full private room join fails.")
	print("Private room full test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
