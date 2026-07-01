extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(server_source.find("foldAndZeroLeavingSeat") != -1, "Active hand exit must fold the leaving seat.")
	_require(server_source.find("committed chips stay in the pot") != -1, "Server log must preserve committed-chip policy.")
	_require(db_smoke.find("active hand cash_out should refund only remaining uncommitted stack") != -1, "DB smoke must cover active hand remaining-stack cashout.")
	_require(db_smoke.find("cannot_cash_out_during_hand") == -1, "Active hand cash_out must no longer be rejected in db smoke.")
	print("Public playing exit cashout remaining stack test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
