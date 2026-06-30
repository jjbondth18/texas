extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("func _try_server_sit_down") != -1)
	assert(source.find("_server_sit_down_pending = true") != -1)
	assert(source.find("func _try_server_ready_after_seated") != -1)
	assert(source.find("if _server_ready_sent or not _server_seat_confirmed or _server_local_seat_index < 0") != -1)
	assert(source.find("_send_server_message(_poker_ws_client.ready(true), \"ready\")") != -1)
	assert(source.find("_send_server_message(_poker_ws_client.sit_down(_server_requested_seat_index") != -1)
