extends SceneTree

const TexasTableFlow := preload("res://scripts/core/texas_table_flow.gd")


func _init() -> void:
	var flow = TexasTableFlow.new()
	flow.reset_table()
	flow.start_new_hand(501)

	var first_dealer: int = int(flow.hand_data.get("dealer_seat", -1))
	var winner_before: int = int(flow.get_seat_data(1).get("chips", 0))
	_prepare_two_player_showdown(flow)
	flow.finish_hand()

	_assert(String(flow.table_state) == TexasTableFlow.HAND_OVER, "finish_hand must enter HAND_OVER")
	_assert(int(flow.hand_data.get("pot", -1)) == 0, "finish_hand must clear pot")
	_assert(int(flow.hand_data.get("current_bet", -1)) == 0, "finish_hand must clear hand current_bet")
	_assert(Array(flow.hand_data.get("acted_this_round", [1])).is_empty(), "finish_hand must clear acted_this_round")
	_assert(Array(flow.hand_data.get("winner_seats", [])).has(1), "seat 1 should win with royal flush")
	_assert(int(flow.get_seat_data(1).get("chips", 0)) == winner_before + 1000, "winner must receive full pot")
	_assert(int(Dictionary(flow.hand_data.get("settlement", {})).get("pot_before_settlement", 0)) == 1000, "settlement must record pot before settlement")
	_assert(int(Dictionary(flow.hand_data.get("settlement", {})).get("pot_after_settlement", -1)) == 0, "settlement must record pot after settlement")
	_assert(_all_player_bets_clear(flow), "finish_hand must clear every player current_bet")
	_assert(_log_contains(flow.table_log, "wins 1000"), "winner log must include awarded pot")

	flow.reset_table()
	flow.start_new_hand(601)
	_prepare_river_completion(flow)
	var river_winner_before: int = int(flow.get_seat_data(1).get("chips", 0))
	flow.advance_stage()
	_assert(String(flow.table_state) == TexasTableFlow.HAND_OVER, "river completion must settle into HAND_OVER")
	_assert(int(flow.hand_data.get("current_bet", -1)) == 0, "river completion must clear current_bet")
	_assert(int(flow.hand_data.get("pot", -1)) == 0, "river completion must clear pot after settlement")
	_assert(_all_player_bets_clear(flow), "river completion must clear all player current_bet")
	_assert(int(flow.get_seat_data(1).get("chips", 0)) == river_winner_before + 1000, "river winner must receive pot exactly once")

	flow.start_new_hand(502)
	var next_dealer: int = int(flow.hand_data.get("dealer_seat", -1))
	_assert(String(flow.table_state) == TexasTableFlow.PREFLOP, "next hand must start from HAND_OVER")
	_assert(next_dealer != first_dealer, "dealer must move clockwise on the next hand")
	_assert(Array(flow.hand_data.get("community_cards", [])).is_empty(), "next hand must clear community cards")
	_assert(int(flow.hand_data.get("pot", 0)) == 75, "next hand must start with only fresh blinds in pot")
	_assert(int(flow.hand_data.get("current_bet", 0)) == flow.big_blind, "next hand current_bet must be fresh big blind only")

	print("Texas table showdown settlement smoke test passed.")
	quit(0)


func _prepare_two_player_showdown(flow) -> void:
	for i in flow.seats.size():
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", 0))
		if seat_id == 1:
			seat["status"] = TexasTableFlow.PLAYING
			seat["hole_cards"] = [
				{"rank": "T", "suit": "spades", "code": "TS"},
				{"rank": "3", "suit": "diamonds", "code": "3D"},
			]
		elif seat_id == 2:
			seat["status"] = TexasTableFlow.PLAYING
			seat["hole_cards"] = [
				{"rank": "A", "suit": "hearts", "code": "AH"},
				{"rank": "A", "suit": "diamonds", "code": "AD"},
			]
		elif String(seat.get("status", "")) != TexasTableFlow.EMPTY:
			seat["status"] = TexasTableFlow.FOLDED
		seat["current_bet"] = 0
		flow.seats[i] = seat
	flow.table_state = TexasTableFlow.SHOWDOWN
	flow.hand_data["stage"] = TexasTableFlow.SHOWDOWN
	flow.hand_data["pot"] = 1000
	flow.hand_data["current_bet"] = 0
	flow.hand_data["community_cards"] = [
		{"rank": "A", "suit": "spades", "code": "AS", "face_up": true},
		{"rank": "K", "suit": "spades", "code": "KS", "face_up": true},
		{"rank": "Q", "suit": "spades", "code": "QS", "face_up": true},
		{"rank": "J", "suit": "spades", "code": "JS", "face_up": true},
		{"rank": "2", "suit": "clubs", "code": "2C", "face_up": true},
	]


func _prepare_river_completion(flow) -> void:
	_prepare_two_player_showdown(flow)
	flow.table_state = TexasTableFlow.RIVER
	flow.hand_data["stage"] = TexasTableFlow.RIVER
	flow.hand_data["pot"] = 1000
	flow.hand_data["current_bet"] = 50
	flow.hand_data["current_turn_seat"] = 2
	flow.hand_data["acted_this_round"] = [1, 2]
	flow.hand_data["community_cards"] = [
		{"rank": "A", "suit": "spades", "code": "AS", "face_up": true},
		{"rank": "K", "suit": "spades", "code": "KS", "face_up": true},
		{"rank": "Q", "suit": "spades", "code": "QS", "face_up": true},
		{"rank": "J", "suit": "spades", "code": "JS", "face_up": true},
	]
	flow.hand_data["deck"] = [
		{"rank": "2", "suit": "clubs", "code": "2C", "face_up": false},
	]
	for i in flow.seats.size():
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		if int(seat.get("seat_id", 0)) in [1, 2]:
			seat["current_bet"] = 50
		flow.seats[i] = seat


func _all_player_bets_clear(flow) -> bool:
	for seat in flow.seats:
		if int(Dictionary(seat).get("current_bet", 0)) != 0:
			return false
	return true


func _log_contains(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if line.find(needle) != -1:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
