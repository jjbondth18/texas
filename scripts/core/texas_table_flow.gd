extends RefCounted
class_name TexasTableFlow

const CoreDeckScript := preload("res://scripts/core/deck.gd")
const TableStateScript := preload("res://scripts/data/table_state.gd")
const TableSeatScript := preload("res://scripts/data/table_seat.gd")
const HandEvaluatorScript := preload("res://scripts/core/hand_evaluator.gd")

const WAITING := TableStateScript.WAITING
const HAND_STARTING := TableStateScript.HAND_STARTING
const PREFLOP := TableStateScript.PREFLOP
const FLOP := TableStateScript.FLOP
const TURN := TableStateScript.TURN
const RIVER := TableStateScript.RIVER
const SHOWDOWN := TableStateScript.SHOWDOWN
const HAND_OVER := TableStateScript.HAND_OVER

const EMPTY := TableSeatScript.EMPTY
const SITTING := TableSeatScript.SITTING
const PLAYING := TableSeatScript.PLAYING
const FOLDED := TableSeatScript.FOLDED
const ALL_IN := TableSeatScript.ALL_IN
const OUT := TableSeatScript.OUT

var table_state: String = WAITING
var seats: Array[Dictionary] = []
var hand_data: Dictionary = {}
var table_log: Array[String] = []
var rule_debug_log: Array[String] = []

var small_blind: int = 25
var big_blind: int = 50
var _configured_seats: Array[Dictionary] = []
var _hand_number: int = 0
var _last_dealer_seat: int = 0
var _visual_event_number: int = 0


func configure_from_launch_context(context: Dictionary) -> void:
	small_blind = int(context.get("small_blind", small_blind))
	big_blind = int(context.get("big_blind", big_blind))
	_configured_seats.clear()
	for seat in Array(context.get("seats", [])):
		_configured_seats.append(Dictionary(seat).duplicate(true))


func reset_table() -> Dictionary:
	table_state = WAITING
	seats = _configured_seats.duplicate(true) if not _configured_seats.is_empty() else _mock_player_seats()
	hand_data = _empty_hand_data()
	table_log.clear()
	rule_debug_log.clear()
	_log("Table reset. Waiting for players.")
	return to_snapshot()


func can_start_hand() -> bool:
	return table_state in [WAITING, HAND_OVER] and eligible_next_hand_seat_ids().size() >= 2


func eligible_next_hand_seat_ids() -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data: Dictionary = seat
		if _is_eligible_for_next_hand(data):
			result.append(int(data.get("seat_id", data.get("seat_index", 0))))
	return result


func next_hand_eligibility_report() -> Array[String]:
	var lines: Array[String] = []
	var eligible: Array[int] = eligible_next_hand_seat_ids()
	lines.append("eligible_players=%d seats=%s" % [eligible.size(), str(eligible)])
	for seat in seats:
		var data: Dictionary = seat
		var seat_id: int = int(data.get("seat_id", data.get("seat_index", 0)))
		var status: String = String(data.get("status", EMPTY))
		var chips: int = int(data.get("chips", 0))
		var sitting_out: bool = bool(data.get("is_sitting_out", false))
		var reason: String = "included" if _is_eligible_for_next_hand(data) else _next_hand_exclusion_reason(data)
		lines.append("Seat %d: chips=%d status=%s sitting_out=%s %s" % [
			seat_id,
			chips,
			status,
			str(sitting_out),
			reason,
		])
	return lines


func start_new_hand(seed: int = 0) -> Dictionary:
	if seats.is_empty():
		reset_table()
	if not can_start_hand():
		_log_start_hand_blocked()
		return to_snapshot()

	table_state = HAND_STARTING
	_hand_number += 1
	hand_data = _empty_hand_data()
	hand_data["hand_id"] = "hand_%06d" % _hand_number
	_log("Starting hand #%d." % _hand_number)

	for i in seats.size():
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		seat["current_bet"] = 0
		seat["hole_cards"] = []
		seat["last_action"] = ""
		seat["last_action_amount"] = 0
		seat["last_action_seq"] = 0
		seat["has_acted"] = false
		seat["is_dealer"] = false
		seat["is_small_blind"] = false
		seat["is_big_blind"] = false
		if _is_eligible_for_next_hand(seat):
			seat["status"] = PLAYING
		elif String(seat.get("status", EMPTY)) != EMPTY:
			seat["status"] = OUT
		seats[i] = seat

	assign_dealer_blinds()
	shuffle_deck(seed)
	post_blinds()
	deal_hole_cards()
	begin_betting_round(PREFLOP)
	return to_snapshot()


func assign_dealer_blinds() -> void:
	var active_ids: Array[int] = _active_seat_ids()
	if active_ids.size() < 2:
		return
	var dealer: int = get_next_active_seat(_last_dealer_seat)
	var small_blind_seat: int = get_next_active_seat(dealer)
	var big_blind_seat: int = get_next_active_seat(small_blind_seat)
	_last_dealer_seat = dealer
	hand_data["dealer_seat"] = dealer
	hand_data["small_blind_seat"] = small_blind_seat
	hand_data["big_blind_seat"] = big_blind_seat
	for i in seats.size():
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		seat["is_dealer"] = seat_id == dealer
		seat["is_small_blind"] = seat_id == small_blind_seat
		seat["is_big_blind"] = seat_id == big_blind_seat
		seats[i] = seat
	_log("Dealer Seat %d. SB Seat %d. BB Seat %d." % [dealer, small_blind_seat, big_blind_seat])


func post_blinds() -> void:
	_post_blind(int(hand_data.get("small_blind_seat", -1)), small_blind, "small blind")
	_post_blind(int(hand_data.get("big_blind_seat", -1)), big_blind, "big blind")
	hand_data["current_bet"] = big_blind
	hand_data["pot"] = _calculate_pot()


func shuffle_deck(seed: int = 0) -> void:
	var deck = CoreDeckScript.new()
	deck.shuffle(seed)
	hand_data["deck"] = deck.cards.duplicate(true)
	_log("Deck shuffled.")


func deal_hole_cards() -> void:
	var deck: Array = Array(hand_data.get("deck", [])).duplicate(true)
	for round_index in range(2):
		for i in seats.size():
			var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
			if String(seat.get("status", EMPTY)) != PLAYING:
				continue
			if deck.is_empty():
				break
			var cards: Array = Array(seat.get("hole_cards", [])).duplicate(true)
			cards.append(Dictionary(deck.pop_front()).duplicate(true))
			seat["hole_cards"] = cards
			seats[i] = seat
			_add_visual_event("deal_hole", int(seat.get("seat_id", seat.get("seat_index", 0))), "", 0, {"card_index": round_index})
	hand_data["deck"] = deck
	_log("Hole cards dealt to %d players." % _active_seat_ids().size())


func begin_betting_round(stage: String) -> void:
	table_state = stage
	hand_data["stage"] = stage
	hand_data["acted_this_round"] = []
	hand_data["last_raiser_seat"] = int(hand_data.get("big_blind_seat", -1)) if stage == PREFLOP else -1
	if stage != PREFLOP:
		hand_data["current_bet"] = 0
		for i in seats.size():
			var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
			seat["current_bet"] = 0
			seats[i] = seat
	var from_seat: int = int(hand_data.get("big_blind_seat", -1)) if stage == PREFLOP else int(hand_data.get("dealer_seat", -1))
	hand_data["current_turn_seat"] = get_next_actionable_seat(from_seat)
	_log("%s betting round started. Turn: Seat %d." % [stage.to_upper(), int(hand_data.get("current_turn_seat", -1))])
	_debug_rule("stage=%s current_turn=%d current_bet=%d pot=%d" % [
		stage.to_upper(),
		int(hand_data.get("current_turn_seat", -1)),
		int(hand_data.get("current_bet", 0)),
		int(hand_data.get("pot", 0)),
	])
	if _should_auto_runout_all_in():
		_debug_rule("stage=%s has no actionable players; auto runout" % stage.to_upper())
		_auto_runout_to_showdown()


func get_next_active_seat(from_seat: int) -> int:
	var ids: Array[int] = _active_seat_ids()
	if ids.is_empty():
		return -1
	ids.sort()
	for seat_id in ids:
		if seat_id > from_seat:
			return seat_id
	return ids[0]


func get_next_actionable_seat(from_seat: int) -> int:
	var ids: Array[int] = _players_who_can_act_ids()
	if ids.is_empty():
		return -1
	ids.sort()
	for seat_id in ids:
		if seat_id > from_seat:
			return seat_id
	return ids[0]


func get_seat_data(seat_id: int) -> Dictionary:
	return _seat_by_id(seat_id).duplicate(true)


func advance_turn() -> Dictionary:
	var current: int = int(hand_data.get("current_turn_seat", -1))
	if current == -1:
		return to_snapshot()
	var acted: Array = Array(hand_data.get("acted_this_round", [])).duplicate()
	if not acted.has(current):
		acted.append(current)
	hand_data["acted_this_round"] = acted
	if _should_auto_runout_all_in():
		_debug_rule("betting round complete: all remaining contenders are all-in")
		_auto_runout_to_showdown()
		return to_snapshot()
	if is_betting_round_complete():
		_debug_rule("betting round complete: %s" % _betting_round_completion_reason())
		advance_stage()
	else:
		hand_data["current_turn_seat"] = get_next_actionable_seat(current)
		_log("Turn advanced to Seat %d." % int(hand_data.get("current_turn_seat", -1)))
	return to_snapshot()


func get_legal_actions(seat_id: int) -> Array[Dictionary]:
	if int(hand_data.get("current_turn_seat", -1)) != seat_id:
		return []
	var seat: Dictionary = _seat_by_id(seat_id)
	if seat.is_empty() or String(seat.get("status", EMPTY)) != PLAYING:
		return []
	var current_bet: int = int(hand_data.get("current_bet", 0))
	var player_bet: int = int(seat.get("current_bet", 0))
	var chips: int = int(seat.get("chips", 0))
	var call_amount: int = max(current_bet - player_bet, 0)
	var actions: Array[Dictionary] = [
		{"id": "fold", "label": "Fold", "enabled": true},
	]
	if call_amount == 0:
		actions.append({"id": "check", "label": "Check", "enabled": true, "amount": 0})
	else:
		actions.append({"id": "call", "label": "Call %d" % min(call_amount, chips), "enabled": chips > 0, "amount": min(call_amount, chips)})
	var raise_id: String = "bet" if current_bet == 0 else "raise"
	var min_raise_total: int = max(current_bet + big_blind, big_blind)
	var max_raise_total: int = player_bet + chips
	actions.append({
		"id": raise_id,
		"label": "Bet" if raise_id == "bet" else "Raise",
		"enabled": chips > call_amount and max_raise_total > current_bet,
		"min_amount": min(min_raise_total, max_raise_total),
		"max_amount": max_raise_total,
	})
	actions.append({"id": "all_in", "label": "All In", "enabled": chips > 0, "amount": chips})
	return actions


func force_current_hand_to_showdown() -> Dictionary:
	if table_state in [WAITING, HAND_OVER]:
		return to_snapshot()
	_log("Debug: force current hand to showdown.")
	_auto_runout_to_showdown()
	return to_snapshot()


func apply_player_action(seat_id: int, action: Dictionary) -> Dictionary:
	if int(hand_data.get("current_turn_seat", -1)) != seat_id:
		_log("Ignored action from Seat %d: not current turn." % seat_id)
		return to_snapshot()
	var action_id: String = String(action.get("id", ""))
	var seat_index: int = _seat_array_index(seat_id)
	if seat_index == -1:
		_log("Ignored action from missing Seat %d." % seat_id)
		return to_snapshot()
	var seat: Dictionary = Dictionary(seats[seat_index]).duplicate(true)
	if String(seat.get("status", EMPTY)) != PLAYING:
		_log("Ignored action from Seat %d: status %s." % [seat_id, String(seat.get("status", EMPTY))])
		return to_snapshot()
	var pot_before: int = int(hand_data.get("pot", 0))
	var current_bet_before: int = int(hand_data.get("current_bet", 0))
	var player_bet_before: int = int(seat.get("current_bet", 0))
	var call_amount_before: int = max(current_bet_before - player_bet_before, 0)
	match action_id:
		"fold":
			seat["status"] = FOLDED
			_set_last_action(seat, "FOLD", 0)
			seats[seat_index] = seat
			_log("%s folds." % _seat_display_name(seat))
			_debug_action(seat_id, "FOLD", call_amount_before, -1, pot_before, current_bet_before)
			_add_visual_event("player_action", seat_id, "FOLD", 0)
			if _active_seat_ids().size() <= 1:
				finish_hand()
				return to_snapshot()
			return advance_turn()
		"check":
			var to_check_call: int = max(int(hand_data.get("current_bet", 0)) - int(seat.get("current_bet", 0)), 0)
			if to_check_call != 0:
				_log("%s cannot check while facing %d." % [_seat_display_name(seat), to_check_call])
				return to_snapshot()
			_set_last_action(seat, "CHECK", 0)
			seats[seat_index] = seat
			_log("%s checks." % _seat_display_name(seat))
			_debug_action(seat_id, "CHECK", to_check_call, -1, pot_before, current_bet_before)
			_add_visual_event("player_action", seat_id, "CHECK", 0)
			return advance_turn()
		"call":
			var call_amount: int = max(int(hand_data.get("current_bet", 0)) - int(seat.get("current_bet", 0)), 0)
			var paid_call: int = _commit_to_pot(seat, call_amount)
			_set_last_action(seat, "CALL", paid_call)
			seats[seat_index] = seat
			_log("%s calls %d." % [_seat_display_name(seat), paid_call])
			_debug_action(seat_id, "CALL", call_amount, -1, pot_before, current_bet_before)
			_add_visual_event("player_action", seat_id, "CALL", paid_call)
			_add_visual_event("chip_move", seat_id, "CALL", paid_call)
			return advance_turn()
		"bet", "raise":
			var target_total: int = int(action.get("amount", action.get("min_amount", 0)))
			if target_total <= int(hand_data.get("current_bet", 0)):
				_log("%s %s rejected: target %d must exceed current bet %d." % [_seat_display_name(seat), action_id, target_total, int(hand_data.get("current_bet", 0))])
				return to_snapshot()
			var raise_delta: int = target_total - int(seat.get("current_bet", 0))
			var paid_raise: int = _commit_to_pot(seat, raise_delta)
			hand_data["current_bet"] = int(seat.get("current_bet", 0))
			hand_data["last_raiser_seat"] = seat_id
			hand_data["acted_this_round"] = [seat_id]
			_set_last_action(seat, "BET" if action_id == "bet" else "RAISE", int(hand_data.get("current_bet", 0)))
			seats[seat_index] = seat
			_log("%s %s to %d." % [_seat_display_name(seat), "bets" if action_id == "bet" else "raises", int(hand_data.get("current_bet", 0))])
			_debug_action(seat_id, action_id.to_upper(), call_amount_before, target_total, pot_before, current_bet_before)
			_add_visual_event("player_action", seat_id, "BET" if action_id == "bet" else "RAISE", int(hand_data.get("current_bet", 0)))
			_add_visual_event("chip_move", seat_id, action_id.to_upper(), paid_raise)
			return advance_turn()
		"all_in":
			var previous_bet: int = int(hand_data.get("current_bet", 0))
			var all_in_amount: int = int(seat.get("chips", 0))
			var paid_all_in: int = _commit_to_pot(seat, all_in_amount)
			seats[seat_index] = seat
			if int(seat.get("current_bet", 0)) > previous_bet:
				hand_data["current_bet"] = int(seat.get("current_bet", 0))
				hand_data["last_raiser_seat"] = seat_id
				hand_data["acted_this_round"] = [seat_id]
			_set_last_action(seat, "ALL-IN", paid_all_in)
			_log("%s is all-in for %d." % [_seat_display_name(seat), paid_all_in])
			_debug_action(seat_id, "ALL-IN", call_amount_before, int(seat.get("current_bet", 0)), pot_before, current_bet_before)
			_add_visual_event("player_action", seat_id, "ALL-IN", paid_all_in)
			_add_visual_event("chip_move", seat_id, "ALL-IN", paid_all_in)
			return advance_turn()
	_log("Unsupported action: %s." % action_id)
	return to_snapshot()


func is_betting_round_complete() -> bool:
	if _should_auto_runout_all_in():
		return true
	var active_ids: Array[int] = _active_seat_ids()
	var acted: Array = Array(hand_data.get("acted_this_round", []))
	var current_bet: int = int(hand_data.get("current_bet", 0))
	for seat_id in active_ids:
		var seat: Dictionary = _seat_by_id(seat_id)
		if String(seat.get("status", PLAYING)) == ALL_IN:
			continue
		if not acted.has(seat_id):
			return false
		if int(seat.get("current_bet", 0)) < current_bet and String(seat.get("status", PLAYING)) == PLAYING:
			return false
	return true


func _betting_round_completion_reason() -> String:
	var active_ids: Array[int] = _active_seat_ids()
	if active_ids.size() <= 1:
		return "only one active player remains"
	var acted: Array = Array(hand_data.get("acted_this_round", []))
	var current_bet: int = int(hand_data.get("current_bet", 0))
	for seat_id in active_ids:
		var seat: Dictionary = _seat_by_id(seat_id)
		if String(seat.get("status", PLAYING)) == ALL_IN:
			continue
		if not acted.has(seat_id):
			return "not complete; Seat %d has not acted" % seat_id
		if int(seat.get("current_bet", 0)) < current_bet and String(seat.get("status", PLAYING)) == PLAYING:
			return "not complete; Seat %d bet %d below current_bet %d" % [seat_id, int(seat.get("current_bet", 0)), current_bet]
	return "all active players acted and matched current_bet %d" % current_bet


func advance_stage() -> Dictionary:
	match table_state:
		PREFLOP:
			_add_collect_bets_event()
			_clear_betting_round_state(false)
			_deal_community_cards(3)
			begin_betting_round(FLOP)
		FLOP:
			_add_collect_bets_event()
			_clear_betting_round_state(false)
			_deal_community_cards(1)
			begin_betting_round(TURN)
		TURN:
			_add_collect_bets_event()
			_clear_betting_round_state(false)
			_deal_community_cards(1)
			begin_betting_round(RIVER)
		RIVER:
			_add_collect_bets_event()
			_clear_betting_round_state(true)
			table_state = SHOWDOWN
			hand_data["stage"] = SHOWDOWN
			_log("Showdown started.")
			_debug_rule("stage=SHOWDOWN pot=%d current_bet=%d" % [int(hand_data.get("pot", 0)), int(hand_data.get("current_bet", 0))])
			finish_hand()
		SHOWDOWN:
			finish_hand()
	return to_snapshot()


func _auto_runout_to_showdown() -> void:
	if table_state == HAND_OVER:
		return
	_log("All players all-in. Running out board.")
	if _all_in_amounts_are_unequal():
		_debug_rule("WARNING: side pot not implemented, using simplified pot settlement.")
	_add_collect_bets_event()
	_clear_betting_round_state(true)
	_runout_board_to_five_cards()
	table_state = SHOWDOWN
	hand_data["stage"] = SHOWDOWN
	hand_data["current_turn_seat"] = -1
	_log("Showdown started.")
	_debug_rule("all-in runout complete board=%d pot=%d" % [
		Array(hand_data.get("community_cards", [])).size(),
		int(hand_data.get("pot", 0)),
	])
	finish_hand()


func _runout_board_to_five_cards() -> void:
	var board_count: int = Array(hand_data.get("community_cards", [])).size()
	if board_count < 3:
		_deal_community_cards(3 - board_count)
		_log("Flop dealt.")
		board_count = Array(hand_data.get("community_cards", [])).size()
	if board_count < 4:
		_deal_community_cards(1)
		_log("Turn dealt.")
		board_count = Array(hand_data.get("community_cards", [])).size()
	if board_count < 5:
		_deal_community_cards(1)
		_log("River dealt.")


func _all_in_amounts_are_unequal() -> bool:
	var amounts: Array[int] = []
	for seat_id in _active_contender_ids():
		var seat: Dictionary = _seat_by_id(seat_id)
		if String(seat.get("status", EMPTY)) == ALL_IN:
			amounts.append(int(seat.get("current_bet", 0)))
	if amounts.size() < 2:
		return false
	var first_amount: int = amounts[0]
	for amount in amounts:
		if amount != first_amount:
			return true
	return false


func finish_hand() -> Dictionary:
	if table_state == HAND_OVER and int(hand_data.get("pot", 0)) == 0 and not Dictionary(hand_data.get("settlement", {})).is_empty():
		_debug_rule("finish_hand ignored: hand already settled")
		return to_snapshot()
	_clear_betting_round_state(true)
	var pot_amount: int = int(hand_data.get("pot", 0))
	var winners: Array[int] = _determine_winners()
	var winning_rank: String = String(hand_data.get("winning_rank", ""))
	_award_pot(winners, pot_amount)
	var winner_names: Array[String] = []
	for winner_id in winners:
		winner_names.append(_seat_display_name(_seat_by_id(winner_id)))
	table_state = HAND_OVER
	hand_data["stage"] = HAND_OVER
	hand_data["current_turn_seat"] = -1
	hand_data["winner_seats"] = winners.duplicate()
	hand_data["settlement"] = {
		"winner_seats": winners.duplicate(),
		"winner_names": winner_names.duplicate(),
		"win_amount": int(pot_amount / max(winners.size(), 1)) if not winners.is_empty() else 0,
		"hand_rank": winning_rank,
		"hand_description": winning_rank,
		"pot_before_settlement": pot_amount,
		"pot_after_settlement": 0,
	}
	hand_data["pot"] = 0
	hand_data["current_bet"] = 0
	hand_data["acted_this_round"] = []
	for i in seats.size():
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		if winners.has(seat_id):
			_set_last_action(seat, "WIN", int(pot_amount / max(winners.size(), 1)))
		seat["current_bet"] = 0
		seats[i] = seat
	var winner_text: String = _winner_names(winners)
	if winning_rank != "":
		_log("%s wins %d with %s." % [winner_text, pot_amount, winning_rank])
	else:
		_log("%s wins %d." % [winner_text, pot_amount])
	for winner_id in winners:
		_add_visual_event("player_action", winner_id, "WIN", int(pot_amount / max(winners.size(), 1)))
	_log("Hand over.")
	_debug_rule("settlement winners=%s win_amount=%d rank=%s pot=%d->0" % [
		str(winners),
		int(hand_data["settlement"].get("win_amount", 0)),
		winning_rank if winning_rank != "" else "-",
		pot_amount,
	])
	return to_snapshot()


func to_snapshot() -> Dictionary:
	return {
		"table_state": table_state,
		"seats": seats.duplicate(true),
		"hand_data": hand_data.duplicate(true),
		"table_log": table_log.duplicate(),
		"rule_debug_log": rule_debug_log.duplicate(),
	}


func _empty_hand_data() -> Dictionary:
	return {
		"deck": [],
		"community_cards": [],
		"pot": 0,
		"current_bet": 0,
		"dealer_seat": -1,
		"small_blind_seat": -1,
		"big_blind_seat": -1,
		"current_turn_seat": -1,
		"acted_this_round": [],
		"last_raiser_seat": -1,
		"stage": WAITING,
		"winner_seats": [],
		"settlement": {},
		"visual_events": [],
	}


func _mock_player_seats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var avatar_ids: Dictionary = {
		1: "1_01",
		2: "1_02",
		3: "1_03",
		4: "2_01",
		5: "4_05",
		6: "5_02",
		7: "7_05",
		8: "8_01",
		9: "10_03",
	}
	for i in range(1, 10):
		var has_player: bool = i != 8
		result.append({
			"seat_id": i,
			"seat_index": i,
			"player_id": "player_%03d" % i if has_player else "",
			"player_name": "Luna0581" if i == 5 else ("Seat %d" % i),
			"avatar_id": String(avatar_ids.get(i, "")) if has_player else "",
			"chips": 24500 if i == 5 else 12000 + i * 850,
			"current_bet": 0,
			"hole_cards": [],
			"status": SITTING if has_player else EMPTY,
			"last_action": "",
			"last_action_amount": 0,
			"last_action_seq": 0,
			"is_dealer": false,
			"is_small_blind": false,
			"is_big_blind": false,
			"is_local": i == 5,
		})
	return result


func _active_seat_ids() -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data: Dictionary = seat
		if String(data.get("status", EMPTY)) in [PLAYING, ALL_IN]:
			result.append(int(data.get("seat_id", data.get("seat_index", 0))))
	return result


func _active_contender_ids() -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data: Dictionary = seat
		var status: String = String(data.get("status", EMPTY))
		if status not in [EMPTY, FOLDED, OUT]:
			result.append(int(data.get("seat_id", data.get("seat_index", 0))))
	return result


func _players_who_can_act_ids() -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data: Dictionary = seat
		if String(data.get("status", EMPTY)) == PLAYING and int(data.get("chips", 0)) > 0:
			result.append(int(data.get("seat_id", data.get("seat_index", 0))))
	return result


func _should_auto_runout_all_in() -> bool:
	if table_state not in [PREFLOP, FLOP, TURN, RIVER]:
		return false
	var contenders: Array[int] = _active_contender_ids()
	if contenders.size() < 2:
		return false
	return _players_who_can_act_ids().is_empty()


func _is_eligible_for_next_hand(seat: Dictionary) -> bool:
	var status: String = String(seat.get("status", EMPTY))
	if status in [EMPTY, OUT]:
		return false
	if bool(seat.get("is_sitting_out", false)):
		return false
	if String(seat.get("player_id", "")) == "":
		return false
	return int(seat.get("chips", 0)) > 0


func _next_hand_exclusion_reason(seat: Dictionary) -> String:
	var status: String = String(seat.get("status", EMPTY))
	if status == EMPTY:
		return "excluded: empty seat"
	if status == OUT:
		return "excluded: out"
	if bool(seat.get("is_sitting_out", false)):
		return "excluded: sitting out"
	if String(seat.get("player_id", "")) == "":
		return "excluded: no player"
	if int(seat.get("chips", 0)) <= 0:
		return "excluded: no chips"
	return "excluded"


func _log_start_hand_blocked() -> void:
	var eligible_count: int = eligible_next_hand_seat_ids().size()
	_log("Cannot start hand: only %d eligible player%s." % [
		eligible_count,
		"" if eligible_count == 1 else "s",
	])
	for line in next_hand_eligibility_report():
		_debug_rule(line)


func _seat_by_id(seat_id: int) -> Dictionary:
	for seat in seats:
		var data: Dictionary = seat
		if int(data.get("seat_id", data.get("seat_index", 0))) == seat_id:
			return data
	return {}


func _post_blind(seat_id: int, amount: int, label: String) -> void:
	for i in seats.size():
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		if int(seat.get("seat_id", seat.get("seat_index", 0))) != seat_id:
			continue
		var paid: int = _commit_to_pot(seat, amount)
		_set_last_action(seat, "SB" if label == "small blind" else "BB", paid)
		seats[i] = seat
		_log("Seat %d posts %s %d." % [seat_id, label, paid])
		_add_visual_event("player_action", seat_id, "SB" if label == "small blind" else "BB", paid)
		_add_visual_event("chip_move", seat_id, label, paid)
		return


func _calculate_pot() -> int:
	var total: int = 0
	for seat in seats:
		total += int(Dictionary(seat).get("current_bet", 0))
	return total


func _deal_community_cards(count: int) -> void:
	var deck: Array = Array(hand_data.get("deck", [])).duplicate(true)
	var community: Array = Array(hand_data.get("community_cards", [])).duplicate(true)
	for i in range(count):
		if deck.is_empty():
			break
		var card: Dictionary = Dictionary(deck.pop_front()).duplicate(true)
		card["face_up"] = true
		community.append(card)
		_add_visual_event("deal_community", -1, "COMMUNITY", 0, {"board_index": community.size() - 1})
	hand_data["deck"] = deck
	hand_data["community_cards"] = community
	_log("Community cards dealt. Board count: %d." % community.size())


func _commit_to_pot(seat: Dictionary, amount: int) -> int:
	var paid: int = min(max(amount, 0), int(seat.get("chips", 0)))
	seat["chips"] = int(seat.get("chips", 0)) - paid
	seat["current_bet"] = int(seat.get("current_bet", 0)) + paid
	if int(seat.get("chips", 0)) == 0 and String(seat.get("status", EMPTY)) == PLAYING:
		seat["status"] = ALL_IN
	hand_data["pot"] = int(hand_data.get("pot", 0)) + paid
	return paid


func _set_last_action(seat: Dictionary, action_label: String, amount: int) -> void:
	seat["last_action"] = action_label
	seat["last_action_amount"] = amount
	seat["last_action_seq"] = int(seat.get("last_action_seq", 0)) + 1


func _determine_winners() -> Array[int]:
	var live_ids: Array[int] = _live_seat_ids()
	if live_ids.size() <= 1:
		hand_data["winning_rank"] = ""
		return live_ids
	var community_cards: Array = Array(hand_data.get("community_cards", []))
	if community_cards.size() < 5:
		hand_data["winning_rank"] = ""
		return live_ids
	var board_codes: Array[String] = _card_codes(community_cards)
	var best_eval: Dictionary = {}
	var best_seats: Array[int] = []
	for seat_id in live_ids:
		var seat: Dictionary = _seat_by_id(seat_id)
		var hole_codes: Array[String] = _card_codes(Array(seat.get("hole_cards", [])))
		var evaluation: Dictionary = HandEvaluatorScript.evaluate(hole_codes + board_codes)
		if best_eval.is_empty() or _compare_evaluations(evaluation, best_eval) > 0:
			best_eval = evaluation
			best_seats = [seat_id]
		elif _compare_evaluations(evaluation, best_eval) == 0:
			best_seats.append(seat_id)
	hand_data["winning_rank"] = String(best_eval.get("rank", ""))
	_log("Winner determined: %s (%s)." % [_winner_names(best_seats), String(hand_data.get("winning_rank", ""))])
	return best_seats


func _award_pot(winner_seats: Array[int], pot_amount: int) -> void:
	if winner_seats.is_empty() or pot_amount <= 0:
		return
	var share: int = pot_amount / winner_seats.size()
	var odd_chip: int = pot_amount % winner_seats.size()
	for i in seats.size():
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		var winner_index: int = winner_seats.find(seat_id)
		if winner_index != -1:
			seat["chips"] = int(seat.get("chips", 0)) + share + (1 if winner_index == 0 and odd_chip > 0 else 0)
		seats[i] = seat


func _live_seat_ids() -> Array[int]:
	var result: Array[int] = []
	for seat in seats:
		var data: Dictionary = seat
		if String(data.get("status", EMPTY)) in [PLAYING, ALL_IN]:
			result.append(int(data.get("seat_id", data.get("seat_index", 0))))
	return result


func _card_codes(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		var data: Dictionary = Dictionary(card)
		var code: String = String(data.get("code", ""))
		if code == "" and data.has("rank") and data.has("suit"):
			code = _card_code_from_rank_suit(String(data.get("rank", "")), String(data.get("suit", "")))
		if code.length() == 2:
			result.append(code)
	return result


func _card_code_from_rank_suit(rank: String, suit: String) -> String:
	var suit_codes := {
		"clubs": "C",
		"diamonds": "D",
		"hearts": "H",
		"spades": "S",
		"C": "C",
		"D": "D",
		"H": "H",
		"S": "S",
	}
	return "%s%s" % [rank.to_upper(), String(suit_codes.get(suit, "?"))]


func _compare_evaluations(a: Dictionary, b: Dictionary) -> int:
	var rank_delta: int = int(a.get("rank_value", 0)) - int(b.get("rank_value", 0))
	if rank_delta != 0:
		return sign(rank_delta)
	var a_cards: Array = Array(a.get("cards", []))
	var b_cards: Array = Array(b.get("cards", []))
	for i in range(min(a_cards.size(), b_cards.size())):
		var delta: int = _rank_value(String(a_cards[i])) - _rank_value(String(b_cards[i]))
		if delta != 0:
			return sign(delta)
	return 0


func _rank_value(code: String) -> int:
	return int(HandEvaluatorScript.RANK_VALUES.get(code.substr(0, 1), 0))


func _winner_names(winner_seats: Array[int]) -> String:
	if winner_seats.is_empty():
		return "No player"
	var names: Array[String] = []
	for seat_id in winner_seats:
		var seat: Dictionary = _seat_by_id(seat_id)
		names.append(_seat_display_name(seat))
	return ", ".join(names)


func _add_visual_event(event_type: String, seat_id: int, action_label: String = "", amount: int = 0, extra: Dictionary = {}) -> void:
	_visual_event_number += 1
	var events: Array = Array(hand_data.get("visual_events", [])).duplicate(true)
	var event: Dictionary = {
		"id": _visual_event_number,
		"type": event_type,
		"seat_id": seat_id,
		"action": action_label,
		"amount": amount,
	}
	for key in extra.keys():
		event[key] = extra[key]
	events.append(event)
	if events.size() > 80:
		events = events.slice(events.size() - 80)
	hand_data["visual_events"] = events


func _add_collect_bets_event() -> void:
	var bets: Array[Dictionary] = []
	for seat in seats:
		var data: Dictionary = Dictionary(seat)
		var amount: int = int(data.get("current_bet", 0))
		if amount <= 0:
			continue
		bets.append({
			"seat_id": int(data.get("seat_id", data.get("seat_index", 0))),
			"amount": amount,
		})
	if bets.is_empty():
		return
	_add_visual_event("collect_bets", -1, "COLLECT", 0, {"bets": bets})


func _clear_betting_round_state(clear_turn: bool) -> void:
	hand_data["current_bet"] = 0
	hand_data["acted_this_round"] = []
	hand_data["last_raiser_seat"] = -1
	if clear_turn:
		hand_data["current_turn_seat"] = -1
	for i in seats.size():
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		seat["current_bet"] = 0
		seats[i] = seat


func _seat_array_index(seat_id: int) -> int:
	for i in seats.size():
		var data: Dictionary = Dictionary(seats[i])
		if int(data.get("seat_id", data.get("seat_index", 0))) == seat_id:
			return i
	return -1


func _seat_display_name(seat: Dictionary) -> String:
	var name: String = String(seat.get("player_name", ""))
	if name != "":
		return name
	return "Seat %d" % int(seat.get("seat_id", seat.get("seat_index", 0)))


func _debug_action(seat_id: int, action_label: String, call_amount: int, raise_to: int, pot_before: int, current_bet_before: int) -> void:
	var pot_after: int = int(hand_data.get("pot", 0))
	var current_bet_after: int = int(hand_data.get("current_bet", 0))
	var paid_amount: int = max(pot_after - pot_before, 0)
	var action_text: String = action_label
	match action_label:
		"CALL":
			action_text = "CALL amount=%d" % paid_amount
		"BET":
			action_text = "BET amount=%d" % paid_amount
		"RAISE":
			action_text = "RAISE to=%d call_part=%d raise_part=%d" % [
				raise_to,
				call_amount,
				max(raise_to - current_bet_before, 0),
			]
		"ALL-IN":
			action_text = "ALL_IN amount=%d" % paid_amount
		"CHECK":
			action_text = "CHECK"
		"FOLD":
			action_text = "FOLD"
	_debug_rule(
		"action seat=%d name=%s %s pot=%d->%d current_bet=%d->%d" % [
			seat_id,
			_seat_display_name(_seat_by_id(seat_id)),
			action_text,
			pot_before,
			pot_after,
			current_bet_before,
			current_bet_after,
		]
	)


func _debug_rule(message: String) -> void:
	rule_debug_log.append(message)
	if rule_debug_log.size() > 80:
		rule_debug_log = rule_debug_log.slice(rule_debug_log.size() - 80)
	print("[PokerRuleDebug] %s" % message)


func _log(message: String) -> void:
	table_log.append(message)
	print("[TexasTableFlow] %s" % message)
