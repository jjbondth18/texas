extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("play_shuffle(self, \"%s:shuffle\" % _sfx_current_hand_key())") != -1, "Local hands should play shuffle with a hand-scoped key.")
	_require(source.find("play_shuffle(self, \"server:%d:shuffle\" % hand_id)") != -1, "Authoritative hands should play shuffle with a server hand key.")
	var manager_source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	_require(manager_source.find("const SHUFFLE_SFX_ENABLED := false") != -1, "Shuffle SFX should be disabled even if hand-scoped call sites remain.")
	_require(manager_source.find("if not SHUFFLE_SFX_ENABLED:") != -1, "play_shuffle should check the disabled flag.")
	_require(manager_source.find("return play_sfx(_owner, \"shuffle\", _event_id)") != -1, "play_shuffle should keep the old route available if re-enabled.")
	print("SFX shuffle once per hand test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
