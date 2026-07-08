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
	var day7: Dictionary = service.claim_daily_login_bonus("2026-07-08")
	_require(int(day7.get("daily_bonus_claim_count", 0)) == 7, "day 7 claim should complete the cycle.")
	var next_state: Dictionary = PlayerProfileScript.daily_bonus_display_state(day7, "2026-07-09")
	_require(int(next_state.get("current_day", 0)) == 1, "after day 7, next claim should return to day 1.")
	ProfileServiceScript.reset_mock_profile()
	print("Daily bonus seven day cycle test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
