extends SceneTree

func _init() -> void:
	var zh := _locale("zh-CN")
	for key in [
		"profile.subtitle",
		"profile.overview_stats",
		"profile.character_avatars",
		"profile.achievements",
		"profile.total_chips",
		"profile.win_rate",
		"avatar.buy_chips",
		"avatar.need_chips",
		"achievement.first_blood.name",
		"achievement.first_blood.desc",
		"achievement.status.unlocked",
	]:
		var value := str(zh.get(key, ""))
		_require(value != "", "%s should exist." % key)
		_require(not _contains_profile_english(value), "%s should not be English fallback in zh-CN." % key)
	print("Localization Profile zh-CN no main English test passed.")
	quit(0)

func _locale(locale: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % locale))
	_require(parsed is Dictionary, "%s locale should parse." % locale)
	return Dictionary(parsed)

func _contains_profile_english(value: String) -> bool:
	for token in ["STATISTICS", "OVERVIEW", "CHARACTER AVATARS", "ACHIEVEMENTS", "Total Chips", "Win Rate", "Buy", "Need", "First Blood", "Unlocked"]:
		if value.find(token) != -1:
			return true
	return false

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
