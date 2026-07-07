extends SceneTree

func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.find("DealerLibraryScript.normalize_dealer_id(dealer_id)") != -1, "missing dealer ids should normalize to default")
	_require(source.find("DealerLibraryScript.get_default_dealer_id()") != -1, "missing dealer textures should fall back to default")
	_require(source.find("ReplayDealerThumbnailPlaceholder") != -1, "thumbnail should have a final placeholder fallback")
	print("Replay list missing dealer fallback test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
