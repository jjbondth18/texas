extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_replay_list_lock_labels") != -1)
	assert(source.find("LOCKED") != -1)
	assert(source.find("UNLOCKED") != -1)
	assert(source.find("_update_replay_list_lock_label") != -1)
