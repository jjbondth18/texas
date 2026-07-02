extends RefCounted

const HandReplayRecordScript := preload("res://scripts/replay/hand_replay_record.gd")
const ReplayRepositoryScript := preload("res://scripts/replay/replay_repository.gd")

func run() -> void:
	var payload: Dictionary = {
		"hand_id": "hand_000001",
		"room_id": "room_1",
		"mode": "public",
		"players": [{"player_id": "local_player", "seat_index": 5, "hole_cards": ["AS", "KH"]}],
		"community_cards": {"flop": ["2C", "7D", "TH"], "turn": ["QS"], "river": ["AC"]},
		"actions": [{"seq": 1, "street": "preflop", "action": "call", "amount": 50, "pot_after": 75, "player_stack_after": 4950}],
		"results": {"winners": [{"winner_seat": 5, "amount_won": 100}], "final_pot": 100},
	}
	var record: Dictionary = HandReplayRecordScript.from_server_payload(payload)
	assert(int(record.get("replay_version", 0)) == HandReplayRecordScript.REPLAY_VERSION)
	assert(record.has("players"))
	assert(record.has("community_cards"))
	assert(record.has("actions"))
	assert(record.has("results"))
	assert(ReplayRepositoryScript.REPLAY_DIR == "user://replays")
	assert(ReplayRepositoryScript.INDEX_PATH == "user://replays/replay_index.json")
