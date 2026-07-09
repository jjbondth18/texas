extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	_require(source.find("const SFX_BUS := \"SFX\"") != -1, "SFX manager should target the SFX bus.")
	_require(source.find("player.bus = SFX_BUS") != -1, "SFX players should use the SFX bus.")
	print("SFX uses SFX bus test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
