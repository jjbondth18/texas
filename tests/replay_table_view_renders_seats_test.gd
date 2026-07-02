extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_render_replay_table_view") != -1)
	assert(source.find("_add_replay_table_seat_card") != -1)
	assert(source.find("_replay_table_seat_position") != -1)
	assert(source.find("ReplaySeat%d") != -1)
	assert(source.find("Seat %d - %s") != -1)
	assert(source.find("Cards: %s") != -1)
