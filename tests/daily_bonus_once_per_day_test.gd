extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var first: Dictionary = service.claim_daily_login_bonus("2026-07-08")
	var second: Dictionary = service.claim_daily_login_bonus("2026-07-08")
	_require(PlayerProfileScript.get_total_chips(second) == PlayerProfileScript.get_total_chips(first), "same day should not grant chips twice.")
	_require(PlayerProfileScript.get_total_xp(second) == PlayerProfileScript.get_total_xp(first), "same day should not grant XP twice.")
	_require(PlayerProfileScript.get_total_gems(second) == PlayerProfileScript.get_total_gems(first), "same day should not grant gems twice.")
	ProfileServiceScript.reset_mock_profile()
	print("Daily bonus once per day test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
