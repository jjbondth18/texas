extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(table_source.find("_poker_ws_client.cash_out()") != -1)
	assert(server_source.find("Wallet refund: reason=${reason}") != -1)
	assert(table_source.find("You have not started an official hand. Your table chips will be returned to your wallet.") != -1)
	assert(server_source.find("exitSettlementReason") != -1)
	print("Public waiting exit refunds buy-in test passed.")
	quit()
