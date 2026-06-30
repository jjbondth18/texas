extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("func _normalized_turn_seat") != -1)
	assert(table_source.find("seat[\"is_turn\"] = turn_seat >= 0 and seat_id == turn_seat") != -1)
	assert(table_source.find("_set_projected_turn_highlight(seat_id)") != -1)
	assert(table_source.find("_status_panel.set_status(snapshot)") != -1)
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	assert(protocol_source.find("current_turn_player_id") != -1)
	var table_state_source := FileAccess.get_file_as_string("res://server/src/table_state.ts")
	assert(table_state_source.find("current_turn_player_id: this.getSeat(this.currentTurnSeat)?.playerId") != -1)
