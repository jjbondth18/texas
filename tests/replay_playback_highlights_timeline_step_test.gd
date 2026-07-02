extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_render_replay_playback_timeline") != -1)
	assert(source.find("i == _replay_playback_step - 1") != -1)
	assert(source.find("HomeTheme.GOLD") != -1)
	assert(source.find("Step %d / %d") != -1)
	assert(source.find("PLAYER ACTIONS") != -1)
	assert(source.find("HAND EVENTS") != -1)
