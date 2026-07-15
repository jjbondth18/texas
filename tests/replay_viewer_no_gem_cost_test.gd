extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var replay_screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_open_replay_detail") != -1)
	assert(source.find("func _unlock_replay_from_detail") != -1)
	assert(source.find("_profile_ws_client.unlock_replay(") != -1)
	assert(source.find("PlayerProfileScript.replay_price_gems") != -1)
	assert(replay_screen_source.find("gems") == -1)
