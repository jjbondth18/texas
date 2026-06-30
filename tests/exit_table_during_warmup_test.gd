extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("_server_leave_return_pending") != -1)
	assert(table_source.find("_complete_return_home_after_server_leave_grace") != -1)
	assert(table_source.find("_cancel_pending_next_hand_timer()") != -1)
	assert(table_source.find("_stop_local_public_warmup()") != -1)
	assert(table_source.find("if _local_public_warmup_active:") != -1)
	assert(table_source.find("Leaving table...") != -1)
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("cashOutWarmupPlayer") == -1)
	assert(server_source.find("clearWarmupState") == -1)
	assert(server_source.find("hostInLocalWarmup") != -1)
