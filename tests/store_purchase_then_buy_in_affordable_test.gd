extends RefCounted

func run() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("func _wallet_chips_for_public_chip_setup") != -1)
	assert(home_source.find("ProfileServiceScript.new().apply_wallet_snapshot(wallet)") != -1)
	assert(home_source.find("return _wallet_chips_for_public_chip_setup() >= buy_in") != -1)
	assert(home_source.find("_quick_start_button.disabled = not is_chip_mode or _selected_quick_buy_in > total_chips") != -1)
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(db_smoke_source.find("mock chip purchase should make selected buy-in affordable") != -1)
