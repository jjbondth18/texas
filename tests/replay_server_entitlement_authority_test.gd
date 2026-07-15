extends RefCounted

func run() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var repository_source := FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	var room_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(home_source.find("_replay_access_by_id") != -1)
	assert(home_source.find("get_replay_access") != -1)
	assert(home_source.find('bool(access.get("supported", false))') != -1)
	assert(repository_source.find('cache.get("checksum"') != -1)
	assert(repository_source.find('cache.get("key_version"') != -1)
	assert(repository_source.find('cache.get("algorithm"') != -1)
	assert(repository_source.find('cache.get("replay_type"') != -1)
	assert(room_source.find('type: "replay_access"') != -1)
	assert(room_source.find('legacy_reason: "replay_not_found"') != -1)
	var record_source := FileAccess.get_file_as_string("res://scripts/replay/hand_replay_record.gd")
	assert(record_source.find('record["objective_equity_by_player"]') != -1)
	assert(home_source.find("if not _is_replay_unlocked(record, index_entry):") != -1)
