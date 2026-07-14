extends RefCounted

func run() -> void:
	var record_source := FileAccess.get_file_as_string("res://scripts/data/replay_record.gd")
	var repository_source := FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	var service_source := FileAccess.get_file_as_string("res://scripts/services/replay_service.gd")
	for field in ["replay_type", "price_gems", "locked", "unlocked"]:
		assert(record_source.find('"%s"' % field) != -1)
	assert(repository_source.find('clean_record["replay_type"]') != -1)
	assert(repository_source.find('clean_record["storage_mode"] = LOCAL_PLAINTEXT_MODE') != -1)
	assert(repository_source.find("save_local_unlock_cache") != -1)
	assert(service_source.find('"price_gems": int(prices.get(replay_type, -1))') != -1)
	assert(service_source.find('"locked": not unlocked') != -1)
