extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before: Dictionary = service.get_current_profile()
	var before_unlocked: Array = Array(before.get("unlocked_avatar_ids", []))

	var after: Dictionary = service.apply_session_result({
		"session_profit": 1500,
		"hands_played": 5,
		"hands_won": 1,
		"biggest_pot": 6000,
		"best_hand_desc": "Flush",
	})
	var new_ids: Array[String] = service.get_last_unlocked_avatar_ids()
	var after_unlocked: Array = Array(after.get("unlocked_avatar_ids", []))
	_require(not new_ids.is_empty(), "qualifying session must unlock avatars")
	for avatar_id in new_ids:
		_require(after_unlocked.has(avatar_id), "new avatar must be in unlocked list")
	_require(after_unlocked.size() == before_unlocked.size() + new_ids.size(), "unlocks must not duplicate ids")

	service.apply_session_result({
		"session_profit": 1500,
		"hands_played": 5,
		"hands_won": 1,
		"biggest_pot": 6000,
		"best_hand_desc": "Flush",
	})
	var second_new_ids: Array[String] = service.get_last_unlocked_avatar_ids()
	_require(second_new_ids.is_empty(), "already unlocked rule avatars must not unlock duplicates")

	ProfileServiceScript.reset_mock_profile()
	print("Session unlock avatar test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
