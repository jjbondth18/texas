extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("Confirm Purchase") != -1, "avatar purchase should open a confirm dialog.")
	_require(source.find("Buy %s for %s Chips?") != -1, "confirm dialog should include avatar name and chip price.")
	_require(source.find("CONFIRM") != -1 and source.find("CANCEL") != -1, "confirm dialog should label confirm and cancel buttons.")
	print("Avatar purchase confirm dialog test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
