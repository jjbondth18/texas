extends SceneTree

func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var client_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	assert(table_source.find("DEV: SIMULATE REAL PLAYER JOIN") != -1)
	assert(table_source.find("func _should_show_dev_simulate_real_join()") != -1)
	assert(table_source.find("OS.is_debug_build()") != -1)
	assert(table_source.find("_local_public_warmup_active") != -1)
	assert(table_source.find("_server_local_seat_index != 0") != -1)
	assert(table_source.find("_real_public_player_count_from_flow() == 1") != -1)
	assert(table_source.find("_poker_ws_client.dev_simulate_real_join(_server_room_id, \"DevPlayer2\")") != -1)
	assert(table_source.find("_return_from_local_warmup_to_public(next_snapshot)") != -1)

	assert(protocol_source.find("const DEV_SIMULATE_REAL_JOIN := \"dev_simulate_real_join\"") != -1)
	assert(protocol_source.find("static func dev_simulate_real_join(room_id: String, player_name: String = \"DevPlayer2\")") != -1)
	assert(client_source.find("func dev_simulate_real_join(target_room_id: String = room_id, player_name: String = \"DevPlayer2\")") != -1)

	assert(server_source.find("case \"dev_simulate_real_join\"") != -1)
	assert(server_source.find("config.nodeEnv === \"production\" || !config.allowMockPurchases") != -1)
	assert(server_source.find("room.hostInLocalWarmup !== hostClient.id") != -1)
	assert(server_source.find("room.table.sitDown(toPlayer(simulatedClient), seat.seatIndex, room.buyIn)") != -1)
	assert(server_source.find("room.hostInLocalWarmup = \"\"") != -1)
	assert(server_source.find("simulated=true") != -1)
	assert(server_source.find("warmupAi") == -1 or server_source.find("warmupAi: true") == -1)

	assert(db_smoke_source.find("{ type: \"dev_simulate_real_join\", room_id: warmupRoom.id, player_name: \"DevPlayer2\" }") != -1)
	assert(db_smoke_source.find("dev simulated real join should interrupt host local warm-up") != -1)
	assert(db_smoke_source.find("dev simulated real join should return public room to two real players") != -1)
	assert(db_smoke_source.find("dev simulated real join should seat DevPlayer2") != -1)
	quit()
