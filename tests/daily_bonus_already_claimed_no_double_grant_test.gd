extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(repository_source.find("if (!beforeStatus.can_claim_today)") != -1, "server claim should branch before granting when already claimed.")
	_require(repository_source.find("daily_login_awarded: false") != -1, "already claimed response should not be a successful award.")
	_require(db_smoke_source.find("claim_daily_bonus should not award twice on the same day") != -1, "db smoke should verify duplicate claim does not change wallet.")
	print("Daily bonus already claimed no double grant test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
