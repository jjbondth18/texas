extends RefCounted
class_name HandLifecycle

const DeckScript := preload("res://scripts/core/deck.gd")
const HandEvaluatorScript := preload("res://scripts/core/hand_evaluator.gd")

const PHASES := ["preflop", "flop", "turn", "river", "showdown", "finished"]
const ACTIONS := ["fold", "check", "call", "bet", "raise", "all_in"]

static func start_new_hand(table_state: Dictionary, seed: int = -1) -> Dictionary:
	var source := table_state.duplicate(true)
	var seats := _prepare_seats(Array(source.get("seats", _default_seats())))
	var active_indices := _active_seat_indices(seats)
	var previous_dealer := int(source.get("dealer_seat", active_indices[0] - 1))
	var dealer := _next_active_after(active_indices, previous_dealer)
	var small_blind := int(source.get("small_blind", 25))
	var big_blind := int(source.get("big_blind", 50))
	var sb_seat := _next_active_after(active_indices, dealer)
	var bb_seat := _next_active_after(active_indices, sb_seat)
	var first_turn := _next_active_after(active_indices, bb_seat)

	var deck := DeckScript.new()
	deck.shuffle(seed if seed != -1 else 0)
	var hand_number := int(source.get("hand_number", 0)) + 1
	var state := {
		"hand_id": "hand_%06d" % hand_number,
		"hand_number": hand_number,
		"phase": "preflop",
		"dealer_seat": dealer,
		"small_blind_seat": sb_seat,
		"big_blind_seat": bb_seat,
		"current_turn_seat": first_turn,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"current_bet": big_blind,
		"minimum_raise": big_blind,
		"pot": {"main": 0, "side_pots": []},
		"community_cards": [],
		"seats": seats,
		"deck": deck.cards.duplicate(true),
		"action_history": [],
		"events": [],
		"hand_complete": false,
		"winners": [],
		"last_error": "",
	}
	_append_event(state, "hand_started", -1, {"hand_number": hand_number})
	_append_event(state, "dealer_assigned", dealer, {})
	_post_blind(state, sb_seat, small_blind, "small_blind")
	_post_blind(state, bb_seat, big_blind, "big_blind")
	_deal_hole_cards(state)
	_append_event(state, "turn_started", first_turn, {})
	state["available_actions"] = get_legal_actions(state, first_turn)
	return state

static func get_legal_actions(state: Dictionary, seat_index: int) -> Array[Dictionary]:
	var seat := _seat_by_index(Array(state.get("seats", [])), seat_index)
	if seat.is_empty() or int(state.get("current_turn_seat", -1)) != seat_index:
		return []
	if String(seat.get("status", "")) not in ["active"]:
		return []
	var to_call: int = max(int(state.get("current_bet", 0)) - int(seat.get("street_bet", 0)), 0)
	var chips := int(seat.get("chips", 0))
	var actions: Array[Dictionary] = [{"id": "fold", "label": "Fold", "enabled": true}]
	actions.append({"id": "check", "label": "Check", "enabled": to_call == 0})
	if to_call > 0:
		actions.append({"id": "call", "label": "Call %d" % min(to_call, chips), "enabled": chips > 0, "amount": min(to_call, chips)})
	else:
		actions.append({"id": "call", "label": "Call", "enabled": false, "amount": 0})
	var current_bet := int(state.get("current_bet", 0))
	var min_raise := int(state.get("minimum_raise", int(state.get("big_blind", 50))))
	actions.append({"id": "bet", "label": "Bet", "enabled": current_bet == 0 and chips > 0, "min": min_raise, "max": chips})
	actions.append({"id": "raise", "label": "Raise", "enabled": current_bet > 0 and chips > to_call, "min": current_bet + min_raise, "max": int(seat.get("street_bet", 0)) + chips})
	actions.append({"id": "all_in", "label": "All In", "enabled": chips > 0, "amount": chips})
	return actions

static func apply_action(state: Dictionary, action: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var seat_index := int(action.get("seat_index", next.get("current_turn_seat", -1)))
	var action_id := String(action.get("id", ""))
	if not bool(action.get("enabled", true)):
		return _reject(next, seat_index, action_id, "disabled_action")
	var legality := _validate_action(next, seat_index, action)
	if not bool(legality.get("ok", false)):
		return _reject(next, seat_index, action_id, String(legality.get("reason", "illegal_action")))

	var seats := Array(next["seats"])
	var seat_pos := _seat_position(seats, seat_index)
	var seat := Dictionary(seats[seat_pos]).duplicate(true)
	var amount := int(legality.get("amount", 0))
	match action_id:
		"fold":
			seat["status"] = "folded"
		"check":
			pass
		"call", "bet", "raise", "all_in":
			_commit_chips(seat, amount)
			if action_id == "all_in" or int(seat.get("chips", 0)) == 0:
				seat["status"] = "all_in"
			if action_id in ["bet", "raise", "all_in"]:
				var old_bet := int(next.get("current_bet", 0))
				var new_bet := int(seat.get("street_bet", 0))
				if new_bet > old_bet:
					next["minimum_raise"] = max(new_bet - old_bet, int(next.get("minimum_raise", 0)))
					next["current_bet"] = new_bet
					_clear_acted_after_raise(seats)
	seat["has_acted"] = true
	seats[seat_pos] = seat
	next["seats"] = seats
	next["pot"] = _build_pots(seats)
	var normalized := {"id": action_id, "seat_index": seat_index, "amount": amount}
	var history: Array = Array(next.get("action_history", [])).duplicate(true)
	history.append(normalized)
	next["action_history"] = history
	_append_event(next, "player_action", seat_index, normalized)

	if _non_folded_seats(seats).size() == 1:
		_finish_by_fold(next)
		return next
	if _betting_round_complete(next):
		_complete_street(next)
	else:
		next["current_turn_seat"] = _next_actor(next, seat_index)
		_append_event(next, "turn_started", int(next["current_turn_seat"]), {})
	next["available_actions"] = get_legal_actions(next, int(next.get("current_turn_seat", -1)))
	return next

static func build_public_snapshot(state: Dictionary) -> Dictionary:
	var snap := state.duplicate(true)
	var phase := String(snap.get("phase", ""))
	var reveal := phase in ["showdown", "finished"] and bool(snap.get("showdown_revealed", false))
	var public_seats: Array[Dictionary] = []
	for seat in Array(snap.get("seats", [])):
		var data := Dictionary(seat).duplicate(true)
		if not reveal:
			var hidden: Array[Dictionary] = []
			for _card in Array(data.get("cards", [])):
				hidden.append({"rank": "", "suit": "", "code": "", "face_up": false})
			data["cards"] = hidden
		public_seats.append(data)
	snap["seats"] = public_seats
	snap.erase("deck")
	return snap

static func build_private_snapshot(state: Dictionary, player_id: String) -> Dictionary:
	var snap := build_public_snapshot(state)
	var source_seats := Array(state.get("seats", []))
	var seats := Array(snap.get("seats", []))
	for i in seats.size():
		var public_seat := Dictionary(seats[i]).duplicate(true)
		var source_seat := Dictionary(source_seats[i])
		if String(source_seat.get("player_id", "")) == player_id:
			var own_cards: Array[Dictionary] = []
			for card in Array(source_seat.get("cards", [])):
				var face := Dictionary(card).duplicate(true)
				face["face_up"] = true
				own_cards.append(face)
			public_seat["cards"] = own_cards
			seats[i] = public_seat
	snap["seats"] = seats
	return snap

static func compare_card_sets(cards_a: Array, cards_b: Array) -> int:
	return _compare_evaluations(HandEvaluatorScript.evaluate(cards_a), HandEvaluatorScript.evaluate(cards_b))

static func _validate_action(state: Dictionary, seat_index: int, action: Dictionary) -> Dictionary:
	var action_id := String(action.get("id", ""))
	if not ACTIONS.has(action_id):
		return {"ok": false, "reason": "unknown_action"}
	if int(state.get("current_turn_seat", -1)) != seat_index:
		return {"ok": false, "reason": "not_players_turn"}
	var seat := _seat_by_index(Array(state.get("seats", [])), seat_index)
	if seat.is_empty() or String(seat.get("status", "")) != "active":
		return {"ok": false, "reason": "seat_cannot_act"}
	var to_call: int = max(int(state.get("current_bet", 0)) - int(seat.get("street_bet", 0)), 0)
	var chips := int(seat.get("chips", 0))
	match action_id:
		"fold":
			return {"ok": true, "amount": 0}
		"check":
			return {"ok": to_call == 0, "reason": "facing_bet", "amount": 0}
		"call":
			return {"ok": to_call > 0 and chips > 0, "reason": "nothing_to_call", "amount": min(to_call, chips)}
		"bet":
			var bet_amount := int(action.get("amount", action.get("min", 0)))
			return {"ok": int(state.get("current_bet", 0)) == 0 and bet_amount > 0 and bet_amount <= chips, "reason": "invalid_bet", "amount": bet_amount}
		"raise":
			var target_total := int(action.get("amount", action.get("min", 0)))
			var min_total := int(state.get("current_bet", 0)) + int(state.get("minimum_raise", 0))
			var max_total := int(seat.get("street_bet", 0)) + chips
			return {"ok": target_total >= min_total and target_total <= max_total, "reason": "invalid_raise", "amount": target_total - int(seat.get("street_bet", 0))}
		"all_in":
			return {"ok": chips > 0, "amount": chips}
	return {"ok": false, "reason": "unhandled_action"}

static func _reject(state: Dictionary, seat_index: int, action_id: String, reason: String) -> Dictionary:
	state["last_error"] = reason
	_append_event(state, "action_rejected", seat_index, {"action": action_id, "reason": reason})
	return state

static func _prepare_seats(input_seats: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in input_seats.size():
		var seat := Dictionary(input_seats[i]).duplicate(true)
		if not seat.has("seat_index"):
			seat["seat_index"] = i + 1
		if not seat.has("player_id"):
			seat["player_id"] = "player_%03d" % int(seat["seat_index"])
		if not seat.has("player_name"):
			seat["player_name"] = "Seat %d" % int(seat["seat_index"])
		seat["status"] = "active" if String(seat.get("status", "active")) != "empty" else "empty"
		seat["chips"] = int(seat.get("chips", 10000))
		seat["street_bet"] = 0
		seat["committed"] = 0
		seat["current_bet"] = 0
		seat["cards"] = []
		seat["has_acted"] = false
		seat["is_turn"] = false
		result.append(seat)
	return result

static func _default_seats() -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for i in range(1, 10):
		seats.append({"seat_index": i, "player_id": "player_%03d" % i, "player_name": "Seat %d" % i, "chips": 10000, "status": "active", "is_local": i == 5})
	return seats

static func _post_blind(state: Dictionary, seat_index: int, amount: int, blind_type: String) -> void:
	var seats := Array(state["seats"])
	var pos := _seat_position(seats, seat_index)
	var seat := Dictionary(seats[pos]).duplicate(true)
	_commit_chips(seat, min(amount, int(seat.get("chips", 0))))
	seat["has_acted"] = false
	seats[pos] = seat
	state["seats"] = seats
	state["pot"] = _build_pots(seats)
	_append_event(state, "blind_posted", seat_index, {"blind": blind_type, "amount": amount})

static func _deal_hole_cards(state: Dictionary) -> void:
	var deck := Array(state["deck"])
	var seats := Array(state["seats"])
	for round_i in range(2):
		for i in seats.size():
			var seat := Dictionary(seats[i]).duplicate(true)
			if String(seat.get("status", "")) == "empty":
				continue
			var card := Dictionary(deck.pop_front()).duplicate(true)
			card["face_up"] = false
			var cards := Array(seat.get("cards", [])).duplicate(true)
			cards.append(card)
			seat["cards"] = cards
			seats[i] = seat
	state["deck"] = deck
	state["seats"] = seats
	_append_event(state, "hole_cards_dealt", -1, {"private": true, "players": _active_seat_indices(seats)})

static func _complete_street(state: Dictionary) -> void:
	_append_event(state, "street_completed", int(state.get("current_turn_seat", -1)), {"phase": state.get("phase", "")})
	var seats := Array(state["seats"])
	for i in seats.size():
		var seat := Dictionary(seats[i]).duplicate(true)
		seat["street_bet"] = 0
		seat["current_bet"] = 0
		seat["has_acted"] = false
		seats[i] = seat
	state["seats"] = seats
	state["current_bet"] = 0
	state["minimum_raise"] = int(state.get("big_blind", 50))
	var phase := String(state.get("phase", "preflop"))
	match phase:
		"preflop":
			state["phase"] = "flop"
			_deal_community(state, 3)
		"flop":
			state["phase"] = "turn"
			_deal_community(state, 1)
		"turn":
			state["phase"] = "river"
			_deal_community(state, 1)
		"river":
			state["phase"] = "showdown"
			_showdown(state)
			return
	_append_event(state, "street_started", -1, {"phase": state["phase"]})
	var first := _first_postflop_actor(state)
	state["current_turn_seat"] = first
	_append_event(state, "turn_started", first, {})

static func _deal_community(state: Dictionary, count: int) -> void:
	var deck := Array(state["deck"])
	var board := Array(state.get("community_cards", [])).duplicate(true)
	for i in range(count):
		var card := Dictionary(deck.pop_front()).duplicate(true)
		card["face_up"] = true
		board.append(card)
	state["deck"] = deck
	state["community_cards"] = board
	_append_event(state, "community_cards_dealt", -1, {"count": count, "total": board.size()})

static func _showdown(state: Dictionary) -> void:
	_append_event(state, "showdown_started", -1, {})
	state["showdown_revealed"] = true
	_append_event(state, "cards_revealed", -1, {"public": true})
	var board_codes := _card_codes(Array(state.get("community_cards", [])))
	var best_seats: Array[int] = []
	var best_eval := {}
	for seat in _non_folded_seats(Array(state.get("seats", []))):
		var data := Dictionary(seat)
		var eval := HandEvaluatorScript.evaluate(_card_codes(Array(data.get("cards", []))) + board_codes)
		if best_eval.is_empty() or _compare_evaluations(eval, best_eval) > 0:
			best_eval = eval
			best_seats = [int(data.get("seat_index", -1))]
		elif _compare_evaluations(eval, best_eval) == 0:
			best_seats.append(int(data.get("seat_index", -1)))
	_append_event(state, "winner_determined", best_seats[0] if not best_seats.is_empty() else -1, {"winners": best_seats, "hand_rank": best_eval.get("rank", "")})
	_award_pot(state, best_seats, "showdown")

static func _finish_by_fold(state: Dictionary) -> void:
	var winner := int(Dictionary(_non_folded_seats(Array(state.get("seats", [])))[0]).get("seat_index", -1))
	_append_event(state, "hand_won_by_fold", winner, {})
	_award_pot(state, [winner], "fold")

static func _award_pot(state: Dictionary, winner_seats: Array, reason: String) -> void:
	var total := int(Dictionary(state.get("pot", {})).get("main", 0))
	if winner_seats.is_empty():
		return
	var share := total / winner_seats.size()
	var odd := total % winner_seats.size()
	var seats := Array(state["seats"])
	for i in seats.size():
		var seat := Dictionary(seats[i]).duplicate(true)
		var winner_pos := winner_seats.find(int(seat.get("seat_index", -1)))
		if winner_pos != -1:
			seat["chips"] = int(seat.get("chips", 0)) + share + (1 if winner_pos == 0 and odd > 0 else 0)
		seats[i] = seat
	state["seats"] = seats
	state["winners"] = winner_seats.duplicate()
	state["hand_complete"] = true
	state["phase"] = "finished"
	state["current_turn_seat"] = -1
	state["available_actions"] = []
	_append_event(state, "pot_awarded", winner_seats[0], {"amount": total, "winners": winner_seats, "reason": reason, "odd_chip_rule": "lowest winner order receives odd chip"})
	_append_event(state, "hand_finished", -1, {"reason": reason})

static func _commit_chips(seat: Dictionary, amount: int) -> void:
	var paid: int = min(max(amount, 0), int(seat.get("chips", 0)))
	seat["chips"] = int(seat.get("chips", 0)) - paid
	seat["street_bet"] = int(seat.get("street_bet", 0)) + paid
	seat["current_bet"] = int(seat.get("street_bet", 0))
	seat["committed"] = int(seat.get("committed", 0)) + paid

static func _build_pots(seats: Array) -> Dictionary:
	var total := 0
	for seat in seats:
		total += int(Dictionary(seat).get("committed", 0))
	return {"main": total, "side_pots": build_side_pots(seats)}

static func build_side_pots(seats: Array) -> Array[Dictionary]:
	var levels: Array[int] = []
	for seat in seats:
		var committed := int(Dictionary(seat).get("committed", 0))
		if committed > 0 and not levels.has(committed):
			levels.append(committed)
	levels.sort()
	var pots: Array[Dictionary] = []
	var previous := 0
	for level in levels:
		var eligible: Array[int] = []
		var amount := 0
		for seat in seats:
			var data := Dictionary(seat)
			var committed := int(data.get("committed", 0))
			if committed >= level:
				amount += level - previous
				if String(data.get("status", "")) != "folded":
					eligible.append(int(data.get("seat_index", -1)))
		if amount > 0:
			pots.append({"amount": amount, "eligible_seats": eligible})
		previous = level
	if pots.size() <= 1:
		return []
	return pots.slice(1)

static func _betting_round_complete(state: Dictionary) -> bool:
	var current_bet := int(state.get("current_bet", 0))
	for seat in Array(state.get("seats", [])):
		var data := Dictionary(seat)
		if String(data.get("status", "")) != "active":
			continue
		if not bool(data.get("has_acted", false)):
			return false
		if int(data.get("street_bet", 0)) < current_bet:
			return false
	return true

static func _next_actor(state: Dictionary, after_seat: int) -> int:
	var active := _actionable_seat_indices(Array(state.get("seats", [])))
	return _next_active_after(active, after_seat)

static func _first_postflop_actor(state: Dictionary) -> int:
	return _next_active_after(_actionable_seat_indices(Array(state.get("seats", []))), int(state.get("dealer_seat", 1)))

static func _active_seat_indices(seats: Array) -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data := Dictionary(seat)
		if String(data.get("status", "")) != "empty":
			result.append(int(data.get("seat_index", -1)))
	result.sort()
	return result

static func _actionable_seat_indices(seats: Array) -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data := Dictionary(seat)
		if String(data.get("status", "")) == "active":
			result.append(int(data.get("seat_index", -1)))
	result.sort()
	return result

static func _non_folded_seats(seats: Array) -> Array:
	var result: Array = []
	for seat in seats:
		var data := Dictionary(seat)
		if String(data.get("status", "")) not in ["empty", "folded"]:
			result.append(data)
	return result

static func _next_active_after(active_indices: Array, after_seat: int) -> int:
	if active_indices.is_empty():
		return -1
	var sorted := active_indices.duplicate()
	sorted.sort()
	for index in sorted:
		if int(index) > after_seat:
			return int(index)
	return int(sorted[0])

static func _seat_by_index(seats: Array, seat_index: int) -> Dictionary:
	var pos := _seat_position(seats, seat_index)
	if pos == -1:
		return {}
	return Dictionary(seats[pos])

static func _seat_position(seats: Array, seat_index: int) -> int:
	for i in seats.size():
		if int(Dictionary(seats[i]).get("seat_index", -1)) == seat_index:
			return i
	return -1

static func _clear_acted_after_raise(seats: Array) -> void:
	for i in seats.size():
		var seat := Dictionary(seats[i]).duplicate(true)
		if String(seat.get("status", "")) == "active":
			seat["has_acted"] = false
			seats[i] = seat

static func _append_event(state: Dictionary, event_type: String, seat_index: int, payload: Dictionary) -> void:
	var events := Array(state.get("events", [])).duplicate(true)
	var seat := _seat_by_index(Array(state.get("seats", [])), seat_index)
	events.append({
		"event_index": events.size(),
		"hand_id": String(state.get("hand_id", "")),
		"type": event_type,
		"phase": String(state.get("phase", "")),
		"seat_index": seat_index,
		"player_id": String(seat.get("player_id", "")),
		"payload": payload.duplicate(true),
	})
	state["events"] = events

static func _card_codes(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		result.append(String(Dictionary(card).get("code", "")))
	return result

static func _compare_evaluations(a: Dictionary, b: Dictionary) -> int:
	var rank_delta := int(a.get("rank_value", 0)) - int(b.get("rank_value", 0))
	if rank_delta != 0:
		return sign(rank_delta)
	var a_cards := Array(a.get("cards", []))
	var b_cards := Array(b.get("cards", []))
	for i in range(min(a_cards.size(), b_cards.size())):
		var delta := _rank_value(String(a_cards[i])) - _rank_value(String(b_cards[i]))
		if delta != 0:
			return sign(delta)
	return 0

static func _rank_value(code: String) -> int:
	return int(HandEvaluatorScript.RANK_VALUES.get(code.substr(0, 1), 0))
