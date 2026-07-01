extends SceneTree

func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")

	assert(server_source.find("waiting_ready") != -1)
	assert(server_source.find("starting_countdown") != -1)
	assert(server_source.find("private publicRoomState(room: Room): string") != -1)
	assert(server_source.find("if ([\"waiting\", \"hand_over\"].includes(room.table.phase)) return \"waiting_ready\"") != -1)
	assert(server_source.find("host_player_id: room.hostPlayerId") != -1)
	assert(server_source.find("ready_count: this.publicReadyCount(room)") != -1)

	assert(table_source.find("WAITING FOR READY") != -1)
	assert(table_source.find("READY") != -1)
	assert(table_source.find("UNREADY") != -1)
	assert(table_source.find("func _should_show_public_ready_entry()") != -1)
	assert(table_source.find("All players ready. Starting in") != -1)

	quit()
