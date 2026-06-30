extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("var _server_local_seat_index := -1") != -1)
	assert(source.find("var is_local := _server_seat_confirmed and i == _server_local_seat_index") != -1)
	assert(source.find("\"local_seat_index\": _server_local_seat_index if _server_seat_confirmed else -1") != -1)
	assert(source.find("Seat not confirmed") != -1 or source.find("Waiting for seat confirmation...") != -1)
