extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("ProfileEditNameButton") != -1, "profile should render a stable edit-name button")
	_require(source.find("EDIT NAME - %d DAYS") != -1, "rename cooldown should disable the button with a remaining-days label")
	_require(source.find("Next rename available: %s") != -1, "rename cooldown should show next available date")
	_require(source.find("rename_display_name") != -1, "rename should remain server authoritative")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
