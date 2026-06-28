extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile := service.get_current_profile()
	var unlocked: Array = Array(profile.get("unlocked_avatar_ids", []))
	_require(unlocked.has("1_01"), "default profile must unlock 1_01 for selection test")

	var selected: Dictionary = service.select_avatar("1_01")
	_require(PlayerProfileScript.get_avatar_id(selected) == "1_01", "select avatar must update selected_avatar_id")
	_require(String(selected.get("avatar", "")).ends_with("1_01.png"), "select avatar must update avatar path")

	var persisted: Dictionary = ProfileServiceScript.new().get_current_profile()
	_require(PlayerProfileScript.get_avatar_id(persisted) == "1_01", "selected avatar must persist")

	ProfileServiceScript.reset_mock_profile()
	print("Avatar select save test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
