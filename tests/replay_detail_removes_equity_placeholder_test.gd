extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("Equity Timeline") == -1)
	assert(source.find("Coming in a later update.") == -1)
	assert(source.find("_replay_equity_box = null") != -1)
