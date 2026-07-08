extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var profile: Dictionary = PlayerProfileScript.default_profile()
	profile["daily_bonus_claim_count"] = 5
	profile["daily_bonus_claimed_days_in_cycle"] = 5
	profile["daily_bonus_cycle_day"] = 6
	profile["daily_bonus_can_claim_today"] = true
	profile["daily_bonus_status_synced"] = true
	profile["daily_reward_claimed_today"] = false
	var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(profile, "2026-07-08")
	var days: Array = Array(state.get("days", []))
	_require(days.size() == 7, "daily bonus must render seven day cards.")
	for day_index in range(5):
		_require(bool(Dictionary(days[day_index]).get("claimed", false)), "claimed cycle days should show claimed.")
	_require(bool(Dictionary(days[5]).get("claimable", false)), "day 6 should be claimable after five claimed days.")
	_require(bool(Dictionary(days[6]).get("locked", false)), "future day 7 should be locked.")
	for day in days:
		var item := Dictionary(day)
		_require(bool(item.get("claimed", false)) or bool(item.get("claimable", false)) or bool(item.get("locked", false)), "day cards must never have an empty state.")
	print("Daily bonus cycle UI states test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
