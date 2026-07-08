extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("_t(\"replay.hand_records\")") != -1, "Replay records title should use localization.")
	_require(source.find("_tf(\"replay.unlock_button\"") != -1, "Replay unlock button should use localization format.")
	_require(source.find("_t(\"replay.back_to_detail\")") != -1 or source.find("back_to_detail_requested") != -1, "Replay detail navigation should remain routed through replay UI.")
	_require(source.find("_t(\"replay.players\")") != -1, "Replay players section should use localization.")
	_require(source.find("_t(\"replay.action_timeline\")") != -1, "Replay action timeline section should use localization.")
	print("Localization replay UI keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
