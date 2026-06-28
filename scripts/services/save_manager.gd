extends RefCounted
class_name SaveManager

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

static func profile_to_save_data(profile: Dictionary) -> Dictionary:
	return {
		"schema_version": PlayerProfileScript.SCHEMA_VERSION,
		"player_profile": PlayerProfileScript.normalized_dict(profile),
	}

static func migrate_profile_save(save_data: Dictionary) -> Dictionary:
	var profile_data: Dictionary = {}
	if save_data.has("player_profile"):
		profile_data = Dictionary(save_data.get("player_profile", {}))
	else:
		profile_data = save_data.duplicate(true)
	return PlayerProfileScript.normalized_dict(profile_data)
