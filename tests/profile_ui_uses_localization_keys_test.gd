extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("_t(\"profile.title\")") != -1, "Profile panel title should use localization.")
	_require(source.find("_t(\"avatar.confirm_title\")") != -1, "Avatar purchase confirm title should use localization.")
	_require(source.find("_tf(\"avatar.confirm_text\"") != -1, "Avatar purchase confirm body should use localization.")
	print("Profile UI uses localization keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
