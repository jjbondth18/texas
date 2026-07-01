extends SceneTree


func _init() -> void:
	var server_state_source: String = FileAccess.get_file_as_string("res://server/src/table_state.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(server_state_source.find("[\"waiting\", \"hand_over\", \"session_complete\"].includes(this.phase)") != -1, "Cash out must be allowed during session_complete.")
	_require(table_source.find("_poker_ws_client.cash_out()") != -1, "Exit Table must cash out through the server.")
	_require(table_source.find("_cancel_pending_next_hand_timer()") != -1, "Exit Table must stop pending local next-hand timers.")
	print("Session complete exit cashout test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
