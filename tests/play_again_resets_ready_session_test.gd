extends SceneTree


func _init() -> void:
	var client_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var protocol_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(protocol_source.find("RESTART_SESSION") != -1, "Protocol must define restart_session.")
	_require(client_source.find("func restart_session") != -1, "WebSocket client must send restart_session.")
	_require(server_source.find("restartPublicSession") != -1, "Server must reset a completed session in-place.")
	_require(server_source.find("room.table.resetForNewSession()") != -1, "Play Again must keep the room but reset ready/session state.")
	_require(table_source.find("_poker_ws_client.restart_session()") != -1, "Play Again must ask the server to reset instead of re-buying.")
	print("Play again resets ready session test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
