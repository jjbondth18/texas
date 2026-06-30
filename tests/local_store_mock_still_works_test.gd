extends RefCounted

func run() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:") != -1)
	assert(home_source.find("var store := StoreMockServiceScript.new()") != -1)
	assert(home_source.find("store.mock_purchase_gems(amount)") != -1)
	assert(home_source.find("store.mock_purchase_chips(amount)") != -1)
	var store_source := FileAccess.get_file_as_string("res://scripts/services/store_mock_service.gd")
	assert(store_source.find("func mock_purchase_chips(amount: int)") != -1)
	assert(store_source.find("func mock_purchase_gems(amount: int)") != -1)
