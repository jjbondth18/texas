extends RefCounted

func run() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("MOCK PURCHASE / DEV ONLY") != -1)
	var config_source := FileAccess.get_file_as_string("res://server/src/config.ts")
	assert(config_source.find("allowMockPurchases") != -1)
	assert(config_source.find("ALLOW_MOCK_PURCHASES") != -1)
	var room_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(room_source.find("mock_purchase_disabled") != -1)
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(db_smoke_source.find("disabled mock purchase should not change wallet") != -1)
