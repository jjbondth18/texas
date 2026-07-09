extends SceneTree

func _init() -> void:
	var zh := _locale("zh-CN")
	for key in [
		"store.subtitle",
		"store.dev_badge",
		"store.chips_desc",
		"store.gems_desc",
		"store.mock_purchase_title",
		"store.mock_buy",
		"store.mock_purchase_confirm_text",
	]:
		var value := str(zh.get(key, ""))
		_require(value != "", "%s should exist." % key)
		_require(value.find("Mock") == -1, "%s should not show Mock English in zh-CN." % key)
		_require(value.find("DEV ONLY") == -1, "%s should not show DEV ONLY English in zh-CN." % key)
	print("Localization Store zh-CN no main English test passed.")
	quit(0)

func _locale(locale: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % locale))
	_require(parsed is Dictionary, "%s locale should parse." % locale)
	return Dictionary(parsed)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
