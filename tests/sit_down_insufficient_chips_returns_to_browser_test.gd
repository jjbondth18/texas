extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("wallet_chips: int = -1, required_chips: int = -1") != -1)
	assert(source.find("Not enough chips for this buy-in. Required: %s. Wallet: %s.") != -1)
	assert(source.find("TableLaunchContext.set_pending_launch_error(failure_message)") != -1)
	assert(source.find("call_deferred(\"_complete_return_home\")") != -1)
	assert(source.find("_server_local_seat_index = -1") != -1)
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("func _show_pending_launch_error") != -1)
	assert(home_source.find("TableLaunchContext.consume_pending_launch_error()") != -1)
