extends SceneTree

const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")

func _init() -> void:
	var path := "user://test_settings_audio_apply.cfg"
	SettingsServiceScript.reset_for_tests(path)
	var service := SettingsServiceScript.new()
	var master_bus := AudioServer.get_bus_index("Master")
	_require(master_bus >= 0, "Master bus must be available")

	var saved := service.save_settings({
		"master_volume": 0.5,
		"music_volume": 0.25,
		"sfx_volume": 0.75,
		"mute_all": false,
	})
	_require(absf(float(saved.get("master_volume", 0.0)) - 0.5) < 0.001, "master volume must be saved")
	_require(absf(AudioServer.get_bus_volume_db(master_bus) - linear_to_db(0.5)) < 0.05, "Master bus must receive saved volume")

	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	_require(music_bus >= 0, "Music bus must exist or be created")
	_require(sfx_bus >= 0, "SFX bus must exist or be created")
	_require(absf(AudioServer.get_bus_volume_db(music_bus) - linear_to_db(0.25)) < 0.05, "Music bus must receive saved volume")
	_require(absf(AudioServer.get_bus_volume_db(sfx_bus) - linear_to_db(0.75)) < 0.05, "SFX bus must receive saved volume")

	service.save_settings({
		"master_volume": 1.0,
		"mute_all": true,
	})
	_require(AudioServer.get_bus_volume_db(master_bus) <= -79.0, "mute all must silence Master bus")

	SettingsServiceScript.reset_for_tests(path)
	print("Settings audio apply test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
