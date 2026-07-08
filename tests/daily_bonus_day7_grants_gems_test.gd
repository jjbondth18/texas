extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["daily_bonus_claim_count"] = 6
	profile["last_daily_reward_date"] = "2026-07-07"
	profile["daily_reward_claimed_today"] = true
	service.save_current_profile(profile)
	var before: Dictionary = service.get_current_profile()
	var after: Dictionary = service.claim_daily_login_bonus("2026-07-08")
	_require(PlayerProfileScript.get_total_gems(after) == PlayerProfileScript.get_total_gems(before) + 5, "day 7 should grant 5 gems.")
	_require(PlayerProfileScript.get_total_xp(after) == PlayerProfileScript.get_total_xp(before) + 50, "day 7 should grant 50 XP.")
	ProfileServiceScript.reset_mock_profile()
	print("Daily bonus day 7 grants gems test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
