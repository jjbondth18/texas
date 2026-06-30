extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("func _should_interrupt_local_public_warmup") != -1)
	assert(table_source.find("_return_from_local_warmup_to_public(next_snapshot)") != -1)
	assert(table_source.find("Real player joined. Returning to public table.") != -1)
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(server_source.find("real_player_joined_interrupts_local_warmup") != -1)
	assert(server_source.find("room.hostInLocalWarmup = \"\"") != -1)
