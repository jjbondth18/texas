extends SceneTree

func _init() -> void:
	var manager_source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	var import_source := FileAccess.get_file_as_string("res://assets/music/shuffle.wav.import")
	_require(manager_source.find("wav.loop_mode = AudioStreamWAV.LOOP_DISABLED") != -1, "SFX manager should disable WAV looping.")
	_require(import_source.find("edit/loop_mode=0") != -1, "shuffle.wav import should not loop.")
	_require(import_source.find("compress/mode=0") != -1, "shuffle.wav import should not use compressed import mode.")
	print("SFX shuffle no loop test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
