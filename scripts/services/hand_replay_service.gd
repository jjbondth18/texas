extends RefCounted
class_name HandReplayService

static func get_events(hand_state: Dictionary) -> Array:
	return Array(hand_state.get("events", [])).duplicate(true)

static func get_event_count(hand_state: Dictionary) -> int:
	return Array(hand_state.get("events", [])).size()

static func reconstruct_to_event(initial_state: Dictionary, events: Array, event_index: int) -> Dictionary:
	var snapshot := initial_state.duplicate(true)
	var replay_events: Array = []
	for event in events:
		var data := Dictionary(event).duplicate(true)
		if int(data.get("event_index", -1)) > event_index:
			break
		replay_events.append(data)
		_apply_display_event(snapshot, data)
	snapshot["events"] = replay_events
	snapshot["replay_cursor"] = event_index
	return snapshot

static func _apply_display_event(snapshot: Dictionary, event: Dictionary) -> void:
	match str(event.get("type", "")):
		"street_started":
			snapshot["phase"] = str(Dictionary(event.get("payload", {})).get("phase", snapshot.get("phase", "")))
		"community_cards_dealt":
			snapshot["community_card_count"] = int(Dictionary(event.get("payload", {})).get("total", 0))
		"turn_started":
			snapshot["current_turn_seat"] = int(event.get("seat_index", -1))
		"hand_finished":
			snapshot["hand_complete"] = true
