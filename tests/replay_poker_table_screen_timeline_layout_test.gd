extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_configure_replay_timeline_panel") != -1)
	assert(source.find("right_panel.position = Vector2(2240, 150)") != -1)
	assert(source.find("right_panel.size = Vector2(320, 700)") != -1)
	assert(source.find("_log_panel.size = Vector2(336, 640)") != -1)
	assert(source.find("HAND HISTORY") != -1)
	assert(source.find("SYSTEM MESSAGES") != -1)
