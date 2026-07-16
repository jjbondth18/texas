extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("ConfirmationModalScript.new()") != -1, "Exit Table must use the shared custom confirmation modal.")
	_require(source.find("ConfirmationDialog.new()") == -1, "Exit Table must not use the native confirmation dialog.")
	_require(source.find("LEAVE TABLE?") != -1, "Leave-table modal title must be present.")
	_require(source.find("Your full remaining table stack will be returned to your wallet.") != -1, "Pre-hand exit copy must explain full settlement.")
	_require(source.find("Practice results do not affect your wallet.") != -1, "Warm-up exit copy must explain practice-only wallet behavior.")
	_require(source.find("Chips already committed to the pot will remain in the pot.") != -1, "In-hand exit copy must explain committed chips.")
	_require(source.find("Committed This Hand:") != -1, "In-hand exit copy must show the authoritative committed amount.")
	_require(source.find("_request_exit_table") != -1 and source.find("_confirm_exit_table") != -1, "Exit flow must separate request and confirmation.")
	print("Public exit confirm dialog test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
