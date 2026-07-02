extends RefCounted

func run() -> void:
	var record_source: String = FileAccess.get_file_as_string("res://scripts/replay/hand_replay_record.gd")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(record_source.find("return \"training\"") != -1)
	assert(record_source.find("table_type == \"training_ai\"") != -1)
	assert(table_source.find("_save_local_replay_record_once") != -1)
