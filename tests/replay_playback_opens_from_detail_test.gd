extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("PLAY REPLAY") != -1)
	assert(source.find("_open_replay_playback") != -1)
	assert(source.find("play_button.pressed.connect(_open_replay_playback.bind(record, index_entry))") != -1)
	assert(source.find("BACK TO DETAIL") != -1)
