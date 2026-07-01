extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("ConfirmationDialog.new()") != -1, "Exit Table must use a confirmation dialog.")
	_require(source.find("Exit Table?") != -1, "Exit dialog title must be present.")
	_require(source.find("You have not started an official hand. Your table chips will be returned to your wallet.") != -1, "Pre-hand exit copy must explain full refund.")
	_require(source.find("This is practice only. Your wallet will not be affected. Leaving will also leave the public room.") != -1, "Warm-up exit copy must explain practice-only wallet behavior.")
	_require(source.find("Chips already committed to the pot stay in the pot") != -1, "In-hand exit copy must explain committed chips.")
	_require(source.find("_request_exit_table") != -1 and source.find("_confirm_exit_table") != -1, "Exit flow must separate request and confirmation.")
	print("Public exit confirm dialog test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
