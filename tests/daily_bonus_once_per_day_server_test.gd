extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(repository_source.find("already_claimed_today") != -1, "server status should expose already_claimed_today.")
	_require(repository_source.find("if (!beforeStatus.can_claim_today)") != -1, "server claim should block duplicate daily claims.")
	_require(db_smoke_source.find("claim_daily_bonus should not award twice on the same day") != -1, "db smoke should assert duplicate claim block.")
	print("Daily bonus once per day server test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
