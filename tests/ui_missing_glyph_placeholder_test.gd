extends SceneTree

func _init() -> void:
	for locale in ["en-US", "zh-CN", "zh-TW", "ja-JP", "ko-KR", "es-ES", "pt-BR", "fr-FR", "de-DE", "it-IT", "ru-RU", "tr-TR"]:
		var path := "res://localization/%s.json" % locale
		var text := FileAccess.get_file_as_string(path)
		_require(text.find("?  CLICK PLAY") == -1, "%s should not use question-mark CTA icon placeholders" % locale)
		_require(text.find("?? {name}") == -1, "%s should not use question-mark achievement icon placeholders" % locale)
		_require(text.find("🏆") == -1, "%s should not use unsupported achievement emoji" % locale)
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
