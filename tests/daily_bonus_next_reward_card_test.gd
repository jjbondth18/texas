extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["last_daily_reward_date"] = "2026-07-08"
	profile["daily_reward_claimed_today"] = true
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	var day6: Dictionary = Dictionary(Array(state.get("days", []))[5])
	var day7: Dictionary = Dictionary(Array(state.get("days", []))[6])
	_require(str(day6.get("status_text", "")) == "NEXT", "next reward card should show NEXT after today's claim.")
	_require(bool(day6.get("next", false)), "next reward card should be flagged as next.")
	_require(not bool(day6.get("highlight", false)), "next reward should not use the claim highlight.")
	_require(str(day7.get("status_text", "")) == "LOCKED", "later future cards should stay locked.")
	print("Daily bonus next reward card test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
