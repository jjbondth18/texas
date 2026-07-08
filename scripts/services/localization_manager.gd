extends RefCounted
class_name LocalizationManager

const DEFAULT_LOCALE := "en-US"
const SUPPORTED_LOCALES: Array[String] = [
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
const LOCALE_NAMES := {
	"en-US": "English",
	"zh-CN": "简体中文",
	"zh-TW": "繁體中文",
	"ja-JP": "日本語",
	"ko-KR": "한국어",
	"es-ES": "Español",
	"pt-BR": "Português (Brasil)",
	"fr-FR": "Français",
	"de-DE": "Deutsch",
	"it-IT": "Italiano",
	"ru-RU": "Русский",
	"tr-TR": "Türkçe",
}

static var current_locale: String = DEFAULT_LOCALE
static var available_locales: Array[String] = SUPPORTED_LOCALES.duplicate()
static var _fallback_strings: Dictionary = {}
static var _locale_strings: Dictionary = {}

static func load_saved_locale(settings: Dictionary) -> void:
	set_locale(str(settings.get("language_locale", DEFAULT_LOCALE)))

static func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		current_locale = DEFAULT_LOCALE
	else:
		current_locale = locale
	_ensure_loaded(DEFAULT_LOCALE)
	_ensure_loaded(current_locale)

static func locale_display_name(locale: String) -> String:
	return str(LOCALE_NAMES.get(locale, locale))

static func language_options() -> Array:
	var options: Array = []
	for locale in SUPPORTED_LOCALES:
		options.append({
			"label": "%s · %s" % [locale_display_name(locale), locale],
			"value": locale,
		})
	return options

static func tr_key(key: String) -> String:
	_ensure_loaded(DEFAULT_LOCALE)
	_ensure_loaded(current_locale)
	var active := Dictionary(_locale_strings.get(current_locale, {}))
	if active.has(key):
		return str(active[key])
	var fallback := Dictionary(_locale_strings.get(DEFAULT_LOCALE, {}))
	return str(fallback.get(key, key))

static func trf(key: String, params: Dictionary) -> String:
	var text := tr_key(key)
	for param_key in params.keys():
		text = text.replace("{%s}" % str(param_key), str(params[param_key]))
	return text

static func has_locale(locale: String) -> bool:
	return SUPPORTED_LOCALES.has(locale)

static func all_keys_for(locale: String) -> Array:
	_ensure_loaded(locale)
	return Dictionary(_locale_strings.get(locale, {})).keys()

static func reset_for_tests() -> void:
	current_locale = DEFAULT_LOCALE
	_locale_strings.clear()

static func _ensure_loaded(locale: String) -> void:
	if _locale_strings.has(locale):
		return
	var path := "res://localization/%s.json" % locale
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_locale_strings[locale] = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_locale_strings[locale] = Dictionary(parsed)
	else:
		_locale_strings[locale] = {}
