extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("func _server_local_seat_from_snapshot") != -1)
	assert(source.find("String(seat.get(\"player_id\", \"\")) == _server_local_player_id") != -1)
	assert(source.find("return -1") != -1)
	assert(source.find("var is_local := local_server_seat >= 0") != -1)
	assert(source.find("local_player_seat_index=%d") != -1)
