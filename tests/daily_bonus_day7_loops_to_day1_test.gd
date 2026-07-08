extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 7
	profile["last_daily_reward_date"] = "2026-07-07"
	profile["daily_reward_claimed_today"] = true
	var next_state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	_require(int(next_state.get("current_day", 0)) == 1, "after claiming day 7, the next eligible claim should return to day 1.")
	_require(bool(Dictionary(Array(next_state.get("days", []))[0]).get("claimable", false)), "day 1 should be claimable after the day 7 cycle completes.")
	print("Daily bonus day 7 loops to day 1 test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
