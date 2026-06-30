extends RefCounted
class_name IdentityService

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func get_identity() -> Dictionary:
	var profile: Dictionary = ProfileServiceScript.new().get_current_profile()
	var local_player_id := String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID)).strip_edges()
	if local_player_id == "":
		local_player_id = PlayerProfileScript.DEFAULT_PLAYER_ID
	var display_name := PlayerProfileScript.get_player_name(profile)
	if display_name == "":
		display_name = PlayerProfileScript.DEFAULT_PLAYER_NAME
	return {
		"provider": _identity_provider(),
		"external_id": _external_id(local_player_id),
		"display_name": display_name,
		"avatar_id": PlayerProfileScript.get_avatar_id(profile),
	}

func _identity_provider() -> String:
	# TODO: Return "steam" once Steamworks identity is verified by a real backend.
	return "local_dev"

func _external_id(local_player_id: String) -> String:
	# TODO: Return verified SteamID when the Steam backend is available.
	return local_player_id
