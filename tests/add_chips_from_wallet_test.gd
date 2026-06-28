extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = 10000
	profile["chips"] = 10000
	service.save_current_profile(profile)

	var table_chips: int = 5000
	var result: Dictionary = service.transfer_chips_to_table(5000)
	_require(bool(result.get("success", false)), "wallet transfer must succeed")
	table_chips += int(result.get("amount", 0))
	var after: Dictionary = Dictionary(result.get("profile", {}))
	_require(PlayerProfileScript.get_total_chips(after) == 5000, "add chips must deduct wallet chips")
	_require(table_chips == 10000, "add chips must increase table chips")

	ProfileServiceScript.reset_mock_profile()
	print("Add chips from wallet test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
