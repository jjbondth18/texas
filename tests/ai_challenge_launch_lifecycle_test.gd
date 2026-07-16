extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")

	assert(table_source.find("func _is_ai_challenge_table() -> bool:") != -1)
	assert(table_source.find("AI Challenge room activation requested. Waiting for authoritative snapshot.") != -1)
	assert(table_source.find("if _is_ai_challenge_table():\n\t\t_server_setup_done = true") != -1)
	assert(table_source.find("_poker_ws_client.sit_down(_server_requested_seat_index") != -1, "Ordinary tables must retain authoritative sit_down.")
	assert(home_source.find("\"ai_challenge_tier\": ai_challenge_tier") != -1)
	assert(home_source.find("\"already_seated\": already_seated") != -1)
	assert(ws_source.find("challenge_table[\"entry_fee_charged\"]") != -1)
	assert(server_source.find("this.sitDownAiChallenge(room, client, 5);") != -1)
	assert(server_source.find("player_seat_index: existingSeat?.seatIndex ?? 5") != -1)
	assert(server_source.find("entry_fee_charged: room.entryFeeCharged") != -1)

	print("AI_CHALLENGE_LAUNCH_LIFECYCLE_TEST_OK")
	quit()
