extends SceneTree

func _init() -> void:
	var player_profile_source := FileAccess.get_file_as_string("res://scripts/data/player_profile.gd")
	var server_repository_source := FileAccess.get_file_as_string("res://server/src/db/login_bonus_repository.ts")
	_require(player_profile_source.find("{\"day\": 5, \"chips\": 1500, \"xp\": 25, \"gems\": 0}") != -1, "client day 5 reward should be 1,500 chips.")
	_require(server_repository_source.find("{ day: 5, chips: 1500, xp: 25, gems: 0 }") != -1, "server day 5 reward should be 1,500 chips.")
	print("Daily bonus day 5 grants 1500 chips test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
