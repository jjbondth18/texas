extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["last_daily_reward_date"] = "2026-07-08"
	profile["daily_reward_claimed_today"] = true
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	_require(str(state.get("action_line", "")) == "Next Reward: Day 6 available tomorrow", "claimed-today state should explain the next reward.")
	var day5: Dictionary = Dictionary(Array(state.get("days", []))[4])
	_require(str(day5.get("status_text", "")) == "CLAIMED TODAY", "today's claimed card should show CLAIMED TODAY.")
	_require(bool(day5.get("highlight", false)), "today's claimed card should keep a light highlight.")
	print("Daily bonus claimed today card test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
