extends RefCounted

const ReplayRepositoryScript := preload("res://scripts/replay/replay_repository.gd")

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	assert(ReplayRepositoryScript.INDEX_PATH == "user://replays/replay_index.json")
	assert(source.find("func load_index_entries") != -1)
	assert(source.find("func _update_index") != -1)
	assert(source.find("player_result") != -1)
	assert(source.find("summary") != -1)
