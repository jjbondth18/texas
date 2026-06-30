extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("if server_authoritative and (not _server_seat_confirmed or _server_local_seat_index < 0):") != -1)
	assert(source.find("Cannot start AI warm-up: waiting for seat confirmation.") != -1)
	assert(source.find("var waiting_for_real_players := local_seat_confirmed") != -1)
	assert(source.find("can_show_warmup=%s") != -1)
