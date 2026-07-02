extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var playback_pos: int = source.find("_open_replay_playback")
	assert(playback_pos != -1)
	var store_pos: int = source.find("func _build_store_panel")
	var playback_source: String = source.substr(playback_pos, store_pos - playback_pos)
	assert(playback_source.find("PokerTableScreen") == -1)
	assert(playback_source.find("_poker_ws_client") == -1)
	assert(playback_source.find("send_player_action") == -1)
	assert(playback_source.find("apply_wallet_snapshot") == -1)
