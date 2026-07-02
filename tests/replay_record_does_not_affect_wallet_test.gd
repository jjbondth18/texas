extends RefCounted

func run() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var repository_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_repository.gd")
	assert(table_source.find("ReplayRepositoryScript.save_hand_record") != -1)
	assert(repository_source.find("wallet") == -1)
	assert(repository_source.find("gems") == -1)
	assert(repository_source.find("push_warning") != -1)
