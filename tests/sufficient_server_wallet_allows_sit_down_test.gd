extends RefCounted

func run() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("func _can_afford_public_buy_in") != -1)
	assert(home_source.find("return _wallet_chips_for_public_chip_setup() >= buy_in") != -1)
	assert(home_source.find("_profile_ws_client.create_table") != -1)
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("sit_down accepted: room_id=%s seat=%d canonical_room_player_id=%s") != -1)
	assert(table_source.find("_try_server_ready_after_seated()") != -1)
