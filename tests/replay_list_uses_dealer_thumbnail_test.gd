extends SceneTree

func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("const DealerLibraryScript") != -1, "Replay list should use DealerLibrary")
	_require(source.find("_make_replay_dealer_thumbnail(hand, preview_record)") != -1, "Replay list should render dealer thumbnail")
	_require(source.find("ReplayDealerThumbnail") != -1, "dealer thumbnail node should be named")
	_require(source.find("TextureRect.new()") != -1, "dealer thumbnail should use a texture")
	print("Replay list dealer thumbnail test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
