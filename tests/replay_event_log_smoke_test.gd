extends SceneTree

const HandLifecycle := preload("res://scripts/core/hand_lifecycle.gd")
const HandReplayService := preload("res://scripts/services/hand_replay_service.gd")

func _init() -> void:
	var state := HandLifecycle.start_new_hand({"seats": _seats(), "dealer_seat": 0}, 41)
	state = HandLifecycle.apply_action(state, {"id": "call", "seat_index": 1, "enabled": true})
	var events := HandReplayService.get_events(state)
	_assert(events.size() == HandReplayService.get_event_count(state), "event count mismatch")
	for i in events.size():
		_assert(int(Dictionary(events[i])["event_index"]) == i, "event indexes must be sequential")
	var replay := HandReplayService.reconstruct_to_event({"phase": "preflop", "hand_complete": false}, events, 2)
	_assert(Array(replay["events"]).size() == 3, "replay should include events through cursor")
	print("Replay event log smoke test passed.")
	quit(0)

func _seats() -> Array[Dictionary]:
	return [
		{"seat_index": 1, "player_id": "player_001", "chips": 10000, "status": "active"},
		{"seat_index": 2, "player_id": "player_002", "chips": 10000, "status": "active"},
	]

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
