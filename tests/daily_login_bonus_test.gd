extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before: Dictionary = service.get_current_profile()
	var starting_chips: int = PlayerProfileScript.get_total_chips(before)
	var starting_gems: int = PlayerProfileScript.get_total_gems(before)
	var starting_xp: int = PlayerProfileScript.get_total_xp(before)

	var first: Dictionary = service.claim_daily_login_bonus("2026-06-28")
	_require(PlayerProfileScript.get_total_chips(first) == starting_chips + PlayerProfileScript.DAILY_LOGIN_CHIPS, "first daily login must add chips")
	_require(PlayerProfileScript.get_total_gems(first) == starting_gems, "daily login must not add gems")
	_require(PlayerProfileScript.get_total_xp(first) == starting_xp + PlayerProfileScript.DAILY_LOGIN_XP, "first daily login must add XP")

	var second: Dictionary = service.claim_daily_login_bonus("2026-06-28")
	_require(PlayerProfileScript.get_total_chips(second) == PlayerProfileScript.get_total_chips(first), "daily login must not double claim on same day")
	_require(PlayerProfileScript.get_total_xp(second) == PlayerProfileScript.get_total_xp(first), "daily login must not double claim XP on same day")

	ProfileServiceScript.reset_mock_profile()
	print("Daily login bonus test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
