extends SceneTree

const TexasTableFlowScript := preload("res://scripts/core/texas_table_flow.gd")

func _init() -> void:
	var flow := TexasTableFlowScript.new()
	flow.reset_table()
	flow.start_new_hand(801)

	_mark_previous_hand_status(flow, 1, TexasTableFlowScript.FOLDED, 1500)
	_mark_previous_hand_status(flow, 2, TexasTableFlowScript.ALL_IN, 900)
	flow.table_state = TexasTableFlowScript.HAND_OVER

	_require(flow.can_start_hand(), "folded/all-in players with chips must be eligible for next hand")
	flow.start_new_hand(802)

	var seat_1: Dictionary = flow.get_seat_data(1)
	var seat_2: Dictionary = flow.get_seat_data(2)
	_require(String(seat_1.get("status", "")) == TexasTableFlowScript.PLAYING, "folded player must reset to PLAYING")
	_require(String(seat_2.get("status", "")) == TexasTableFlowScript.PLAYING, "all-in player with chips must reset to PLAYING")
	_require(int(seat_1.get("current_bet", -1)) >= 0, "next hand must reset current_bet before blinds")
	_require(Array(seat_1.get("hole_cards", [])).size() == 2, "reset player must receive hole cards")
	_require(Array(seat_2.get("hole_cards", [])).size() == 2, "reset all-in player must receive hole cards")

	print("Next hand resets folded players test passed.")
	quit(0)

func _mark_previous_hand_status(flow: TexasTableFlow, seat_id: int, status: String, chips: int) -> void:
	for i in flow.seats.size():
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		if int(seat.get("seat_id", 0)) != seat_id:
			continue
		seat["status"] = status
		seat["chips"] = chips
		seat["current_bet"] = 0
		seat["hole_cards"] = []
		flow.seats[i] = seat
		return

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
