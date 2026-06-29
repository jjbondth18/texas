extends SceneTree

const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")

func _init() -> void:
	var path := "user://test_settings_save_load.cfg"
	SettingsServiceScript.reset_for_tests(path)
	var service := SettingsServiceScript.new()
	service.save_settings({
		"master_volume": 0.42,
		"animation_speed": "fast",
		"reduce_motion": true,
	})

	SettingsServiceScript.reset_for_tests(path, false)
	var loaded := SettingsServiceScript.new().load_settings()
	_require(absf(float(loaded.get("master_volume", 0.0)) - 0.42) < 0.001, "saved master volume must load")
	_require(String(loaded.get("animation_speed", "")) == "fast", "saved animation speed must load")
	_require(bool(loaded.get("reduce_motion", false)), "saved reduce motion must load")
	_require(float(loaded.get("music_volume", 0.0)) == 0.8, "unspecified settings must keep defaults")

	SettingsServiceScript.reset_for_tests(path)
	print("Settings save load test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
