extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("REPLAY_TABLE_DESIGN_SIZE := Vector2(2560.0, 900.0)") != -1)
	assert(source.find("REPLAY_SEAT_PANEL_ORIGINS_BY_SEAT") != -1)
	assert(source.find("REPLAY_BET_MARKER_ANCHORS_BY_SEAT") != -1)
	assert(source.find("_replay_design_to_view") != -1)
	assert(source.find("REPLAY_SEAT_PANEL_ORIGINS_BY_SEAT.get") != -1)
