extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var repository_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	assert(source.find("Replay file missing.") != -1)
	assert(source.find("FileAccess.file_exists(file_path)") != -1)
	assert(repository_source.find("func load_hand_record") != -1)
	assert(repository_source.find("return {}") != -1)
