extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = 100
	profile["chips"] = 100
	profile["unlocked_avatar_ids"] = ["4_05"]
	service.save_current_profile(profile)
	var result: Dictionary = service.purchase_avatar_with_chips("1_03", AvatarLibraryScript.DEFAULT_AVATAR_PRICE_CHIPS)
	var after: Dictionary = Dictionary(result.get("profile", {}))
	_require(not bool(result.get("success", true)), "not enough chips should block avatar purchase.")
	_require(PlayerProfileScript.get_total_chips(after) == 100, "blocked purchase should not deduct chips.")
	_require(not Array(after.get("unlocked_avatar_ids", [])).has("1_03"), "blocked purchase should not unlock avatar.")
	ProfileServiceScript.reset_mock_profile()
	print("Avatar purchase not enough chips test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
