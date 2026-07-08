extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("dialog.canceled.connect(dialog.queue_free)") != -1, "cancel should only close the dialog.")
	print("Avatar purchase cancel no charge test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
