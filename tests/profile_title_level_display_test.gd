extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.normalized_dict({
		"name": "Luna0581",
		"total_xp": 420,
		"total_chips": 10000,
		"gems": 3,
		"selected_avatar_id": "4_05",
		"unlocked_avatar_ids": ["4_05"],
	})
	_require(int(profile.get("level", 0)) == 5, "420 XP should resolve to Level 5.")
	_require(int(profile.get("xp_current", -1)) == 20, "Level progress should be 20 / 100.")
	_require(str(profile.get("current_title_name", "")) == "Table Regular", "Level 5 should display Table Regular.")
	_require(str(profile.get("xp_text", "")) == "20 / 100 XP", "Profile XP text should use current / next.")
	print("Profile title level display test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
