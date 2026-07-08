extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	_require(repository_source.find("const transaction = this.db.transaction") != -1, "claim should use a database transaction.")
	_require(repository_source.find("this.walletRepository.addChips(playerId, reward.chips") < repository_source.find("INSERT INTO daily_login_claims"), "wallet grant should happen before claimed insert so failures do not leave claimed-only state.")
	print("Daily bonus claim failure does not mark claimed test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
