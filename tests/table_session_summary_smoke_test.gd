extends SceneTree

const TableSessionScript := preload("res://scripts/data/table_session.gd")

func _initialize() -> void:
	var session := TableSessionScript.new()
	session.configure_from_context({
		"mode": "quick_play",
		"buy_in": 20000,
		"starting_chips": 20000,
		"current_table_chips": 20000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 2,
		"session_start_chips": 20000,
	})
	_require(session.begin_next_hand() == 1, "first hand index must be 1")
	session.record_hand_result({
		"winner_seats": [3],
		"winner_names": ["Seat 3"],
		"win_amount": 450,
		"hand_description": "Two Pair",
		"pot_before_settlement": 450,
		"pot_after_settlement": 0,
	}, 5, 19750)
	_require(not session.is_session_over, "session should continue before max_hands")
	_require(session.begin_next_hand() == 2, "second hand index must be 2")
	session.record_hand_result({
		"winner_seats": [5],
		"winner_names": ["Luna0581"],
		"win_amount": 900,
		"hand_description": "Flush",
		"pot_before_settlement": 900,
		"pot_after_settlement": 0,
	}, 5, 20650)

	_require(session.is_session_over, "session must end at max_hands")
	_require(session.end_reason == "Hands completed", "end reason must be hands completed")
	_require(session.hands_played == 2, "hands_played must be 2")
	_require(session.hands_won == 1, "hands_won must count local wins")
	_require(session.session_end_chips == 20650, "final chips must be recorded")
	_require(session.session_profit == 650, "profit must equal final minus buy-in")
	_require(session.biggest_pot == 900, "biggest pot must be tracked")
	_require(session.best_hand_desc == "Flush", "best hand must be tracked")
	_require(session.last_winner == "Luna0581", "last winner must be tracked")

	print("Table session summary smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
