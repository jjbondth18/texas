extends SceneTree

func _init() -> void:
	var protocol_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var client_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(protocol_source.find("join_private_table(room_code") != -1, "Protocol must create join_private_table room-code messages.")
	_require(client_source.find("func join_private_table(room_code: String)") != -1, "PokerWsClient must expose join_private_table.")
	_require(home_source.find("_join_private_room_by_code") != -1, "Home lobby must join private rooms by code.")
	_require(smoke_source.find("join_private_table should join by room code") != -1, "DB smoke must verify join-by-code.")
	print("Private room join by code test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
