extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("_t(\"profile.overview_stats\")") != -1, "Profile overview title should use localization.")
	_require(source.find("_t(\"profile.character_avatars\")") != -1, "Profile avatar gallery title should use localization.")
	_require(source.find("_tf(\"avatar.buy_chips\"") != -1, "Avatar buy state should use localization format.")
	_require(source.find("_t(\"store.dev_badge\")") != -1, "Store dev badge should use localization.")
	_require(source.find("_t(\"events.card_toast\")") != -1, "Events coming-soon toast should use localization.")
	print("Localization profile/store/events keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
