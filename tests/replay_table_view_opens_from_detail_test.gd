extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("PLAY REPLAY") != -1)
	assert(source.find("_open_replay_playback") != -1)
	assert(source.find("_render_replay_playback") != -1)
	assert(source.find("ReplayPokerTableScreenScene.instantiate()") != -1)
	assert(source.find("play_button.pressed.connect(_open_replay_playback.bind(record, index_entry))") != -1)
	assert(source.find("if not _is_replay_unlocked(record, index_entry):") != -1)
