extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var player_source: String = FileAccess.get_file_as_string("res://scripts/data/player_profile.gd")
	assert(player_source.find("unlocked_replay_ids") != -1)
	assert(profile_source.find("profile[\"unlocked_replay_ids\"] = unlocked") != -1)
	assert(profile_source.find("save_current_profile(profile)") != -1)
