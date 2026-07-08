extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var nav_source := FileAccess.get_file_as_string("res://scripts/components/left_nav_rail.gd")
	_require(source.find("mode.%s.title") != -1, "Mode card titles should use localization keys.")
	_require(nav_source.find("nav.%s") != -1, "Main nav items should use dynamic localization keys.")
	_require(nav_source.find("mode.%s.title") != -1, "Play submenu should use localized mode titles.")
	print("Localization no hardcoded main nav test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
