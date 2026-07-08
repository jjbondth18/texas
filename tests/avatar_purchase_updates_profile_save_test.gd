extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = 10000
	profile["chips"] = 10000
	profile["unlocked_avatar_ids"] = ["4_05"]
	service.save_current_profile(profile)
	service.purchase_avatar_with_chips("8_01", AvatarLibraryScript.DEFAULT_AVATAR_PRICE_CHIPS)
	var reloaded: Dictionary = ProfileServiceScript.new().get_current_profile()
	_require(Array(reloaded.get("unlocked_avatar_ids", [])).has("8_01"), "avatar purchase should persist unlock.")
	_require(PlayerProfileScript.get_avatar_id(reloaded) == "8_01", "avatar purchase should persist selected avatar.")
	_require(PlayerProfileScript.get_total_chips(reloaded) == 2500, "avatar purchase should persist chip deduction.")
	ProfileServiceScript.reset_mock_profile()
	print("Avatar purchase updates profile save test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
