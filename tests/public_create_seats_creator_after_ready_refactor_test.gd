extends SceneTree

func _init() -> void:
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(home_source.find("_open_server_table(room_id, table_info, 5)") != -1, "Browser Create must launch the creator with requested seat 5.")
	_require(server_source.find("public create auto-seat should put creator at objective seat 5") != -1, "DB smoke must verify objective creator seat 5.")
	print("Public create seats creator after ready refactor test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
