extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var identity_source: String = FileAccess.get_file_as_string("res://scripts/services/identity_service.gd")

	_require(server_source.find("ready_count: this.publicReadyCount(room)") != -1, "Second real seated client should expose ready counts.")
	_require(server_source.find("private publicRoomState(room: Room): string") != -1, "Server should expose public room state.")
	_require(server_source.find("return \"waiting_ready\"") != -1, "Public room state must wait for ready.")
	_require(server_source.find("return \"starting_countdown\"") != -1, "Public room state must support ready countdown.")
	_require(server_source.find("hasUncontrolledDevSimulatedPlayer(room)") != -1, "Start blocking should be limited to uncontrolled dev simulated players.")
	_require(server_source.find("devSimulated") != -1, "Server should distinguish dev simulated players from real dev clients.")
	_require(server_source.find("client.id !== room.hostPlayerId") != -1, "Public hand start should remain host-only.")

	_require(identity_source.find("--dev-player-id") != -1, "Dev identity override should support a second real local client.")
	_require(identity_source.find("dev_player_2") == -1, "Identity service should not hard-code the second client as simulated.")

	_require(table_source.find("WAITING FOR READY") != -1, "Public table should use ready UI.")
	_require(table_source.find("_toggle_server_public_ready") != -1, "Ready button should toggle server ready state.")
	_require(table_source.find("DEV_SIMULATED_START_BLOCK_MESSAGE") != -1, "Dev simulated start block should provide explicit UI feedback.")
	_require(table_source.find("dev_simulated_player") != -1, "Client should only block dev simulated players, not dev_player_2 clients.")

	print("Two client join public room test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
