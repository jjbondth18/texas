extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["last_daily_reward_date"] = "2026-06-25"
	profile["daily_reward_claimed_today"] = false
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	_require(int(state.get("current_day", 0)) == 6, "missing days must not reset the seven-claim cycle.")
	_require(bool(Dictionary(Array(state.get("days", []))[5]).get("claimable", false)), "after missed days, the next unclaimed cycle day remains claimable.")
	print("Daily bonus cycle not consecutive streak test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
