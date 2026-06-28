extends SceneTree

const TexasTableFlowScript := preload("res://scripts/core/texas_table_flow.gd")

func _init() -> void:
	var flow := TexasTableFlowScript.new()
	flow.reset_table()
	flow.start_new_hand(701)
	_prepare_two_player_all_in_spot(flow, TexasTableFlowScript.PREFLOP, 0)

	flow.apply_player_action(1, {"id": "all_in"})
	_assert(String(flow.table_state) == TexasTableFlowScript.PREFLOP, "first all-in should wait for second player")
	flow.apply_player_action(2, {"id": "all_in"})

	_assert(String(flow.table_state) == TexasTableFlowScript.HAND_OVER, "preflop all-in must auto runout to HAND_OVER")
	_assert(Array(flow.hand_data.get("community_cards", [])).size() == 5, "preflop all-in must deal full board")
	_assert(int(flow.hand_data.get("current_turn_seat", -2)) == -1, "all-in runout must clear current_turn")
	_assert(int(flow.hand_data.get("pot", -1)) == 0, "settled all-in hand must clear pot")
	_assert(not Dictionary(flow.hand_data.get("settlement", {})).is_empty(), "all-in runout must settle")
	_assert(_log_contains(flow.table_log, "All players all-in"), "table log must record all-in runout")

	print("All-in preflop auto runout test passed.")
	quit(0)

func _prepare_two_player_all_in_spot(flow: TexasTableFlow, stage: String, board_count: int) -> void:
	for i in flow.seats.size():
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", 0))
		if seat_id in [1, 2]:
			seat["status"] = TexasTableFlowScript.PLAYING
			seat["chips"] = 100
			seat["current_bet"] = 0
		elif String(seat.get("status", "")) != TexasTableFlowScript.EMPTY:
			seat["status"] = TexasTableFlowScript.FOLDED
			seat["current_bet"] = 0
		flow.seats[i] = seat
	flow.table_state = stage
	flow.hand_data["stage"] = stage
	flow.hand_data["pot"] = 0
	flow.hand_data["current_bet"] = 0
	flow.hand_data["current_turn_seat"] = 1
	flow.hand_data["acted_this_round"] = []
	if board_count > 0:
		var deck: Array = Array(flow.hand_data.get("deck", [])).duplicate(true)
		var board: Array = []
		for index in range(board_count):
			var card: Dictionary = Dictionary(deck.pop_front()).duplicate(true)
			card["face_up"] = true
			board.append(card)
		flow.hand_data["deck"] = deck
		flow.hand_data["community_cards"] = board
	else:
		flow.hand_data["community_cards"] = []

func _log_contains(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if String(line).find(needle) != -1:
			return true
	return false

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
