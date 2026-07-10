extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
var _failures: Array[String] = []

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var legacy := service.apply_server_profile(
		{"player_id": "legacy_player", "display_name": "Legacy Name", "avatar_id": "default"},
		{"chips": 7777, "gems": 8},
		["default"]
	)
	_require(String(legacy.get("player_id", "")) == "legacy_player", "legacy player_id should apply")
	_require(PlayerProfileScript.get_player_name(legacy) == "Legacy Name", "legacy name should apply")
	_require(PlayerProfileScript.get_total_chips(legacy) == 7777, "legacy chips should apply")
	_require(PlayerProfileScript.get_total_gems(legacy) == 8, "legacy gems should apply")
	var previous_xp := int(legacy.get("total_xp", 0))
	var previous_hands := int(legacy.get("total_hands_played", 0))
	var partial := service.apply_server_profile_snapshot({"display_name": "Partial Update"})
	_require(int(partial.get("total_xp", -1)) == previous_xp, "partial snapshot should preserve XP")
	_require(int(partial.get("total_hands_played", -1)) == previous_hands, "partial snapshot should preserve stats")
	_require(PlayerProfileScript.get_total_chips(partial) == 7777, "partial snapshot should preserve wallet")
	_require(not bool(partial.get("is_new_player", false)), "missing is_new_player should default to false")
	ProfileServiceScript.reset_mock_profile()
	_finish("Server profile legacy fallback test passed.")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish(success_message: String) -> void:
	if _failures.is_empty():
		print(success_message)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
