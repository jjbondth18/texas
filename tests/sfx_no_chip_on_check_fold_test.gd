extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(table_source.find("\"check\"") != -1, "Poker actions can still include check.")
	_require(table_source.find("\"fold\"") != -1, "Poker actions can still include fold.")
	_require(table_source.find("return action_id in [\"small_blind\", \"big_blind\", \"call\", \"bet\", \"raise\", \"all_in\"]") != -1, "Chip SFX should not include check/fold.")
	print("SFX no chip on check fold test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
