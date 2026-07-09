extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	_require(source.find("const SHUFFLE_SFX_ENABLED := false") != -1, "Shuffle SFX should stay disabled.")
	_require(source.find("player.pitch_scale = 1.0") != -1, "Shuffle and all SFX players should reset pitch_scale to 1.0 before play.")
	_require(source.find("stream_paused = false") != -1, "SFX players should not be paused when playing shuffle.")
	_require(source.find("playback_speed") == -1, "SFX manager should not use playback_speed for shuffle.")
	print("SFX shuffle pitch normal test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
