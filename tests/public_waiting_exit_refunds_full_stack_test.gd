extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(server_source.find("left_before_official_hand") != -1, "Server must keep the pre-official-hand refund reason.")
	_require(server_source.find("!room.officialHandStarted") != -1, "Pre-hand public exit must be based on officialHandStarted.")
	_require(db_smoke.find("pre-hand cash out should write left_before_official_hand wallet transaction") != -1, "DB smoke must cover pre-hand full-stack refund.")
	print("Public waiting exit refunds full stack test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
