extends RefCounted
class_name HandReplayRecord

const REPLAY_VERSION := 1


static func from_server_payload(payload: Dictionary) -> Dictionary:
	var record: Dictionary = payload.duplicate(true)
	record["replay_version"] = int(record.get("replay_version", REPLAY_VERSION))
	record["players"] = Array(record.get("players", [])).duplicate(true)
	record["actions"] = Array(record.get("actions", [])).duplicate(true)
	record["results"] = Dictionary(record.get("results", {})).duplicate(true)
	record["community_cards"] = Dictionary(record.get("community_cards", {})).duplicate(true)
	record["dealer_id"] = str(record.get("dealer_id", ""))
	record["currency"] = str(record.get("currency", "gems" if str(record.get("table_type", "")).ends_with("_gem") else "chips"))
	return record


static func from_local_flow(flow_snapshot: Dictionary, ui_snapshot: Dictionary, session_data: Dictionary) -> Dictionary:
	var hand: Dictionary = Dictionary(flow_snapshot.get("hand_data", {})).duplicate(true)
	var settlement: Dictionary = Dictionary(hand.get("settlement", {})).duplicate(true)
	var hand_id: String = str(hand.get("hand_id", ui_snapshot.get("hand_id", "hand_000000")))
	var mode: String = _mode_from_session(session_data)
	var ended_at: String = Time.get_datetime_string_from_system(true)
	var players: Array = _players_from_local_flow(Array(flow_snapshot.get("seats", [])), settlement)
	var community: Array = Array(hand.get("community_cards", [])).duplicate(true)
	var actions: Array = _actions_from_local_events(Array(hand.get("visual_events", [])), Array(flow_snapshot.get("table_log", [])))
	return {
		"replay_version": REPLAY_VERSION,
		"hand_id": hand_id,
		"room_id": str(ui_snapshot.get("table_id", "")),
		"room_code": str(ui_snapshot.get("room_code", ui_snapshot.get("room_label", ""))),
		"mode": mode,
		"table_type": str(session_data.get("table_type", ui_snapshot.get("table_type", mode))),
		"currency": str(session_data.get("currency", ui_snapshot.get("currency", "gems" if str(session_data.get("table_type", "")).ends_with("_gem") else "chips"))),
		"dealer_id": str(session_data.get("dealer_id", session_data.get("selected_dealer_id", ui_snapshot.get("dealer_id", "")))),
		"started_at": ended_at,
		"ended_at": ended_at,
		"small_blind": int(session_data.get("small_blind", 0)),
		"big_blind": int(session_data.get("big_blind", 0)),
		"button_seat": int(hand.get("dealer_seat", -1)),
		"small_blind_seat": int(hand.get("small_blind_seat", -1)),
		"big_blind_seat": int(hand.get("big_blind_seat", -1)),
		"max_hands": int(session_data.get("max_hands", ui_snapshot.get("max_hands", 0))),
		"hand_number": int(session_data.get("current_hand_index", ui_snapshot.get("current_hand_number", 0))),
		"players": players,
		"community_cards": {
			"flop": _card_codes(community.slice(0, min(3, community.size()))),
			"turn": _card_codes(community.slice(3, min(4, community.size()))),
			"river": _card_codes(community.slice(4, min(5, community.size()))),
		},
		"actions": actions,
		"results": _results_from_settlement(settlement),
	}


static func from_ui_snapshot(ui_snapshot: Dictionary, private_snapshot: Dictionary = {}) -> Dictionary:
	var table_info: Dictionary = Dictionary(ui_snapshot.get("table_info", {}))
	var hand_id: String = str(ui_snapshot.get("hand_id", "hand_000000"))
	var local_seat: int = int(ui_snapshot.get("local_seat_index", -1))
	var players: Array = []
	for seat_item in Array(ui_snapshot.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item).duplicate(true)
		if not bool(seat.get("occupied", str(seat.get("player_id", "")) != "")):
			continue
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", -1)))
		var cards: Array = []
		if seat_id == local_seat:
			cards = _card_codes(Array(private_snapshot.get("hole_cards", seat.get("cards", []))))
		players.append({
			"player_id": str(seat.get("player_id", "")),
			"player_name": str(seat.get("player_name", seat.get("name", ""))),
			"seat_index": seat_id,
			"avatar_id": str(seat.get("avatar_id", "")),
			"is_ai": bool(seat.get("is_ai", false)),
			"is_local_warmup_ai": bool(seat.get("warmup_ai", false)),
			"is_local": bool(seat.get("is_local", false)),
			"starting_stack": int(seat.get("hand_starting_stack", seat.get("chips", 0))),
			"ending_stack": int(seat.get("chips", 0)),
			"hole_cards": cards,
			"final_status": str(seat.get("raw_status", seat.get("status", ""))),
		})
	var board: Array = Array(ui_snapshot.get("community_cards", []))
	return {
		"replay_version": REPLAY_VERSION,
		"hand_id": hand_id,
		"room_id": str(ui_snapshot.get("table_id", "")),
		"room_code": str(ui_snapshot.get("room_code", ui_snapshot.get("room_label", ""))),
		"mode": _mode_from_table_type(str(ui_snapshot.get("table_type", table_info.get("table_type", "")))),
		"table_type": str(ui_snapshot.get("table_type", table_info.get("table_type", ""))),
		"currency": str(ui_snapshot.get("currency", table_info.get("currency", "gems" if str(ui_snapshot.get("table_type", table_info.get("table_type", ""))).ends_with("_gem") else "chips"))),
		"dealer_id": str(ui_snapshot.get("dealer_id", table_info.get("dealer_id", ""))),
		"started_at": Time.get_datetime_string_from_system(true),
		"ended_at": Time.get_datetime_string_from_system(true),
		"small_blind": int(table_info.get("small_blind", 0)),
		"big_blind": int(table_info.get("big_blind", 0)),
		"button_seat": int(ui_snapshot.get("dealer_seat", -1)),
		"small_blind_seat": int(ui_snapshot.get("small_blind_seat", -1)),
		"big_blind_seat": int(ui_snapshot.get("big_blind_seat", -1)),
		"max_hands": int(ui_snapshot.get("max_hands", 0)),
		"hand_number": int(ui_snapshot.get("current_hand_number", 0)),
		"players": players,
		"community_cards": {
			"flop": _card_codes(board.slice(0, min(3, board.size()))),
			"turn": _card_codes(board.slice(3, min(4, board.size()))),
			"river": _card_codes(board.slice(4, min(5, board.size()))),
		},
		"actions": _actions_from_server_log(Array(ui_snapshot.get("server_recent_actions", ui_snapshot.get("server_action_log", [])))),
		"results": {
			"winners": Array(ui_snapshot.get("winners", [])).duplicate(true),
			"final_pot": int(ui_snapshot.get("pot", 0)),
			"side_pots": Array(Dictionary(ui_snapshot.get("pot_data", {})).get("side_pots", [])).duplicate(true),
		},
	}


static func _mode_from_session(session_data: Dictionary) -> String:
	if bool(session_data.get("is_ai_warmup", false)):
		return "local_warmup"
	var mode: String = str(session_data.get("mode", ""))
	var table_type: String = str(session_data.get("table_type", ""))
	if mode == "training" or table_type == "training_ai":
		return "training"
	if mode == "friends_room" or table_type in ["private_room", "private_chip", "private_gem"]:
		return "private"
	return "public"


static func _mode_from_table_type(table_type: String) -> String:
	if table_type in ["private_room", "private_chip", "private_gem"]:
		return "private"
	if table_type == "training_ai":
		return "training"
	return "public"


static func _players_from_local_flow(seats: Array, settlement: Dictionary) -> Array:
	var winner_ids: Array = Array(settlement.get("winner_seats", []))
	var players: Array = []
	for seat_item in seats:
		var seat: Dictionary = Dictionary(seat_item).duplicate(true)
		var player_id: String = str(seat.get("player_id", ""))
		if player_id == "":
			continue
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", -1)))
		var is_winner: bool = winner_ids.has(seat_id)
		players.append({
			"player_id": player_id,
			"player_name": str(seat.get("player_name", seat.get("name", ""))),
			"seat_index": seat_id,
			"avatar_id": str(seat.get("avatar_id", "")),
			"is_ai": bool(seat.get("is_ai", false)),
			"is_local_warmup_ai": bool(seat.get("warmup_ai", false)),
			"is_local": bool(seat.get("is_local", false)),
			"starting_stack": int(seat.get("hand_starting_stack", seat.get("chips", 0))),
			"ending_stack": int(seat.get("chips", 0)),
			"hole_cards": _card_codes(Array(seat.get("hole_cards", []))),
			"final_status": "winner" if is_winner else str(seat.get("status", "")),
		})
	return players


static func _actions_from_local_events(events: Array, table_log: Array) -> Array:
	var actions: Array = []
	var seq: int = 0
	for event_item in events:
		var event: Dictionary = Dictionary(event_item)
		var event_type: String = str(event.get("type", ""))
		if event_type not in ["player_action", "deal_community"]:
			continue
		seq += 1
		actions.append({
			"seq": seq,
			"street": str(event.get("phase", "")),
			"actor_seat": int(event.get("seat_id", -1)),
			"actor_player_id": "",
			"action": _normalized_action(str(event.get("label", event.get("action", event_type)))),
			"amount": int(event.get("amount", 0)),
			"bet_to": int(event.get("amount", 0)),
			"pot_after": 0,
			"player_stack_after": 0,
			"timestamp_ms": Time.get_ticks_msec(),
			"message": str(event.get("message", "")),
		})
	if actions.is_empty():
		for log_item in table_log:
			seq += 1
			actions.append({
				"seq": seq,
				"street": "",
				"actor_seat": -1,
				"actor_player_id": "",
				"action": "log",
				"amount": 0,
				"bet_to": 0,
				"pot_after": 0,
				"player_stack_after": 0,
				"timestamp_ms": Time.get_ticks_msec(),
				"message": str(log_item),
			})
	return actions


static func _actions_from_server_log(events: Array) -> Array:
	var actions: Array = []
	for event_item in events:
		var event: Dictionary = Dictionary(event_item)
		actions.append({
			"seq": int(event.get("sequence", event.get("id", actions.size() + 1))),
			"street": str(event.get("betting_round", event.get("phase", ""))),
			"actor_seat": int(event.get("seat_index", event.get("seat_id", -1))),
			"actor_player_id": str(event.get("player_id", "")),
			"action": _normalized_action(str(event.get("action", event.get("type", "")))),
			"amount": int(event.get("amount", 0)),
			"bet_to": int(event.get("amount", 0)),
			"pot_after": int(event.get("pot_after", 0)),
			"player_stack_after": int(event.get("player_stack_after", 0)),
			"timestamp_ms": Time.get_ticks_msec(),
			"message": str(event.get("message", "")),
		})
	return actions


static func _results_from_settlement(settlement: Dictionary) -> Dictionary:
	var winners: Array = []
	var winner_names: Array = Array(settlement.get("winner_names", []))
	for winner_seat_item in Array(settlement.get("winner_seats", [])):
		winners.append({
			"winner_seat": int(winner_seat_item),
			"winner_player_id": "",
			"amount_won": int(settlement.get("win_amount", 0)),
			"hand_rank_text": str(settlement.get("hand_description", settlement.get("hand_rank", ""))),
			"pot_type": "main",
		})
	return {
		"winners": winners,
		"winner_names": winner_names.duplicate(),
		"final_pot": int(settlement.get("pot_after_settlement", 0)),
		"side_pots": [],
	}


static func _card_codes(cards: Array) -> Array:
	var codes: Array = []
	for card_item in cards:
		var type_id: int = typeof(card_item)
		if type_id == TYPE_STRING or type_id == TYPE_STRING_NAME:
			var string_code: String = str(card_item)
			if string_code != "":
				codes.append(string_code)
			continue
		var card: Dictionary = Dictionary(card_item)
		var code: String = str(card.get("code", ""))
		if code == "":
			code = "%s%s" % [str(card.get("rank", "")), _suit_code(str(card.get("suit", "")))]
		if code != "":
			codes.append(code)
	return codes


static func _suit_code(suit: String) -> String:
	match suit:
		"clubs", "club", "C":
			return "C"
		"diamonds", "diamond", "D":
			return "D"
		"hearts", "heart", "H":
			return "H"
		"spades", "spade", "S":
			return "S"
	return suit


static func _normalized_action(action: String) -> String:
	var value: String = action.to_lower()
	match value:
		"sb":
			return "small_blind"
		"bb":
			return "big_blind"
		"auto-check":
			return "timeout_auto_check"
		"auto-fold":
			return "timeout_auto_fold"
	return value
