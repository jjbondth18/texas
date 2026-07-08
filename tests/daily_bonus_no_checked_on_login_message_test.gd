extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(home_source.find("Server rewards are checked on login") == -1, "checked-on-login copy should not be visible.")
	_require(home_source.find("Could not claim daily bonus") != -1, "claim failures should use clear claim copy.")
	print("Daily bonus no checked on login message test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
