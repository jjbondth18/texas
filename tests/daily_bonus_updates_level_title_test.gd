extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_xp"] = 475
	service.save_current_profile(profile)
	var after: Dictionary = service.claim_daily_login_bonus("2026-07-08")
	_require(int(after.get("level", 0)) == 6, "daily XP should refresh level after crossing threshold.")
	_require(str(after.get("current_title_name", "")) == "Table Regular", "daily XP should refresh title.")
	ProfileServiceScript.reset_mock_profile()
	print("Daily bonus updates level title test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
