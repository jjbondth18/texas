extends SceneTree


func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(table_source.find("Your current table stack will be cashed out to your wallet.") != -1, "Between-hands exit copy must mention table stack cashout.")
	_require(server_source.find("table_cash_out") != -1, "Server must keep table_cash_out reason.")
	print("Public hand-over exit cashout stack test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
