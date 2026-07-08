extends SceneTree

const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

func _init() -> void:
	LocalizationManagerScript.reset_for_tests()
	LocalizationManagerScript.set_locale("en-US")
	_require(LocalizationManagerScript.tr_key("nav.settings") == "SETTINGS", "English settings label should resolve.")
	LocalizationManagerScript.set_locale("zh-CN")
	_require(LocalizationManagerScript.tr_key("nav.settings") == "设置", "Chinese settings label should resolve after switch.")
	LocalizationManagerScript.set_locale("not-real")
	_require(LocalizationManagerScript.current_locale == LocalizationManagerScript.DEFAULT_LOCALE, "unsupported locale should fall back to en-US.")
	print("Localization switch language test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
