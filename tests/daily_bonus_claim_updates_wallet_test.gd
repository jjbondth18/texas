extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	_require(repository_source.find("this.walletRepository.addChips(playerId, reward.chips") != -1, "claim should add reward chips to the server wallet.")
	_require(repository_source.find("reason: \"daily_login_bonus_chips\"") != -1, "claim should write a chip wallet transaction.")
	_require(db_smoke_source.find("claim_daily_bonus should grant day 1 chips") != -1, "db smoke should verify claim changes wallet chips.")
	print("Daily bonus claim updates wallet test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
