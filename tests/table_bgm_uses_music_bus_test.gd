extends SceneTree

func _init() -> void:
	var music_source := FileAccess.get_file_as_string("res://scripts/services/music_service.gd")
	var settings_source := FileAccess.get_file_as_string("res://scripts/services/settings_service.gd")
	_require(music_source.find("const MUSIC_BUS := \"Music\"") != -1, "BGM should use the Music bus.")
	_require(music_source.find("_player.bus = MUSIC_BUS") != -1, "BGM player should be assigned to Music bus.")
	_require(settings_source.find("_apply_bus_volume(\"Music\"") != -1, "SettingsService should control the Music bus.")
	print("Table BGM uses music bus test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
