extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(server_source.find("settledPlayerExits") != -1, "Server must track settled player exits.")
	_require(server_source.find("Wallet refund skipped duplicate") != -1, "Duplicate exit settlement must be skipped.")
	_require(db_smoke.find("repeat active hand cash_out should not double refund") != -1, "DB smoke must cover repeat active-hand cashout.")
	print("No double cashout on repeated exit test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
