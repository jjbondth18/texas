extends SceneTree

const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

func _init() -> void:
	LocalizationManagerScript.reset_for_tests()
	LocalizationManagerScript.set_locale("zh-CN")
	_require(LocalizationManagerScript.tr_key("settings.language_note") == "Applies immediately to Home and Settings. Some table text updates after reopening the screen.", "missing zh-CN key should fall back to en-US.")
	_require(LocalizationManagerScript.tr_key("missing.dev.key") == "missing.dev.key", "missing fallback key should return raw key.")
	print("Localization missing key fallback test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
