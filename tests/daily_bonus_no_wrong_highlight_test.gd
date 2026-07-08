extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["last_daily_reward_date"] = "2026-07-01"
	profile["daily_reward_claimed_today"] = false
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	var days: Array = Array(state.get("days", []))
	for index in range(5):
		var claimed_day: Dictionary = Dictionary(days[index])
		_require(str(claimed_day.get("status_text", "")) == "CLAIMED", "history cards should show CLAIMED.")
		_require(not bool(claimed_day.get("highlight", false)), "history claimed cards should not be highlighted.")
	var day6: Dictionary = Dictionary(days[5])
	_require(bool(day6.get("highlight", false)), "only the current claimable card should be highlighted.")
	print("Daily bonus no wrong highlight test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
