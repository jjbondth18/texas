extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const StoreMockServiceScript := preload("res://scripts/services/store_mock_service.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var before: Dictionary = ProfileServiceScript.new().get_current_profile()
	var starting_gems: int = PlayerProfileScript.get_total_gems(before)
	var after: Dictionary = StoreMockServiceScript.new().mock_purchase_gems(500)
	_require(PlayerProfileScript.get_total_gems(after) == starting_gems + 500, "mock store gem purchase must add gems")
	var persisted: Dictionary = ProfileServiceScript.new().get_current_profile()
	_require(PlayerProfileScript.get_total_gems(persisted) == starting_gems + 500, "mock gem purchase must save profile")

	ProfileServiceScript.reset_mock_profile()
	print("Mock store buy gems test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
