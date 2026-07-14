extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(profile_source.find("func unlock_replay") != -1)
	assert(home_source.find("not OS.is_debug_build()") != -1)
	assert(home_source.find("_profile_ws_client.unlock_replay(replay_id, replay_type)") != -1)
	assert(server_source.find('if (wallet.gems < priceGems) throw new Error("insufficient_gems")') != -1)
	assert(server_source.find("replayUnlockCost(replayType)") != -1)
