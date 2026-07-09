extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("SfxManagerScript.play_gem(self, \"replay_unlock:%s\" % replay_id)") != -1, "Replay unlock should play gem SFX after success.")
	print("SFX gem on replay unlock test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
