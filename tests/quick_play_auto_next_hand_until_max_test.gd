extends SceneTree

const TexasTableFlowScript := preload("res://scripts/core/texas_table_flow.gd")
const TableSessionScript := preload("res://scripts/data/table_session.gd")

func _init() -> void:
	var flow := TexasTableFlowScript.new()
	var session := TableSessionScript.new()
	session.configure_from_context({
		"mode": "quick_play",
		"buy_in": 20000,
		"starting_chips": 20000,
		"current_table_chips": 20000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 3,
	})
	flow.reset_table()

	for hand_index in range(1, 4):
		_require(session.can_start_next_hand(), "session must allow hand %d" % hand_index)
		_require(flow.can_start_hand(), "table flow must allow hand %d" % hand_index)
		session.begin_next_hand()
		flow.start_new_hand(820 + hand_index)
		_require(not _log_contains(flow.table_log, "Cannot start hand"), "hand %d must not log enough-player failure" % hand_index)
		flow.force_current_hand_to_showdown()
		session.record_hand_result(Dictionary(flow.hand_data.get("settlement", {})), 5, int(flow.get_seat_data(5).get("chips", 0)))
		_mark_folded_players_with_chips(flow)

	_require(session.is_session_over, "session must end after max_hands")
	_require(session.end_reason == "Hands completed", "session must end because hands completed")

	print("Quick play auto next hand until max test passed.")
	quit(0)

func _mark_folded_players_with_chips(flow: TexasTableFlow) -> void:
	for seat_id in [1, 2, 3]:
		for i in flow.seats.size():
			var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
			if int(seat.get("seat_id", 0)) != seat_id:
				continue
			seat["status"] = TexasTableFlowScript.FOLDED
			seat["chips"] = max(int(seat.get("chips", 0)), 500)
			flow.seats[i] = seat
			break
	flow.table_state = TexasTableFlowScript.HAND_OVER

func _log_contains(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if String(line).find(needle) != -1:
			return true
	return false

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
