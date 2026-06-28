extends SceneTree

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = 9000
	profile["chips"] = 9000
	service.save_current_profile(profile)

	var result: Dictionary = service.transfer_chips_to_table(3000)
	var after: Dictionary = Dictionary(result.get("profile", {}))
	_require(int(result.get("amount", 0)) == 3000, "add chips must transfer requested amount")
	_require(PlayerProfileScript.get_total_chips(after) == 6000, "add chips must not increase wallet chips like a purchase")

	ProfileServiceScript.reset_mock_profile()
	print("Add chips not purchase test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
