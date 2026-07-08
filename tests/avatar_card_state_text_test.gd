extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("SELECTED") != -1, "avatar card should show SELECTED for selected avatar.")
	_require(source.find("SELECT") != -1, "avatar card should show SELECT for owned avatars.")
	_require(source.find("Buy %s") != -1, "avatar card should show Buy price for affordable locked avatars.")
	_require(source.find("Need %s") != -1, "avatar card should show Need price for unaffordable locked avatars.")
	_require(source.find("Buy Locked") == -1, "avatar card should not show Buy Locked.")
	print("Avatar card state text test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
