extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const StoreMockServiceScript := preload("res://scripts/services/store_mock_service.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var before: Dictionary = ProfileServiceScript.new().get_current_profile()
	var starting_chips: int = PlayerProfileScript.get_total_chips(before)
	var after: Dictionary = StoreMockServiceScript.new().mock_purchase_chips(50000)
	_require(PlayerProfileScript.get_total_chips(after) == starting_chips + 50000, "mock store chip purchase must add chips")
	var persisted: Dictionary = ProfileServiceScript.new().get_current_profile()
	_require(PlayerProfileScript.get_total_chips(persisted) == starting_chips + 50000, "mock chip purchase must save profile")

	ProfileServiceScript.reset_mock_profile()
	print("Mock store buy chips test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
