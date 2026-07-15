extends RefCounted

func run() -> void:
	var replay_source := FileAccess.get_file_as_string("res://server/src/replay.ts")
	var repository_source := FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	var room_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(replay_source.find("replay_${randomUUID()}") != -1)
	assert(repository_source.find("Replay ID collision detected. Existing replay preserved.") != -1)
	assert(repository_source.find("user://replays_quarantine") != -1)
	assert(repository_source.find("_official_identity_conflicts") != -1)
	assert(room_source.find("createOfficialReplay") != -1)
	assert(room_source.find("return undefined") != -1)
