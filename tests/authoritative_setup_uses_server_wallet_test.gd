extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("func _wallet_chips_for_public_chip_setup") != -1)
	assert(source.find("var _profile_server_wallet_synced := false") != -1)
	assert(source.find("not _profile_server_wallet_synced") != -1)
	assert(source.find("Server Wallet Chips") != -1)
	assert(source.find("not _can_afford_public_buy_in") != -1)
	assert(source.find("Not enough server wallet chips") != -1)
	assert(source.find("_quick_start_button.disabled = not is_chip_mode or _selected_quick_buy_in > total_chips") != -1)
