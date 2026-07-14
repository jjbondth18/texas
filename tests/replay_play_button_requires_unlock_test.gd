extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("if replay_unlocked:") != -1)
	assert(source.find('_t("replay.play_replay")') != -1)
	assert(source.find('_tf("replay.unlock_button"') != -1)
	assert(source.find("if not _is_replay_unlocked(record, index_entry):") != -1)
