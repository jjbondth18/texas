extends RefCounted
class_name MockTableSimulation

const HandLifecycleScript := preload("res://scripts/core/hand_lifecycle.gd")

const LOCAL_SEAT_INDEX := 5

static func get_mock_table_snapshot() -> Dictionary:
	return get_phase_snapshot("preflop")

static func get_phase_snapshot(phase: String) -> Dictionary:
	if phase.to_lower() in ["waiting", "ready"]:
		return get_waiting_snapshot()
	var state := HandLifecycleScript.start_new_hand({"seats": _mock_table_seats(), "dealer_seat": 0, "small_blind": 25, "big_blind": 50}, 101)
	var target := _normalize_phase(phase)
	while String(state.get("phase", "")) != target and not bool(state.get("hand_complete", false)):
		if String(state.get("phase", "")) == "finished":
			break
		_force_complete_current_street(state)
		if target == "showdown" and String(state.get("phase", "")) == "finished":
			break
	return _with_ui_fields(state)

static func get_waiting_snapshot() -> Dictionary:
	return _with_ui_fields({
		"table_id": "mock_table_001",
		"table_name": "Neon Table 01",
		"hand_id": "waiting",
		"hand_number": 0,
		"phase": "waiting",
		"dealer_seat": -1,
		"small_blind_seat": -1,
		"big_blind_seat": -1,
		"current_turn_seat": -1,
		"small_blind": 25,
		"big_blind": 50,
		"current_bet": 0,
		"minimum_raise": 50,
		"pot": {"main": 0, "side_pots": []},
		"community_cards": [],
		"seats": _mock_table_seats(),
		"action_history": [],
		"events": [
			{"type": "room_entered", "phase": "waiting", "seat_index": -1, "payload": {"room": "Neon Table 01"}},
			{"type": "waiting_for_hand", "phase": "waiting", "seat_index": -1, "payload": {}},
		],
		"hand_complete": false,
		"winners": [],
		"available_actions": [],
		"showdown_revealed": false,
	})

static func start_new_mock_hand(seed: int = 101) -> Dictionary:
	return _with_ui_fields(HandLifecycleScript.start_new_hand({"seats": _mock_table_seats(), "dealer_seat": 0, "small_blind": 25, "big_blind": 50}, seed))

static func start_test_hand(previous_snapshot: Dictionary = {}, seed: int = -1) -> Dictionary:
	var source := previous_snapshot.duplicate(true)
	if not source.has("seats") or Array(source.get("seats", [])).is_empty():
		source["seats"] = _mock_table_seats()
	source["small_blind"] = int(source.get("small_blind", 25))
	source["big_blind"] = int(source.get("big_blind", 50))
	source["dealer_seat"] = int(source.get("dealer_seat", 0))
	var hand_seed := seed if seed != -1 else 100 + int(source.get("hand_number", 0)) + 1
	return run_ai_until_local_turn(_with_ui_fields(HandLifecycleScript.start_new_hand(source, hand_seed)))

static func apply_mock_action(table_state: Dictionary, action: Dictionary) -> Dictionary:
	var state := table_state.duplicate(true)
	var norm_action := action.duplicate(true)
	if not norm_action.has("seat_index"):
		norm_action["seat_index"] = LOCAL_SEAT_INDEX
	
	var target_seat := int(norm_action["seat_index"])
	state["current_turn_seat"] = target_seat
	
	var next := HandLifecycleScript.apply_action(state, _normalize_action(state, norm_action))
	return run_ai_until_local_turn(_with_ui_fields(next))

static func advance_stage(table_state: Dictionary) -> Dictionary:
	var state := table_state.duplicate(true)
	if String(state.get("phase", "")) in ["waiting", "ready", "finished"]:
		return start_test_hand(state)
	_force_complete_current_street(state)
	return run_ai_until_local_turn(_with_ui_fields(state))

static func force_showdown(table_state: Dictionary) -> Dictionary:
	var state := table_state.duplicate(true)
	if String(state.get("phase", "")) in ["waiting", "ready"]:
		state = HandLifecycleScript.start_new_hand({"seats": _mock_table_seats(), "dealer_seat": 0, "small_blind": 25, "big_blind": 50}, 777)
	var guard := 0
	while String(state.get("phase", "")) not in ["showdown", "finished"] and guard < 120:
		guard += 1
		_force_complete_current_street(state)
	return run_ai_until_local_turn(_with_ui_fields(state))

static func reset_table() -> Dictionary:
	return get_waiting_snapshot()

static func run_ai_until_local_turn(table_state: Dictionary) -> Dictionary:
	var state := table_state.duplicate(true)
	var guard := 0
	while guard < 80:
		guard += 1
		var phase := String(state.get("phase", ""))
		if phase in ["waiting", "ready", "finished"]:
			break
		var turn_seat := int(state.get("current_turn_seat", -1))
		if turn_seat == LOCAL_SEAT_INDEX:
			break
		var actions := HandLifecycleScript.get_legal_actions(state, turn_seat)
		if actions.is_empty():
			break
		var action := _auto_action(actions)
		action["seat_index"] = turn_seat
		state = HandLifecycleScript.apply_action(state, action)
	return _with_ui_fields(state)

static func get_legal_actions(table_state: Dictionary, seat_index: int) -> Array:
	return HandLifecycleScript.get_legal_actions(table_state, seat_index)

static func visual_position_for_seat_index(seat_index: int, local_seat_index: int = LOCAL_SEAT_INDEX) -> int:
	return ((seat_index - local_seat_index + 4 + 9) % 9) + 1

static func _normalize_action(table_state: Dictionary, action: Dictionary) -> Dictionary:
	var normalized := action.duplicate(true)
	if not normalized.has("seat_index"):
		normalized["seat_index"] = int(table_state.get("current_turn_seat", LOCAL_SEAT_INDEX))
	if not normalized.has("player_id"):
		normalized["player_id"] = _player_id_for_seat(table_state, int(normalized["seat_index"]))
	return normalized

static func _with_ui_fields(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	next["table_id"] = String(next.get("table_id", "mock_table_001"))
	next["table_name"] = String(next.get("table_name", "Neon Table 01"))
	next["blinds_text"] = "%d / %d" % [int(next.get("small_blind", 25)), int(next.get("big_blind", 50))]
	next["pot_data"] = Dictionary(next.get("pot", {"main": 0, "side_pots": []})).duplicate(true)
	next["pot"] = int(Dictionary(next["pot_data"]).get("main", 0))
	next["local_seat_index"] = LOCAL_SEAT_INDEX
	next["turn_seat_index"] = int(next.get("current_turn_seat", -1))
	next["turn_seconds"] = 15
	next["room_state"] = _room_state_for_phase(String(next.get("phase", "waiting")))
	var seats: Array = []
	for seat in Array(next.get("seats", [])):
		var data := Dictionary(seat).duplicate(true)
		var seat_index := int(data.get("seat_index", 0))
		data["visual_position"] = visual_position_for_seat_index(seat_index, LOCAL_SEAT_INDEX)
		data["current_bet"] = int(data.get("street_bet", data.get("current_bet", 0)))
		data["is_local"] = seat_index == LOCAL_SEAT_INDEX
		data["is_dealer"] = seat_index == int(next.get("dealer_seat", -1))
		data["is_small_blind"] = seat_index == int(next.get("small_blind_seat", -1))
		data["is_big_blind"] = seat_index == int(next.get("big_blind_seat", -1))
		data["is_turn"] = seat_index == int(next.get("current_turn_seat", -1))
		if String(data.get("status", "")) != "empty" and seat_index != LOCAL_SEAT_INDEX and String(next.get("phase", "")) != "finished":
			var hidden: Array[Dictionary] = []
			for _card in Array(data.get("cards", [])):
				hidden.append({"rank": "", "suit": "", "code": "", "face_up": false})
			data["cards"] = hidden
		else:
			var cards: Array[Dictionary] = []
			for card in Array(data.get("cards", [])):
				var face := Dictionary(card).duplicate(true)
				face["face_up"] = true
				cards.append(face)
			data["cards"] = cards
		seats.append(data)
	next["seats"] = seats
	next["local_player"] = _local_player_from_seats(seats)
	if int(next.get("current_turn_seat", -1)) == LOCAL_SEAT_INDEX:
		next["available_actions"] = HandLifecycleScript.get_legal_actions(next, LOCAL_SEAT_INDEX)
	else:
		next["available_actions"] = []
	next["hand_history"] = _history_from_events(Array(next.get("events", [])))
	next["system_messages"] = [
		"Lifecycle hand engine active. Room state: %s" % String(next.get("room_state", "")),
		"Debug keys: S start hand, N advance stage, W force showdown, R reset table",
	]
	next["deck_count"] = 52
	return next

static func _force_complete_current_street(state: Dictionary) -> void:
	var initial_phase := String(state.get("phase", ""))
	var guard := 0
	while not bool(state.get("hand_complete", false)) and guard < 30:
		guard += 1
		var seat_index := int(state.get("current_turn_seat", -1))
		var actions := HandLifecycleScript.get_legal_actions(state, seat_index)
		if actions.is_empty():
			break
		var action := _auto_action(actions)
		action["seat_index"] = seat_index
		var next := HandLifecycleScript.apply_action(state, action)
		state.clear()
		state.merge(next, true)
		if String(state.get("phase", "")) != initial_phase:
			break

static func _auto_action(actions: Array) -> Dictionary:
	for action in actions:
		var data := Dictionary(action)
		if String(data.get("id", "")) == "check" and bool(data.get("enabled", false)):
			return {"id": "check", "enabled": true}
	for action in actions:
		var data := Dictionary(action)
		if String(data.get("id", "")) == "call" and bool(data.get("enabled", false)):
			return {"id": "call", "enabled": true, "amount": int(data.get("amount", 0))}
	return {"id": "fold", "enabled": true}

static func _street_has_open_action(state: Dictionary) -> bool:
	for seat in Array(state.get("seats", [])):
		var data := Dictionary(seat)
		if String(data.get("status", "")) == "active" and not bool(data.get("has_acted", false)):
			return true
	return false

static func _mock_table_seats() -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for i in range(1, 10):
		seats.append({
			"seat_index": i,
			"player_id": "player_%03d" % i,
			"player_name": "Luna0581" if i == LOCAL_SEAT_INDEX else ("XProGamer_Texas_999" if i == 4 else "Seat %d" % i),
			"chips": 24500 if i == LOCAL_SEAT_INDEX else 12000 + i * 850,
			"status": "empty" if i == 8 else "active",
			"is_local": i == LOCAL_SEAT_INDEX,
		})
	return seats

static func _normalize_phase(phase: String) -> String:
	var lowered := phase.to_lower()
	if lowered in ["preflop", "flop", "turn", "river", "showdown"]:
		return lowered
	return "preflop"

static func _room_state_for_phase(phase: String) -> String:
	match phase:
		"waiting":
			return "waiting"
		"ready":
			return "ready"
		"finished":
			return "hand_over"
		"showdown":
			return "showdown"
	return "in_hand"

static func _local_player_from_seats(seats: Array) -> Dictionary:
	for seat in seats:
		var data := Dictionary(seat)
		if bool(data.get("is_local", false)):
			return data.duplicate(true)
	return {}

static func _player_id_for_seat(state: Dictionary, seat_index: int) -> String:
	for seat in Array(state.get("seats", [])):
		var data := Dictionary(seat)
		if int(data.get("seat_index", -1)) == seat_index:
			return String(data.get("player_id", ""))
	return ""

static func _history_from_events(events: Array) -> Array[String]:
	var lines: Array[String] = []
	for event in events.slice(max(events.size() - 8, 0)):
		var data := Dictionary(event)
		var payload := Dictionary(data.get("payload", {}))
		match String(data.get("type", "")):
			"room_entered":
				lines.append("Entered room: %s" % String(payload.get("room", "Neon Table 01")))
			"waiting_for_hand":
				lines.append("Waiting for next hand. Press S to start test hand.")
			"hand_started":
				lines.append("Hand #%d started" % int(payload.get("hand_number", 0)))
			"dealer_assigned":
				lines.append("Seat %d is dealer" % int(data.get("seat_index", -1)))
			"blind_posted":
				lines.append("Seat %d posted %s %d" % [int(data.get("seat_index", -1)), String(payload.get("blind", "")), int(payload.get("amount", 0))])
			"hole_cards_dealt":
				lines.append("Hole cards dealt")
			"player_action":
				var amount := int(payload.get("amount", 0))
				var suffix := " %d" % amount if amount > 0 else ""
				lines.append("Seat %d %s%s" % [int(data.get("seat_index", -1)), String(payload.get("id", payload.get("action", ""))), suffix])
			"street_completed":
				lines.append("%s betting round complete" % String(payload.get("phase", "")).capitalize())
			"street_started":
				lines.append("%s started" % String(payload.get("phase", "")).capitalize())
			"community_cards_dealt":
				var total := int(payload.get("total", 0))
				if total == 3:
					lines.append("Flop dealt")
				elif total == 4:
					lines.append("Turn dealt")
				elif total == 5:
					lines.append("River dealt")
				else:
					lines.append("Board cards dealt: %d total" % total)
			"showdown_started":
				lines.append("Showdown started")
			"winner_determined":
				lines.append("Winner candidate: Seat %d (%s)" % [int(data.get("seat_index", -1)), String(payload.get("hand_rank", ""))])
			"pot_awarded":
				lines.append("Seat %d wins %d" % [int(data.get("seat_index", -1)), int(payload.get("amount", 0))])
			"hand_finished":
				lines.append("Hand finished: %s" % String(payload.get("reason", "")))
			"hand_won_by_fold":
				lines.append("Seat %d wins by fold" % int(data.get("seat_index", -1)))
			"action_rejected":
				lines.append("Action rejected: %s" % String(payload.get("reason", "")))
	return lines
