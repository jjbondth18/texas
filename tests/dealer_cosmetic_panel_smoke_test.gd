extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.contains("DealerImageCardGrid"), "dealer panel must build an image card grid")
	_require(source.contains("DealerImageCardScroll"), "dealer panel must support scrolling image cards")
	_require(source.contains("CurrentDealerPreview"), "dealer panel must show a current dealer image preview")
	_require(source.contains("_dealer_image_card_button"), "dealer panel must use image card buttons")
	_require(source.contains("TextureRect.new()"), "dealer panel must create texture previews")
	_require(source.contains("DealerLibraryScript.list_dealers()"), "dealer panel must use dealer library resources")
	_require(not source.contains("TableSessionScript.AVAILABLE_DEALER_IDS"), "dealer panel must not use the old text-only dealer id list")
	_require(source.contains("can_change_dealer_cosmetic"), "dealer panel must keep solo/AI permission guard")
	print("Dealer cosmetic panel smoke test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
