extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before: Dictionary = service.get_current_profile()
	var reward: Dictionary = PlayerProfileScript.daily_bonus_reward_for_day(1)
	var after: Dictionary = service.claim_daily_login_bonus("2026-07-08")
	_require(PlayerProfileScript.get_total_xp(after) == PlayerProfileScript.get_total_xp(before) + int(reward.get("xp", 0)), "claim should grant daily XP.")
	ProfileServiceScript.reset_mock_profile()
	print("Daily bonus claim grants XP test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
