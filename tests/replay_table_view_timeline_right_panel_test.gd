extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var replay_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var scene_source: String = FileAccess.get_file_as_string("res://scenes/screens/replay_poker_table_screen.tscn")
	assert(scene_source.find("RightPanel") != -1)
	assert(scene_source.find("LogPanel") != -1)
	assert(source.find("_toggle_replay_fullscreen_timeline") != -1)
	assert(replay_source.find("set_timeline_visible") != -1)
	assert(source.find("HIDE TIMELINE") != -1)
	assert(source.find("SHOW TIMELINE") != -1)
