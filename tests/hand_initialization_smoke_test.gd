extends SceneTree

const HandLifecycle := preload("res://scripts/core/hand_lifecycle.gd")

func _init() -> void:
	var state := HandLifecycle.start_new_hand({"seats": _seats(), "dealer_seat": 0}, 7)
	_assert(Array(state["deck"]).size() == 34, "deck should have 34 cards after 9 players receive 2")
	_assert(_all_cards_unique(state), "cards must be unique")
	for seat in Array(state["seats"]):
		var data := Dictionary(seat)
		if String(data["status"]) != "empty":
			_assert(Array(data["cards"]).size() == 2, "active players need two hole cards")
	_assert(int(state["small_blind_seat"]) == 2, "small blind should be seat 2")
	_assert(int(state["big_blind_seat"]) == 3, "big blind should be seat 3")
	_assert(int(state["current_turn_seat"]) == 4, "preflop first actor should be seat 4")
	_assert(int(Dictionary(state["pot"])["main"]) == 75, "blinds must post 75 total")
	_assert(_has_event(state, "hand_started"), "hand_started event missing")
	_assert(_has_event(state, "hole_cards_dealt"), "hole_cards_dealt event missing")
	print("Hand initialization smoke test passed.")
	quit(0)

func _seats() -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for i in range(1, 10):
		seats.append({"seat_index": i, "player_id": "player_%03d" % i, "chips": 10000, "status": "active"})
	return seats

func _all_cards_unique(state: Dictionary) -> bool:
	var seen := {}
	for card in Array(state["deck"]):
		seen[String(Dictionary(card)["code"])] = true
	for seat in Array(state["seats"]):
		for card in Array(Dictionary(seat)["cards"]):
			var code := String(Dictionary(card)["code"])
			if seen.has(code):
				return false
			seen[code] = true
	return seen.size() == 52

func _has_event(state: Dictionary, event_type: String) -> bool:
	for event in Array(state["events"]):
		if String(Dictionary(event)["type"]) == event_type:
			return true
	return false

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
