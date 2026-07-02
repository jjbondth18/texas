extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("_is_replay_debug_action") != -1)
	assert(source.find("_looks_like_replay_debug_text") != -1)
	assert(source.find("begins_with(\"----\")") != -1)
	assert(source.find("ends_with(\"----\")") != -1)
	assert(source.find("message != \"\" and not _looks_like_replay_debug_text(message)") != -1)
