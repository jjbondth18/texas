extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	assert(table_source.find("DEV_SIMULATED_START_BLOCK_MESSAGE") != -1)
	assert(table_source.find("func _public_start_block_reason") != -1)
	assert(table_source.find("_ai_warmup_button.disabled = not (should_show or should_show_ready)") != -1)
	assert(server_source.find("dev_simulated_player_present") != -1)
	assert(protocol_source.find("dev_simulated_player_present") != -1)
	assert(server_source.find("Dev simulated player cannot play a real public hand") != -1)
	print("Dev simulated player start blocked test passed.")
	quit()
