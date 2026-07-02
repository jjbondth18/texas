extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_list_panel") != -1)
	assert(source.find("_set_replay_playback_layout") != -1)
	assert(source.find("_replay_list_panel.visible = not enabled") != -1)
	assert(source.find("_replay_equity_box.visible = not enabled") != -1)
