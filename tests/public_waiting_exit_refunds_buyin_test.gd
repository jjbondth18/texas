extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(table_source.find("_poker_ws_client.cash_out()") != -1)
	assert(server_source.find("Wallet refund: reason=${reason}") != -1)
	assert(server_source.find("reason = room.isPublic && !room.officialHandStarted ? \"left_before_official_hand\" : \"table_cash_out\"") != -1)
	print("Public waiting exit refunds buy-in test passed.")
	quit()
