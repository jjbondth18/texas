extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	var add_index := repository_source.find("this.walletRepository.addChips(playerId, reward.chips")
	var claim_index := repository_source.find("INSERT INTO daily_login_claims")
	_require(add_index != -1, "claim should grant chips.")
	_require(claim_index != -1, "claim should write claimed state.")
	_require(add_index < claim_index, "claim should grant rewards before marking the day claimed inside the transaction.")
	_require(repository_source.find("claimedWithoutRewardTransaction") != -1, "daily bonus audit should detect claimed rows without reward transactions.")
	print("Daily bonus claimed requires reward grant test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
