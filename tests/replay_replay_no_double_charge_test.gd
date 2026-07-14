extends RefCounted

func run() -> void:
	var profile_source: String = FileAccess.get_file_as_string("res://scripts/services/profile_service.gd")
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	assert(profile_source.find("if unlocked.has(clean_id):") != -1)
	assert(profile_source.find("\"already_unlocked\"") != -1)
	assert(server_source.find("const existing = this.replays.getUnlock(replayId, client.id)") != -1)
	assert(server_source.find("alreadyUnlocked: true") != -1)
	var playback_pos: int = home_source.find("func _open_replay_playback")
	assert(playback_pos != -1)
	var playback_source: String = home_source.substr(playback_pos, 420)
	assert(playback_source.find("unlock_replay") == -1)
	assert(playback_source.find("gems") == -1)
