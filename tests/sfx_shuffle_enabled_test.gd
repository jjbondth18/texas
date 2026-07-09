extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	var docs := FileAccess.get_file_as_string("res://docs/audio_sfx_rules.md")
	_require(source.find("const SHUFFLE_SFX_ENABLED := true") != -1, "Shuffle SFX should be enabled for the new trial.")
	_require(source.find("static func play_shuffle(owner: Node, event_id: String = \"\") -> bool:") != -1, "play_shuffle should remain callable.")
	_require(source.find("return play_sfx(owner, \"shuffle\", event_id)") != -1, "play_shuffle should route to SFX playback while enabled.")
	_require(source.find("sfx_id == \"shuffle\" and _is_shuffle_playing()") != -1, "Shuffle should still ignore overlap while playing.")
	_require(docs.find("Shuffle SFX is enabled again") != -1, "SFX rules should document the shuffle trial.")
	print("SFX shuffle enabled test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
