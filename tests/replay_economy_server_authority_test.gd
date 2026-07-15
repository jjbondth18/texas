extends RefCounted

func run() -> void:
	var economy_source := FileAccess.get_file_as_string("res://server/src/replay_economy.ts")
	var room_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	assert(economy_source.find("REPLAY_ECONOMY_CONFIG") != -1)
	assert(economy_source.find("official_replay_unlock") != -1)
	assert(economy_source.find("ai_replay_unlock") != -1)
	assert(economy_source.find("training_replay_unlock") != -1)
	assert(room_source.find("replayUnlockCost(replayType)") != -1)
	assert(room_source.find("profile_snapshot: this.authoritativeProfileSnapshot(client.id)") != -1)
	assert(protocol_source.find("_replay_identity_payload") != -1)
	assert(protocol_source.find("checksum") != -1)
