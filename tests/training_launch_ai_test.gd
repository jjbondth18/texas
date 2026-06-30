extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("func _is_training_launch") != -1)
	assert(table_source.find("if _is_training_launch():\n\t\tserver_authoritative = false") != -1)
	assert(table_source.find("Training Mode: AI opponents, no network authority") != -1)
	var backend_source := FileAccess.get_file_as_string("res://scripts/services/local_mock_backend.gd")
	assert(backend_source.find("func create_training_table") != -1)
	assert(backend_source.find("\"table_type\": \"training_ai\" if training else mode") != -1)
	assert(backend_source.find("\"uses_practice_chips\": training") != -1)
	assert(backend_source.find("\"affects_account_balance\": not training") != -1)
