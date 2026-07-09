extends SceneTree

const LOCALES := [
	"en-US",
	"zh-CN",
	"zh-TW",
	"ja-JP",
	"ko-KR",
	"es-ES",
	"pt-BR",
	"fr-FR",
	"de-DE",
	"it-IT",
	"ru-RU",
	"tr-TR",
]

func _init() -> void:
	var en_keys := _keys_for("en-US")
	for locale in LOCALES:
		var keys := _keys_for(locale)
		_require(keys.size() == en_keys.size(), "%s should have the same key count as en-US." % locale)
		for key in en_keys:
			_require(keys.has(key), "%s is missing localization key %s." % [locale, key])
	print("Localization key parity test passed.")
	quit(0)

func _keys_for(locale: String) -> Dictionary:
	var path := "res://localization/%s.json" % locale
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	_require(parsed is Dictionary, "%s must parse as a Dictionary." % path)
	var result := {}
	for key in Dictionary(parsed).keys():
		result[str(key)] = true
	return result

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
