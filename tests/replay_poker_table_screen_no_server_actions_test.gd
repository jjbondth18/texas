extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("PokerWsClient") == -1)
	assert(source.find("_poker_ws_client") == -1)
	assert(source.find("send_player_action") == -1)
	assert(source.find("player_action") == -1)
	assert(source.find("cash_out") == -1)
	assert(source.find("wallet") == -1)
	assert(source.find("gems") == -1)
