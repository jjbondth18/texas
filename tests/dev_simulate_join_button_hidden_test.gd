extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var client_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	_assert(table_source.find("DEV: SIMULATE REAL PLAYER JOIN") == -1, "Poker table UI must not render the dev simulate join button.")
	_assert(table_source.find("_top_control_button(\"DEV: SIMULATE REAL PLAYER JOIN\"") == -1, "Top-right action bar must not create the dev simulate join button.")
	_assert(table_source.find("_dev_simulate_real_join_button = null") != -1, "Hidden dev button reference should stay null in normal UI.")
	_assert(table_source.find("_poker_ws_client.dev_simulate_real_join(_server_room_id, \"DevPlayer2\")") != -1, "Dev command may remain callable for tests.")
	_assert(protocol_source.find("dev_simulate_real_join") != -1, "Protocol command may remain available.")
	_assert(client_source.find("func dev_simulate_real_join") != -1, "WebSocket command may remain available.")
	print("Dev simulate join button hidden test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
