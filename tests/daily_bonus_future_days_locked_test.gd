extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 3
	profile["daily_bonus_claimed_days_in_cycle"] = 3
	profile["daily_bonus_cycle_day"] = 4
	profile["daily_bonus_can_claim_today"] = true
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	var days: Array = Array(state.get("days", []))
	for day_index in range(4, 7):
		var day: Dictionary = Dictionary(days[day_index])
		_require(bool(day.get("locked", false)), "future days after the current claimable day should be locked.")
		_require(not bool(day.get("claimable", false)), "future days should not show CLAIM.")
	print("Daily bonus future days locked test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
