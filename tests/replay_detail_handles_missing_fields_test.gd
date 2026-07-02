extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("Unknown") != -1)
	assert(source.find("get(\"mode\", \"\")") != -1)
	assert(source.find("get(\"room_id\", \"\")") != -1)
	assert(source.find("get(\"side_pots\", [])") != -1)
	assert(source.find("_winner_summary") != -1)
