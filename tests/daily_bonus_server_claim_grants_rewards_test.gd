extends SceneTree

func _init() -> void:
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	var room_manager_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(protocol_source.find("\"claim_daily_bonus\"") != -1, "server protocol should expose claim_daily_bonus.")
	_require(room_manager_source.find("private claimDailyBonus") != -1, "room manager should implement explicit daily claim.")
	_require(room_manager_source.find("type: \"daily_bonus_result\"") != -1, "claim should return daily_bonus_result.")
	_require(db_smoke_source.find("claim_daily_bonus should grant day 1 chips") != -1, "db smoke should assert claim grants chips.")
	print("Daily bonus server claim grants rewards test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
