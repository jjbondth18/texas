extends RefCounted

func run() -> void:
	var record_source: String = FileAccess.get_file_as_string("res://scripts/replay/hand_replay_record.gd")
	var repository_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	assert(record_source.find("return \"local_warmup\"") != -1)
	assert(record_source.find("is_local_warmup_ai") != -1)
	assert(repository_source.find("prefix = \"warmup\"") != -1)
