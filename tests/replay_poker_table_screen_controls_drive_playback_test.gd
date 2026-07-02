extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("previous_step_requested") != -1)
	assert(source.find("next_step_requested") != -1)
	assert(source.find("playback_toggle_requested") != -1)
	assert(source.find("speed_toggle_requested") != -1)
	assert(home_source.find("previous_step_requested.connect(_replay_playback_prev)") != -1)
	assert(home_source.find("next_step_requested.connect(_replay_playback_next)") != -1)
	assert(home_source.find("playback_toggle_requested.connect(_toggle_replay_playback)") != -1)
	assert(home_source.find("speed_toggle_requested.connect(_toggle_replay_playback_speed)") != -1)
