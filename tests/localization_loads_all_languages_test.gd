extends SceneTree

const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

func _init() -> void:
	for locale in LocalizationManagerScript.SUPPORTED_LOCALES:
		var path := "res://localization/%s.json" % locale
		_require(FileAccess.file_exists(path), "missing language pack: %s" % path)
		LocalizationManagerScript.set_locale(locale)
		_require(LocalizationManagerScript.tr_key("nav.play") != "nav.play", "nav.play should resolve for %s" % locale)
	_require(LocalizationManagerScript.SUPPORTED_LOCALES.size() == 12, "first pass must expose twelve locales.")
	print("Localization loads all languages test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
