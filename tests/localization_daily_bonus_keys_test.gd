extends SceneTree

const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

func _init() -> void:
	for key in [
		"daily.claim",
		"daily.claimed",
		"daily.claimed_today",
		"daily.locked",
		"daily.next",
		"daily.progress",
		"daily.today_claim",
	]:
		_require(LocalizationManagerScript.tr_key(key) != key, "%s should resolve." % key)
	print("Localization daily bonus keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
