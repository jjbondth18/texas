extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["last_daily_reward_date"] = "2026-07-01"
	profile["daily_reward_claimed_today"] = false
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	var day6: Dictionary = Dictionary(Array(state.get("days", []))[5])
	_require(bool(day6.get("claimable", false)), "day 6 must show CLAIM when five cycle days are already claimed and today is available.")
	_require(not bool(day6.get("claimed", false)), "day 6 should not show CLAIMED before claim.")
	_require(not bool(day6.get("locked", false)), "day 6 should not be locked when it is current.")
	print("Daily bonus day 6 claim visible test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
