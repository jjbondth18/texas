extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	var room_manager_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(repository_source.find("auditDailyBonus") != -1, "server should expose a daily bonus audit helper.")
	_require(repository_source.find("daily_login_bonus_chips") != -1, "audit should include daily bonus chip transactions.")
	_require(room_manager_source.find("[DailyBonusAudit] claimed without reward transaction") != -1, "claim path should warn when claimed rows are missing reward transactions.")
	print("Daily bonus audit transaction test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
