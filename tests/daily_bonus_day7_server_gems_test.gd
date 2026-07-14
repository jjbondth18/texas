extends SceneTree

func _init() -> void:
	var repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	_require(repository_source.find("{ day: 7, chips: 6000, xp: 50, gems: 100 }") != -1, "server day 7 reward should include 100 gems.")
	_require(repository_source.find("daily_login_bonus_gems") != -1, "server day 7 gems should use daily bonus transaction reason.")
	print("Daily bonus day 7 server gems test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
