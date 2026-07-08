extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/daily_bonus_bar.gd")
	_require(source.find("daily.title") != -1, "Daily Bonus title should use localization.")
	_require(source.find("daily.claimed_today") != -1, "Daily Bonus claimed-today state should use localization.")
	_require(source.find("daily.chips") != -1, "Daily Bonus reward text should use localization.")
	print("Daily Bonus UI uses localization keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
