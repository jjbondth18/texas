extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	_require(source.find("const SHUFFLE_SFX_ENABLED := true") != -1, "Shuffle SFX should be enabled with a conservative volume.")
	_require(source.find("\"shuffle\": -12.0") != -1, "Shuffle SFX should be reduced to -12 dB.")
	_require(source.find("func volume_db_for(sfx_id: String) -> float") != -1, "SFX manager should expose volume checks for tests.")
	print("SFX shuffle volume db test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
