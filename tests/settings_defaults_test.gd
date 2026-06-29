extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")

func _init() -> void:
	SettingsServiceScript.reset_for_tests("user://test_settings_defaults.cfg")
	ProfileServiceScript.reset_mock_profile()
	var profile_service := ProfileServiceScript.new()
	var before := profile_service.get_current_profile()
	var settings := SettingsServiceScript.new().load_settings()

	_require(float(settings.get("master_volume", 0.0)) == 1.0, "default master volume must be 1.0")
	_require(float(settings.get("music_volume", 0.0)) == 0.8, "default music volume must be 0.8")
	_require(float(settings.get("sfx_volume", 0.0)) == 0.8, "default sfx volume must be 0.8")
	_require(not bool(settings.get("mute_all", true)), "default mute all must be off")
	_require(bool(settings.get("show_hand_hints", false)), "default hand hints must be on")
	_require(String(settings.get("animation_speed", "")) == "normal", "default animation speed must be normal")
	_require(String(settings.get("network_mode", "")) == "local_mock", "default network mode must be local mock")

	var after := profile_service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(after) == PlayerProfileScript.get_total_chips(before), "settings defaults must not change chips")
	_require(PlayerProfileScript.get_total_gems(after) == PlayerProfileScript.get_total_gems(before), "settings defaults must not change gems")
	_require(String(after.get("selected_avatar_id", "")) == String(before.get("selected_avatar_id", "")), "settings defaults must not change avatar")

	SettingsServiceScript.reset_for_tests("user://test_settings_defaults.cfg")
	print("Settings defaults test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
