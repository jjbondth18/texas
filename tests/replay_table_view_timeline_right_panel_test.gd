extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("ReplayFullscreenTimelinePanel") != -1)
	assert(source.find("_replay_fullscreen_timeline_panel.offset_left = -350") != -1)
	assert(source.find("_toggle_replay_fullscreen_timeline") != -1)
	assert(source.find("HIDE TIMELINE") != -1)
	assert(source.find("SHOW TIMELINE") != -1)
