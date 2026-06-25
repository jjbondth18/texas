extends SceneTree

const HandLifecycle := preload("res://scripts/core/hand_lifecycle.gd")

func _init() -> void:
	var state := HandLifecycle.start_new_hand({"seats": _seats(), "dealer_seat": 0}, 11)
	var original := state.duplicate(true)
	var rejected := HandLifecycle.apply_action(state, {"id": "check", "seat_index": 4, "enabled": true})
	_assert(String(rejected.get("last_error", "")) == "facing_bet", "illegal check should be rejected")
	_assert(String(state.get("last_error", "")) == "", "input state must not mutate on rejection")
	var called := HandLifecycle.apply_action(state, {"id": "call", "seat_index": 4, "enabled": true})
	_assert(_seat(called, 4)["chips"] == 9950, "call should deduct 50 chips")
	_assert(int(Dictionary(called["pot"])["main"]) == 125, "call should increase pot")
	var raised := HandLifecycle.apply_action(called, {"id": "raise", "seat_index": 5, "amount": 150, "enabled": true})
	_assert(int(raised["current_bet"]) == 150, "raise should update current bet")
	_assert(int(raised["minimum_raise"]) >= 100, "raise should update minimum raise")
	var folded := HandLifecycle.apply_action(raised, {"id": "fold", "seat_index": 6, "enabled": true})
	_assert(String(_seat(folded, 6)["status"]) == "folded", "fold should update status")
	_assert(int(Dictionary(original["pot"])["main"]) == 75, "original snapshot must remain unchanged")
	print("Betting round smoke test passed.")
	quit(0)

func _seats() -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	for i in range(1, 10):
		seats.append({"seat_index": i, "player_id": "player_%03d" % i, "chips": 10000, "status": "active"})
	return seats

func _seat(state: Dictionary, seat_index: int) -> Dictionary:
	for seat in Array(state["seats"]):
		var data := Dictionary(seat)
		if int(data["seat_index"]) == seat_index:
			return data
	return {}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
