extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("item.custom_minimum_size = Vector2(0, 112)") != -1, "Replay list row should be tall enough for the larger dealer thumbnail.")
	_require(source.find("custom_minimum_size = Vector2(56, 68)") != -1, "Replay dealer thumbnail should use the larger 56x68 size.")
	_require(source.find("_make_replay_dealer_thumbnail(hand, preview_record)") != -1, "Replay list must still render dealer thumbnails.")
	print("Replay list dealer thumbnail size test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
