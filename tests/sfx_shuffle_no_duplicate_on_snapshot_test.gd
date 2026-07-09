extends SceneTree

func _init() -> void:
	var manager_source := FileAccess.get_file_as_string("res://scripts/services/sfx_manager.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(manager_source.find("sfx_id == \"shuffle\" and _is_shuffle_playing()") != -1, "Shuffle should not stack while another shuffle is playing.")
	_require(table_source.find("\"%s:shuffle\" % _sfx_current_hand_key()") != -1, "Local shuffle should be hand scoped, not snapshot scoped.")
	_require(table_source.find("\"server:%d:shuffle\" % hand_id") != -1, "Server shuffle should be hand id scoped, not snapshot scoped.")
	print("SFX shuffle no duplicate on snapshot test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
