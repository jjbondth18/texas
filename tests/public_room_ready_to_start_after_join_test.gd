extends SceneTree

func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var registry_source := FileAccess.get_file_as_string("res://scripts/services/public_table_registry.gd")

	assert(server_source.find("ready_to_start") != -1)
	assert(server_source.find("private publicRoomState(room: Room): string") != -1)
	assert(server_source.find("if ([\"waiting\", \"hand_over\"].includes(room.table.phase)) return \"ready_to_start\"") != -1)
	assert(server_source.find("host_player_id: room.hostPlayerId") != -1)

	assert(table_source.find("READY TO START") != -1)
	assert(table_source.find("START PUBLIC HAND") != -1)
	assert(table_source.find("func _should_show_public_start_hand_entry()") != -1)
	assert(table_source.find("Waiting for host to start.") != -1)

	assert(registry_source.find("const STATUS_READY_TO_START := \"ready_to_start\"") != -1)
	assert(registry_source.find("table[\"status\"] = STATUS_READY_TO_START") != -1)
	quit()
