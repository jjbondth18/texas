extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/settings_service.gd")
	_require(source.find("\"sfx_volume\": 0.8") != -1, "Settings should keep an SFX volume setting.")
	_require(source.find("_apply_bus_volume(\"SFX\"") != -1, "Settings should apply volume to the SFX bus.")
	print("Settings SFX volume controls SFX test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
