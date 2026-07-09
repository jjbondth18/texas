extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("mode.%s.title") != -1, "Mode card titles should be resolved from localization keys.")
	_require(source.find("mode.%s.subtitle") != -1, "Mode card subtitles should be resolved from localization keys.")
	for key in [
		"mode.quick_play.title",
		"mode.room_browser.title",
		"mode.private_table.title",
		"mode.training.title",
		"mode.events.title",
	]:
		_require(_locale("zh-CN").has(key), "zh-CN should contain %s." % key)
	print("Localization mode cards from keys test passed.")
	quit(0)

func _locale(locale: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % locale))
	_require(parsed is Dictionary, "%s locale should parse." % locale)
	return Dictionary(parsed)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
