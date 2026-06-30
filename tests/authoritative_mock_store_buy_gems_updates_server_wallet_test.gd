extends RefCounted

func run() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("var label := \"Gems\" if currency == \"gems\" else \"Chips\"") != -1)
	assert(home_source.find("_player_profile = ProfileServiceScript.new().apply_wallet_snapshot(wallet)") != -1)
	assert(home_source.find("_refresh_profile_views_from_server()") != -1)
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("this.wallets.addGems(client.id, normalized, { reason: \"store_mock_purchase\" })") != -1)
