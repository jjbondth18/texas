extends SceneTree

const TexasTableFlow := preload("res://scripts/core/texas_table_flow.gd")


func _init() -> void:
	_check_call()
	_check_fold()
	_check_raise()
	print("Texas table player action smoke test passed.")
	quit(0)


func _check_call() -> void:
	var flow = TexasTableFlow.new()
	flow.reset_table()
	flow.start_new_hand(33)
	flow.hand_data["current_turn_seat"] = 5
	var before: Dictionary = _seat(flow, 5)
	var before_chips: int = int(before.get("chips", 0))
	var before_pot: int = int(flow.hand_data.get("pot", 0))
	flow.apply_player_action(5, {"id": "call"})
	var after: Dictionary = _seat(flow, 5)
	_assert(int(after.get("chips", 0)) == before_chips - 50, "CALL must reduce local chips by call amount")
	_assert(int(flow.hand_data.get("pot", 0)) == before_pot + 50, "CALL must add to pot")
	_assert(int(flow.hand_data.get("current_turn_seat", -1)) != 5, "CALL must advance turn")
	_assert(_log_contains(flow, "calls 50"), "CALL must log action")


func _check_fold() -> void:
	var flow = TexasTableFlow.new()
	flow.reset_table()
	flow.start_new_hand(34)
	flow.hand_data["current_turn_seat"] = 5
	flow.apply_player_action(5, {"id": "fold"})
	var after: Dictionary = _seat(flow, 5)
	_assert(String(after.get("status", "")) == TexasTableFlow.FOLDED, "FOLD must mark local player folded")
	_assert(_log_contains(flow, "folds"), "FOLD must log action")


func _check_raise() -> void:
	var flow = TexasTableFlow.new()
	flow.reset_table()
	flow.start_new_hand(35)
	flow.hand_data["current_turn_seat"] = 5
	var before: Dictionary = _seat(flow, 5)
	var before_chips: int = int(before.get("chips", 0))
	var before_pot: int = int(flow.hand_data.get("pot", 0))
	flow.apply_player_action(5, {"id": "raise", "amount": 150})
	var after: Dictionary = _seat(flow, 5)
	_assert(int(after.get("chips", 0)) == before_chips - 150, "RAISE must reduce local chips by raise delta")
	_assert(int(flow.hand_data.get("pot", 0)) == before_pot + 150, "RAISE must add raise delta to pot")
	_assert(int(flow.hand_data.get("current_bet", 0)) == 150, "RAISE must update current_bet")
	_assert(Array(flow.hand_data.get("acted_this_round", [])).has(5), "RAISE must reset acted_this_round to raiser")
	_assert(int(flow.hand_data.get("current_turn_seat", -1)) != 5, "RAISE must advance turn")
	_assert(_log_contains(flow, "raises to 150"), "RAISE must log action")


func _seat(flow, seat_id: int) -> Dictionary:
	for seat in flow.seats:
		var data: Dictionary = Dictionary(seat)
		if int(data.get("seat_id", -1)) == seat_id:
			return data
	return {}


func _log_contains(flow, needle: String) -> bool:
	for item in flow.table_log:
		if String(item).find(needle) != -1:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
