extends SceneTree

func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")

	assert(server_source.find("private requirePublicHandStartAllowed(room: Room, client: Client): void") != -1)
	assert(server_source.find("if (client.id !== room.hostPlayerId) throw new Error(\"not_host\")") != -1)
	assert(server_source.find("if (this.publicReadyRequiredCount(room) < 2) throw new Error(\"not_enough_players\")") != -1)
	assert(server_source.find("if (!this.canStartPublicCountdown(room)) throw new Error(\"not_ready_to_start\")") != -1)
	assert(server_source.find("room.table.startHand(Date.now(), room.isPublic)") != -1)

	assert(table_source.find("func _is_authoritative_public_host") != -1)
	assert(table_source.find("_send_server_message(_poker_ws_client.ready(next_ready)") != -1)
	assert(table_source.find("Public hands start automatically after all seated players are ready.") != -1)
	quit()
