extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_playback_next") != -1)
	assert(source.find("_replay_playback_prev") != -1)
	assert(source.find("_replay_playback_step += 1") != -1)
	assert(source.find("_replay_playback_step = max(0, _replay_playback_step - 1)") != -1)
	assert(source.find("_replay_playback_state_for_step") != -1)
	assert(source.find("_replay_playback_steps") != -1)
