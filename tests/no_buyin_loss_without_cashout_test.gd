extends SceneTree


func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var wallet_source: String = FileAccess.get_file_as_string("res://server/src/db/wallet_repository.ts")
	_require(table_source.find("Exit settlement timed out. Please retry; wallet was not assumed settled.") != -1, "Client must not silently leave when settlement times out.")
	_require(table_source.find("call_deferred(\"_complete_return_home_after_server_leave_grace\")") == -1, "Client must not complete home return through the old grace path.")
	_require(wallet_source.find("auditWalletTransactions") != -1, "Wallet repository must expose a buy-in/cashout audit helper.")
	print("No buy-in loss without cashout test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
