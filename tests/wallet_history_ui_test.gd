extends SceneTree

func _init() -> void:
	var top_bar_source := FileAccess.get_file_as_string("res://scripts/components/top_bar.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")

	assert(top_bar_source.find("signal wallet_history_requested(currency: String)") != -1)
	assert(top_bar_source.find("_on_currency_pill_input") != -1)
	assert(protocol_source.find("GET_WALLET_HISTORY") != -1)
	assert(protocol_source.find("func get_wallet_history") != -1)
	assert(ws_source.find("signal wallet_history_received") != -1)
	assert(home_source.find("WALLET HISTORY") != -1)
	assert(home_source.find("[\"all\", \"chips\", \"gems\"]") != -1)
	assert(home_source.find("No wallet activity yet.") != -1)
	assert(home_source.find("Wallet history is temporarily unavailable.") != -1)
	assert(home_source.find("\"+\" if amount >= 0 else \"-\"") != -1)
	var wallet_modal_start := home_source.find("func _build_wallet_history_modal()")
	var wallet_modal_end := home_source.find("func _open_rename_display_name_dialog()", wallet_modal_start)
	assert(wallet_modal_start != -1 and wallet_modal_end > wallet_modal_start)
	var wallet_modal_source := home_source.substr(wallet_modal_start, wallet_modal_end - wallet_modal_start)
	assert(wallet_modal_source.find("ConfirmationDialog.new()") == -1, "Wallet history must use the custom modal, not a native dialog.")

	print("WALLET_HISTORY_UI_TEST_OK")
	quit()
