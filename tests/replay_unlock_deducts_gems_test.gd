extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var player_source: String = FileAccess.get_file_as_string("res://scripts/data/player_profile.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/replay_economy.ts")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(player_source.find("REPLAY_UNLOCK_COST_GEMS") == -1)
	assert(server_source.find("official_human: 20") != -1)
	assert(server_source.find("ai: 10") != -1)
	assert(server_source.find("training: 10") != -1)
	assert(profile_source.find("profile[\"gems\"] = available_gems - cost_gems") != -1)
	assert(home_source.find("PlayerProfileScript.replay_price_gems") != -1)
