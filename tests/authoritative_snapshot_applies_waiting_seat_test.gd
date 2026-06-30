extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("_sync_authoritative_waiting_context") != -1)
	assert(source.find("_server_ui_seats_to_table_flow_seats") != -1)
	assert(source.find("_real_public_player_count_from_snapshot") != -1)
	assert(source.find("TableLaunchContext.waiting_for_real_players = waiting_for_real_players") != -1)
	assert(source.find("_table_flow.table_state = TexasTableFlowScript.WAITING") != -1)
	assert(source.find("_table_flow.seats = _server_ui_seats_to_table_flow_seats(seats)") != -1)
