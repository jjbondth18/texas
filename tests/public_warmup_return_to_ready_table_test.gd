extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("func _return_from_local_warmup_to_public") != -1)
	assert(table_source.find("_stop_local_public_warmup()") != -1)
	assert(table_source.find("Real player joined. Ready to start public hand.") != -1)
	assert(table_source.find("snapshot = returned_snapshot") != -1)
	var registry_source := FileAccess.get_file_as_string("res://scripts/services/public_table_registry.gd")
	assert(registry_source.find("table[\"host_in_local_warmup\"] = false") != -1)
