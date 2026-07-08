extends SceneTree

const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

func _init() -> void:
	var avatar_text := LocalizationManagerScript.trf("avatar.confirm_text", {"name": "Lucky Fox", "price": "7,500"})
	_require(avatar_text.find("Lucky Fox") != -1, "Avatar purchase text should inject avatar name.")
	_require(avatar_text.find("7,500") != -1, "Avatar purchase text should inject price.")
	var room_text := LocalizationManagerScript.trf("friends.room_code_value", {"code": "A7K9"})
	_require(room_text.find("A7K9") != -1, "Room code text should inject code.")
	var step_text := LocalizationManagerScript.trf("replay.speed", {"speed": 2})
	_require(step_text.find("2") != -1, "Replay speed text should inject speed.")
	print("Localization dynamic format test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
