extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var zh := _locale("zh-CN")
	_require(source.find("func _avatar_display_name") != -1, "Avatar display names should go through a localization helper.")
	_require(source.find("avatar.%s.name") != -1, "Avatar display helper should build avatar name keys.")
	_require(source.find("achievement.first_blood.name") != -1, "Achievement metadata should use localization keys.")
	_require(source.find("achievement.line") != -1, "Achievement line should be formatted from localization.")
	for key in [
		"avatar.4_05.name",
		"avatar.1_01.name",
		"achievement.first_blood.name",
		"achievement.first_blood.desc",
		"achievement.status.locked",
		"profile.title.table_regular",
	]:
		_require(zh.has(key), "zh-CN should contain metadata key %s." % key)
	print("Localization avatar achievement metadata test passed.")
	quit(0)

func _locale(locale: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % locale))
	_require(parsed is Dictionary, "%s locale should parse." % locale)
	return Dictionary(parsed)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
