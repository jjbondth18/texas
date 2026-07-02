extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var service_source: String = FileAccess.get_file_as_string("res://scripts/services/replay_service.gd")
	assert(source.find("_open_replay_detail") != -1)
	assert(source.find("Unlock Replay Pro") == -1)
	assert(source.find("Coming in a later update.") != -1)
	assert(source.find("spend_gems") == -1)
	assert(service_source.find("gems") == -1)
