extends SceneTree

const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")

func _init() -> void:
	SettingsServiceScript.reset_for_tests("user://settings_language_saved_test.cfg")
	var service := SettingsServiceScript.new()
	var saved := service.save_settings({"language_locale": "ja-JP"})
	_require(str(saved.get("language_locale", "")) == "ja-JP", "language locale should be saved.")
	var loaded := service.load_settings()
	_require(str(loaded.get("language_locale", "")) == "ja-JP", "language locale should load from settings.")
	var normalized := SettingsServiceScript.normalize_settings({"language_locale": "bad-locale"})
	_require(str(normalized.get("language_locale", "")) == "en-US", "bad locale should normalize to en-US.")
	print("Settings language saved test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
