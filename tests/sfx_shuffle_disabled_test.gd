extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	var docs := FileAccess.get_file_as_string("res://docs/audio_sfx_rules.md")
	_require(source.find("const SHUFFLE_SFX_ENABLED := false") != -1, "Shuffle SFX should be disabled.")
	_require(source.find("static func play_shuffle(_owner: Node, _event_id: String = \"\") -> bool:") != -1, "play_shuffle should remain callable.")
	_require(source.find("if not SHUFFLE_SFX_ENABLED:") != -1, "play_shuffle should check the disabled flag.")
	_require(source.find("return false") != -1, "play_shuffle should no-op before loading shuffle.wav.")
	_require(docs.find("Shuffle SFX: disabled.") != -1, "SFX rules should document that shuffle is disabled.")
	print("SFX shuffle disabled test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
