extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("_server_leave_return_pending") != -1)
	assert(table_source.find("_complete_return_home_after_server_leave_grace") != -1)
	assert(table_source.find("_cancel_pending_next_hand_timer()") != -1)
	assert(table_source.find("Leaving table...") != -1)
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("cashOutWarmupPlayer") != -1)
	assert(server_source.find("clearWarmupState") != -1)
	assert(server_source.find("cancelWarmupNextHand") != -1)
	assert(server_source.find("Practice result ignored and original table stack returned") != -1)
