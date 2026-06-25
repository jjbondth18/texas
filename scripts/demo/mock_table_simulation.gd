extends RefCounted
class_name MockTableSimulation

const DeckScript := preload("res://scripts/core/deck.gd")
const PokerPhaseScript := preload("res://scripts/core/poker_phase.gd")
const BettingActionScript := preload("res://scripts/core/betting_action.gd")
const TableStateReducerScript := preload("res://scripts/core/table_state_reducer.gd")

const LOCAL_SEAT_INDEX := 5

static func get_mock_table_snapshot() -> Dictionary:
	return get_phase_snapshot("preflop")

static func get_phase_snapshot(phase: String) -> Dictionary:
	var deck := DeckScript.new()
	var normalized_phase := _normalize_phase(phase)
	var community_cards := _community_cards_for_phase(normalized_phase)
	var seats := _mock_seats(normalized_phase)
	return {
		"table_id": "mock_table_001",
		"table_name": "Neon Table 01",
		"blinds_text": "25 / 50",
		"phase": normalized_phase,
		"deck_count": deck.count(),
		"community_cards": community_cards,
		"pot": 1250,
		"pot_data": {"main": 1250, "side_pots": []},
		"seats": seats,
		"local_player": _local_player_from_seats(seats),
		"dealer_seat_index": 1,
		"local_seat_index": LOCAL_SEAT_INDEX,
		"turn_seat_index": LOCAL_SEAT_INDEX,
		"turn_seconds": 15,
		"available_actions": _mock_available_actions(),
		"hand_history": [
			"Seat 2 raised to 150",
			"Seat 5 called 150",
			"Flop: A hearts 7 clubs K spades",
			"Your turn",
		],
		"system_messages": [
			"Connection: mock local table",
			"Phase keys: 1 preflop, 2 flop, 3 turn, 4 river, 5 showdown, R reset",
		],
	}

static func apply_mock_action(table_state: Dictionary, action: Dictionary) -> Dictionary:
	var normalized := action.duplicate(true)
	if not normalized.has("player_id"):
		normalized["player_id"] = "player_005"
	var next_state := TableStateReducerScript.apply_action(table_state, normalized)
	var action_id := String(normalized.get("id", ""))
	var amount := int(normalized.get("amount", normalized.get("min", 0)))
	var seats: Array = Array(next_state.get("seats", [])).duplicate(true)
	for i in seats.size():
		var seat := Dictionary(seats[i]).duplicate(true)
		if int(seat.get("seat_index", 0)) == LOCAL_SEAT_INDEX:
			if action_id == BettingActionScript.FOLD:
				seat["status"] = "folded"
				seat["is_turn"] = false
			elif action_id in [BettingActionScript.CALL, BettingActionScript.BET, BettingActionScript.RAISE, BettingActionScript.ALL_IN]:
				seat["current_bet"] = int(seat.get("current_bet", 0)) + max(amount, 0)
				seat["chips"] = max(int(seat.get("chips", 0)) - max(amount, 0), 0)
			seats[i] = seat
	next_state["seats"] = seats
	next_state["local_player"] = _local_player_from_seats(seats)
	next_state["pot_data"] = {"main": int(next_state.get("pot", 0)), "side_pots": []}
	var history: Array = Array(next_state.get("hand_history", [])).duplicate()
	history.append("Seat 5 %s" % action_id.replace("_", " "))
	next_state["hand_history"] = history
	return next_state

static func visual_position_for_seat_index(seat_index: int, local_seat_index: int = LOCAL_SEAT_INDEX) -> int:
	return ((seat_index - local_seat_index + 4 + 9) % 9) + 1

static func _normalize_phase(phase: String) -> String:
	var lowered := phase.to_lower()
	if lowered in ["preflop", "flop", "turn", "river", "showdown"]:
		return lowered
	return PokerPhaseScript.PREFLOP

static func _community_cards_for_phase(phase: String) -> Array[Dictionary]:
	var cards: Array[Dictionary] = [
		{"rank": "A", "suit": "hearts", "face_up": true},
		{"rank": "7", "suit": "clubs", "face_up": true},
		{"rank": "K", "suit": "spades", "face_up": true},
		{"rank": "T", "suit": "diamonds", "face_up": true},
		{"rank": "2", "suit": "hearts", "face_up": true},
	]
	match phase:
		"flop":
			return cards.slice(0, 3)
		"turn":
			return cards.slice(0, 4)
		"river", "showdown":
			return cards.slice(0, 5)
		_:
			return []

static func _mock_seats(phase: String) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for seat_index in range(1, 10):
		var is_local := seat_index == LOCAL_SEAT_INDEX
		var is_occupied := seat_index != 8
		var cards: Array[Dictionary] = []
		if is_occupied:
			if is_local or phase == "showdown":
				cards = _cards_for_seat(seat_index, true)
			else:
				cards = _cards_for_seat(seat_index, false)
		seats.append({
			"seat_index": seat_index,
			"visual_position": visual_position_for_seat_index(seat_index, LOCAL_SEAT_INDEX),
			"player_id": "player_%03d" % seat_index if is_occupied else "",
			"player_name": "Luna0581" if is_local else ("Seat %d" % seat_index if is_occupied else "Empty Seat"),
			"avatar": "",
			"chips": 24500 if is_local else 12000 + seat_index * 850,
			"current_bet": 50 if seat_index in [1, 5] else (25 if seat_index == 2 else 0),
			"status": "active" if is_occupied else "empty",
			"is_local": is_local,
			"is_dealer": seat_index == 1,
			"is_small_blind": seat_index == 2,
			"is_big_blind": seat_index == 3,
			"is_turn": is_local,
			"cards": cards,
		})
	return seats

static func _cards_for_seat(seat_index: int, face_up: bool) -> Array[Dictionary]:
	var ranks := ["A", "K", "Q", "J", "T", "9", "8", "7", "6"]
	var suits := ["spades", "hearts", "diamonds", "clubs"]
	return [
		{"rank": ranks[(seat_index - 1) % ranks.size()], "suit": suits[seat_index % suits.size()], "face_up": face_up},
		{"rank": ranks[seat_index % ranks.size()], "suit": suits[(seat_index + 1) % suits.size()], "face_up": face_up},
	]

static func _local_player_from_seats(seats: Array) -> Dictionary:
	for seat in seats:
		var data := Dictionary(seat)
		if bool(data.get("is_local", false)):
			return data.duplicate(true)
	return {}

static func _mock_available_actions() -> Array[Dictionary]:
	return [
		{"id": BettingActionScript.FOLD, "label": "Fold", "enabled": true},
		{"id": BettingActionScript.CHECK, "label": "Check", "enabled": false},
		{"id": BettingActionScript.CALL, "label": "Call 50", "enabled": true, "amount": 50},
		{"id": BettingActionScript.BET, "label": "Bet", "enabled": false, "min": 50, "max": 1000},
		{"id": BettingActionScript.RAISE, "label": "Raise", "enabled": true, "min": 100, "max": 1000},
		{"id": BettingActionScript.ALL_IN, "label": "All In", "enabled": true, "amount": 24500},
	]
