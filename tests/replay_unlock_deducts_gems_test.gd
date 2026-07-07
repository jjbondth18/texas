extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var player_source: String = FileAccess.get_file_as_string("res://scripts/data/player_profile.gd")
	assert(player_source.find("const REPLAY_UNLOCK_COST_GEMS := 20") != -1)
	assert(profile_source.find("profile[\"gems\"] = available_gems - cost_gems") != -1)
	assert(profile_source.find("PlayerProfileScript.REPLAY_UNLOCK_COST_GEMS") != -1)
