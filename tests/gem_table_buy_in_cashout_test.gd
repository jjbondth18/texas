extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("reason: \"gem_table_buy_in\"") != -1, "Gem table sit_down must deduct Gems with gem_table_buy_in.")
	_require(server_source.find("this.wallets.addGems(client.id, amount") != -1, "Gem table cash out must return Gems.")
	_require(server_source.find("currency=${roomCurrency(room)}") != -1, "Gem cash-out logs should include table currency.")
	print("Gem table buy-in cashout test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
