extends SceneTree

const TexasTableFlow := preload("res://scripts/core/texas_table_flow.gd")


func _init() -> void:
	var flow = TexasTableFlow.new()
	var waiting: Dictionary = flow.reset_table()
	_assert(String(waiting.get("table_state", "")) == TexasTableFlow.WAITING, "reset_table must enter WAITING")
	_assert(flow.can_start_hand(), "mock table should be able to start a hand")

	var started: Dictionary = flow.start_new_hand(2026)
	var hand: Dictionary = Dictionary(started.get("hand_data", {}))
	var seats: Array = Array(started.get("seats", []))

	_assert(String(started.get("table_state", "")) == TexasTableFlow.PREFLOP, "start_new_hand must enter PREFLOP")
	_assert(String(hand.get("stage", "")) == TexasTableFlow.PREFLOP, "hand stage must be PREFLOP")
	_assert(int(hand.get("dealer_seat", -1)) > 0, "dealer seat must be assigned")
	_assert(int(hand.get("small_blind_seat", -1)) > 0, "small blind seat must be assigned")
	_assert(int(hand.get("big_blind_seat", -1)) > 0, "big blind seat must be assigned")
	_assert(int(hand.get("small_blind_seat", -1)) != int(hand.get("big_blind_seat", -1)), "SB and BB must differ")
	_assert(int(hand.get("pot", 0)) == 75, "pot must equal posted blinds 25 + 50")

	var sb: Dictionary = _seat_by_id(seats, int(hand.get("small_blind_seat", -1)))
	var bb: Dictionary = _seat_by_id(seats, int(hand.get("big_blind_seat", -1)))
	_assert(int(sb.get("current_bet", 0)) == 25, "SB current_bet must be 25")
	_assert(int(bb.get("current_bet", 0)) == 50, "BB current_bet must be 50")
	_assert(int(sb.get("chips", 0)) < 12000 + int(sb.get("seat_id", 0)) * 850 or bool(sb.get("is_local", false)), "SB chips must be reduced")
	_assert(int(bb.get("chips", 0)) < 12000 + int(bb.get("seat_id", 0)) * 850 or bool(bb.get("is_local", false)), "BB chips must be reduced")

	for seat in seats:
		var data: Dictionary = Dictionary(seat)
		if String(data.get("status", "")) == TexasTableFlow.PLAYING:
			_assert(Array(data.get("hole_cards", [])).size() == 2, "playing player must receive 2 hole cards")

	_assert(Array(started.get("table_log", [])).size() > 0, "table log must be populated")
	print("Texas table flow state machine smoke test passed.")
	quit(0)


func _seat_by_id(seats: Array, seat_id: int) -> Dictionary:
	for seat in seats:
		var data: Dictionary = Dictionary(seat)
		if int(data.get("seat_id", -1)) == seat_id:
			return data
	return {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
