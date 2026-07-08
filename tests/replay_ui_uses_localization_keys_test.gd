extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("_t(\"replay.room_title\")") != -1, "Replay Room title should use localization.")
	_require(source.find("_t(\"replay.play_replay\")") != -1, "Replay play button should use localization.")
	_require(source.find("_tf(\"replay.hand_review\"") != -1, "Replay detail title should use localization format.")
	print("Replay UI uses localization keys test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
