extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var repository_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	var server_repository_source: String = FileAccess.get_file_as_string("res://server/src/db/replay_repository.ts")
	assert(repository_source.find("save_local_unlock_cache") != -1)
	assert(repository_source.find('\"authority\": authority') != -1)
	assert(server_repository_source.find("recordUnlock") != -1)
	assert(profile_source.find("func unlock_replay") != -1)
