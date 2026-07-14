extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")

	var quick_start := home_source.find("func _start_quick_play_from_setup")
	var quick_end := home_source.find("func _quick_server_table_config")
	var quick_section := home_source.substr(quick_start, quick_end - quick_start)
	_require(quick_section.find("_profile_ws_client.quick_join_table(quick_config)") != -1, "Authoritative Quick must request quick_join_table from the server.")
	_require(quick_section.find("_open_server_table(") == -1, "Authoritative Quick must not open PokerTableScreen before the server matched room_id.")
	_require(home_source.find("func _on_server_table_joined(room_id: String, table_info: Dictionary)") != -1, "Home must open server tables from table_joined/quick_table_matched response.")
	_require(home_source.find("_open_server_table(room_id, table_info, -1)") != -1, "Server table open must use the authoritative response room_id.")

	_require(table_source.find("_server_room_id = String(TableLaunchContext.room_id)") != -1, "PokerTableScreen must boot from the launch context room_id.")
	_require(ws_source.find("signal hello_received(player_id: String, room_id: String, reconnected_to_table: bool)") != -1, "PokerWsClient hello signal must expose reconnect state.")
	_require(ws_source.find("hello_received.emit(player_id, room_id, bool(message.get(\"reconnected_to_table\", false)))") != -1, "PokerWsClient must pass reconnected_to_table from hello.")
	_require(table_source.find("func _on_server_hello_received(player_id: String, room_id: String, reconnected_to_table: bool = false)") != -1, "PokerTableScreen hello handler must accept reconnect state.")
	_require(table_source.find("if reconnected_to_table:") != -1 and table_source.find("Reconnected to table. Waiting for authoritative snapshot.") != -1, "Reconnect hello must skip new sit_down and wait for snapshot.")
	_require(table_source.find("_server_setup_done = true") != -1, "PokerTableScreen must guard repeated setup/sit_down sends in a single scene.")
	_require(server_source.find("sit_down idempotent room_id=") != -1, "Server sit_down must remain idempotent for reconnects.")
	_require(smoke_source.find("grace reconnect should not deduct another buy-in") != -1, "DB smoke must cover reconnect without a second buy-in.")
	_require(smoke_source.find("grace reconnect hello should return reconnected_to_table and original room_id") != -1, "DB smoke must cover reconnect hello protocol.")
	print("Online core reconnect/Quick regression test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
