extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 6
	profile["daily_bonus_claimed_days_in_cycle"] = 6
	profile["daily_bonus_cycle_day"] = 6
	profile["daily_bonus_can_claim_today"] = false
	profile["last_daily_reward_date"] = "2026-07-08"
	profile["daily_reward_claimed_today"] = true
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	var day6: Dictionary = Dictionary(Array(state.get("days", []))[5])
	_require(bool(day6.get("claimed", false)), "today's claimed current day should show CLAIMED.")
	_require(not bool(day6.get("claimable", false)), "today's claimed current day should not show CLAIM.")
	print("Daily bonus claimed today shows claimed test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
