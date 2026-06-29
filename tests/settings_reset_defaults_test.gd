extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")

func _init() -> void:
	var path := "user://test_settings_reset_defaults.cfg"
	SettingsServiceScript.reset_for_tests(path)
	ProfileServiceScript.reset_mock_profile()
	var profile_service := ProfileServiceScript.new()
	var before := profile_service.get_current_profile()
	var service := SettingsServiceScript.new()
	service.save_settings({
		"master_volume": 0.2,
		"animation_speed": "slow",
		"reduce_motion": true,
		"mute_all": true,
	})
	var reset := service.reset_defaults()

	_require(float(reset.get("master_volume", 0.0)) == 1.0, "reset must restore master volume")
	_require(String(reset.get("animation_speed", "")) == "normal", "reset must restore animation speed")
	_require(not bool(reset.get("reduce_motion", true)), "reset must restore reduce motion")
	_require(not bool(reset.get("mute_all", true)), "reset must restore mute all")

	var after := profile_service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(after) == PlayerProfileScript.get_total_chips(before), "settings reset must not change chips")
	_require(PlayerProfileScript.get_total_gems(after) == PlayerProfileScript.get_total_gems(before), "settings reset must not change gems")
	_require(String(after.get("selected_avatar_id", "")) == String(before.get("selected_avatar_id", "")), "settings reset must not change avatar")

	SettingsServiceScript.reset_for_tests(path)
	print("Settings reset defaults test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
