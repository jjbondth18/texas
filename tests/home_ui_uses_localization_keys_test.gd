extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("_t(\"home.prompt\")") != -1, "Home prompt should use localization.")
	_require(source.find("_t(\"home.choose_room\")") != -1, "Play panel title should use localization.")
	_require(source.find("mode.%s.title") != -1, "Mode cards should use localization keys.")
	print("Home UI uses localization keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
