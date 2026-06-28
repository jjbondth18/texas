extends SceneTree

const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	var migrated: Dictionary = PlayerProfileScript.normalized_dict({
		"name": "LegacyPlayer",
		"chips": 10000,
	})
	var unlocked: Array = Array(migrated.get("unlocked_avatar_ids", []))
	var selected: String = PlayerProfileScript.get_avatar_id(migrated)

	_require(not unlocked.is_empty(), "legacy profile must receive default unlocked avatars")
	_require(unlocked.has(selected), "selected avatar must be unlocked")
	_require(AvatarLibraryScript.get_avatar_by_id(selected) != null, "selected avatar must resolve to a texture")

	print("Profile default avatars test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
