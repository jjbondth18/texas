extends RefCounted

func run() -> void:
	var registry_source := FileAccess.get_file_as_string("res://scripts/services/public_table_registry.gd")
	assert(registry_source.find("pending_next_hand") == -1)
	assert(registry_source.find("host_in_local_warmup") != -1)
	assert(registry_source.find("table[\"host_in_local_warmup\"] = false") != -1)
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("WARM-UP / WAITING FOR PLAYERS") != -1)
