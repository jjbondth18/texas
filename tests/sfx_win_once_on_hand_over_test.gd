extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("SfxManagerScript.play_win(self, \"%s:win\" % _sfx_current_hand_key())") != -1, "Local hand result should play win SFX once per hand.")
	_require(source.find("SfxManagerScript.play_win(self, \"server:%s:win\" % _sfx_current_hand_key())") != -1, "Server winner event should play win SFX once per hand.")
	print("SFX win once on hand over test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
