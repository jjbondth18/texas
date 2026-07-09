extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("play_shuffle(self, \"%s:shuffle\" % _sfx_current_hand_key())") != -1, "Local hands should play shuffle with a hand-scoped key.")
	_require(source.find("play_shuffle(self, \"server:%d:shuffle\" % hand_id)") != -1, "Authoritative hands should play shuffle with a server hand key.")
	var manager_source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	_require(manager_source.find("_played_event_ids.has(unique_key)") != -1, "SFX manager should suppress repeated shuffle hand keys.")
	print("SFX shuffle once per hand test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
