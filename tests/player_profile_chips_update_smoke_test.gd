extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before := service.get_current_profile()
	var starting_chips: int = PlayerProfileScript.get_total_chips(before)
	var after := service.apply_session_profit(3450)
	_require(PlayerProfileScript.get_total_chips(after) == starting_chips + 3450, "profile chips must increase by profit")

	var next_service := ProfileServiceScript.new()
	var persisted := next_service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(persisted) == starting_chips + 3450, "saved profile chips must be readable by new service")

	ProfileServiceScript.reset_mock_profile()
	print("Player profile chips update smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
