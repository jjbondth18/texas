extends RefCounted

func run() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var repository_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	assert(server_source.find("mode: room.visibility === \"private\" ? \"private\" : \"public\"") != -1)
	assert(repository_source.find("private_%s") != -1)
	assert(repository_source.find("room_code") != -1)
