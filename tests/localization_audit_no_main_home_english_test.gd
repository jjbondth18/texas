extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var topbar_source := FileAccess.get_file_as_string("res://scripts/components/top_bar.gd")
	var zh := _locale("zh-CN")
	for key in [
		"mode.quick_play.title",
		"mode.room_browser.title",
		"mode.private_table.title",
		"mode.training.title",
		"mode.events.title",
		"home.cta_play",
		"topbar.chips",
		"topbar.gems",
		"topbar.help",
		"topbar.exit",
	]:
		_require(not _is_english_fallback(str(zh.get(key, ""))), "%s should not be English fallback in zh-CN." % key)
	_require(home_source.find("_t(\"home.cta_play\")") != -1, "Home CTA should use localization.")
	_require(topbar_source.find("topbar.chips") != -1, "Top bar chips should use localization.")
	_require(topbar_source.find("topbar.level_xp") != -1, "Top bar level text should use localization.")
	print("Localization audit no main Home English test passed.")
	quit(0)

func _locale(locale: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % locale))
	_require(parsed is Dictionary, "%s locale should parse." % locale)
	return Dictionary(parsed)

func _is_english_fallback(value: String) -> bool:
	return value.find("QUICK PLAY") != -1 or value.find("ROOM BROWSER") != -1 or value.find("FRIENDS ROOM") != -1 or value.find("TRAINING") != -1 or value.find("EVENTS") != -1 or value.find("CHIPS") != -1 or value.find("GEMS") != -1 or value.find("HELP") != -1 or value.find("EXIT") != -1

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
