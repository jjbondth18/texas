extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["last_daily_reward_date"] = "2026-07-01"
	profile["daily_reward_claimed_today"] = false
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	_require(str(state.get("summary_line", "")) == "Cycle Progress: 5 / 7", "summary should show clear cycle progress.")
	_require(str(state.get("action_line", "")) == "Today: Claim Day 6 reward", "available state should tell the player which day to claim.")
	var day6: Dictionary = Dictionary(Array(state.get("days", []))[5])
	_require(str(day6.get("status_text", "")) == "CLAIM", "current available day should show CLAIM.")
	print("Daily bonus clear status text test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
