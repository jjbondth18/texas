extends SceneTree

const HandLifecycle := preload("res://scripts/core/hand_lifecycle.gd")

func _init() -> void:
	# 3-player game: dealer_seat=0 (so previous_dealer=0, dealer=1, SB=2, BB=3, first turn=1)
	var state := HandLifecycle.start_new_hand({"seats": _seats(3), "dealer_seat": 0}, 12)
	# Preflop action:
	# Seat 1 (Dealer) folds
	state = HandLifecycle.apply_action(state, {"id": "fold", "seat_index": 1, "enabled": true})
	# Seat 2 (SB) calls
	state = HandLifecycle.apply_action(state, {"id": "call", "seat_index": 2, "enabled": true})
	# Seat 3 (BB) checks to close action
	state = HandLifecycle.apply_action(state, {"id": "check", "seat_index": 3, "enabled": true})
	
	_assert(String(state["phase"]) == "flop", "betting round should advance to flop")
	_assert(Array(state["community_cards"]).size() == 3, "flop should have 3 cards")
	
	# Flop action check around
	state = _check_around(state)
	_assert(String(state["phase"]) == "turn", "flop checks should advance to turn")
	_assert(Array(state["community_cards"]).size() == 4, "turn should have 4 cards")
	
	# 2-player game (heads-up): dealer_seat=1 (so previous_dealer=1, dealer=2, SB=1, BB=2, first turn=1)
	var fold_win := HandLifecycle.start_new_hand({"seats": _seats(2), "dealer_seat": 1}, 13)
	# SB (Seat 1) folds preflop, BB (Seat 2) wins immediately
	fold_win = HandLifecycle.apply_action(fold_win, {"id": "fold", "seat_index": 1, "enabled": true})
	
	_assert(bool(fold_win["hand_complete"]), "single remaining player should win immediately")
	_assert(_has_event(fold_win, "hand_won_by_fold"), "fold victory event missing")
	
	print("Hand lifecycle smoke test passed.")
	quit(0)

func _check_around(state: Dictionary) -> Dictionary:
	var next := state
	var guard := 0
	while String(next["phase"]) == "flop" and guard < 10:
		guard += 1
		next = HandLifecycle.apply_action(next, {"id": "check", "seat_index": int(next["current_turn_seat"]), "enabled": true})
	return next

func _seats(count: int) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for i in range(1, count + 1):
		seats.append({"seat_index": i, "player_id": "player_%03d" % i, "chips": 10000, "status": "active"})
	return seats

func _has_event(state: Dictionary, event_type: String) -> bool:
	for event in Array(state["events"]):
		if String(Dictionary(event)["type"]) == event_type:
			return true
	return false

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("Assertion failed: " + message)
		quit(1)
		# Immediately terminate the process to prevent executing success lines
		OS.kill(OS.get_process_id())
