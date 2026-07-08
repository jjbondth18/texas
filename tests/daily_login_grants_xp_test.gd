extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before: Dictionary = service.get_current_profile()
	var starting_xp: int = PlayerProfileScript.get_total_xp(before)
	var first: Dictionary = service.claim_daily_login_bonus("2026-07-07")
	_require(PlayerProfileScript.get_total_xp(first) == starting_xp + PlayerProfileScript.DAILY_LOGIN_XP, "daily login should grant XP.")
	_require(int(first.get("level", 0)) == PlayerProfileScript.level_for_total_xp(PlayerProfileScript.get_total_xp(first)), "daily login should refresh level.")
	ProfileServiceScript.reset_mock_profile()
	print("Daily login grants XP test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
