extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(source.find("_server_latest_ui_snapshot") != -1 and source.find("contribution") != -1, "Exit values must come from the authoritative seat snapshot.")
	_require(source.find("_poker_ws_client.cash_out()") != -1, "Official table exit must request authoritative cash out.")
	_require(source.find("SETTLING...") != -1, "Settlement pending state must be visible.")
	_require(source.find("Settlement timed out. Please try again.") != -1, "Settlement timeout must allow a retry.")
	_require(source.find("_server_leave_return_pending") != -1 and source.find("_server_cash_out_pending_return") != -1, "Exit settlement must guard duplicate requests.")
	_require(source.find("MODE_TRAINING") != -1 and source.find("LEAVE TRAINING?") != -1, "Training exit must use practice-safe copy.")
	_require(source.find("is_ai_warmup") != -1 and source.find("LEAVE PRACTICE?") != -1, "AI warm-up exit must use practice-safe copy.")
	print("Table exit settlement modal test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
