extends SceneTree

const TableLaunchContextScript := preload("res://scripts/app/table_launch_context.gd")
const TableSessionScript := preload("res://scripts/data/table_session.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _initialize() -> void:
	var profile := PlayerProfileScript.default_profile()
	TableLaunchContextScript.configure("quick_play", "mock_table_001", profile, {
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"max_hands": 20,
	})

	var context := TableLaunchContextScript.get_current_table_context()
	var session: TableSession = TableSessionScript.from_context(context)
	_require(session.buy_in == 10000, "session buy-in must use setup value")
	_require(session.small_blind == 50, "session small blind must use setup value")
	_require(session.big_blind == 100, "session big blind must use setup value")
	_require(session.max_hands == 20, "session max_hands must use setup value")
	_require(session.begin_next_hand() == 1, "new session must start at hand 1")

	var play_again_context: Dictionary = _fresh_play_again_context(session)
	var play_again_session: TableSession = TableSessionScript.from_context(play_again_context)
	_require(play_again_session.buy_in == 10000, "play again must keep buy-in")
	_require(play_again_session.small_blind == 50, "play again must keep small blind")
	_require(play_again_session.big_blind == 100, "play again must keep big blind")
	_require(play_again_session.max_hands == 20, "play again must keep hand count")
	_require(play_again_session.current_hand_index == 0, "play again must reset hand index")
	_require(play_again_session.begin_next_hand() == 1, "play again first hand must be 1")

	print("Play again context smoke test passed.")
	quit(0)

func _fresh_play_again_context(previous_session: TableSession) -> Dictionary:
	var context := TableLaunchContextScript.get_current_table_context()
	context["buy_in"] = previous_session.buy_in
	context["small_blind"] = previous_session.small_blind
	context["big_blind"] = previous_session.big_blind
	context["max_hands"] = previous_session.max_hands
	context["table_session"] = {
		"mode": previous_session.mode,
		"buy_in": previous_session.buy_in,
		"starting_chips": previous_session.buy_in,
		"current_table_chips": previous_session.buy_in,
		"small_blind": previous_session.small_blind,
		"big_blind": previous_session.big_blind,
		"max_hands": previous_session.max_hands,
		"current_hand_index": 0,
		"session_start_chips": previous_session.buy_in,
		"session_end_chips": previous_session.buy_in,
		"session_profit": 0,
		"hands_played": 0,
		"hands_won": 0,
		"biggest_pot": 0,
		"best_hand_desc": "-",
		"is_session_over": false,
		"end_reason": "",
		"last_winner": "-",
		"last_win_amount": 0,
	}
	return context

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
