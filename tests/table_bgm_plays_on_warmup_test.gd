extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(table_source.find("_local_public_warmup_active") != -1, "PokerTableScreen should host local warm-up state.")
	_require(table_source.find("MusicServiceScript.play_table_bgm(self)") != -1, "Local warm-up should inherit PokerTableScreen table BGM.")
	print("Table BGM plays on warmup test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
