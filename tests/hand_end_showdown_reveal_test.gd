extends SceneTree

const PokerTableScreenPath := "res://scripts/screens/poker_table_screen.gd"
const TexasTableFlowPath := "res://scripts/core/texas_table_flow.gd"

func _init() -> void:
	var table_screen_source: String = _read_source(PokerTableScreenPath)
	var table_flow_source: String = _read_source(TexasTableFlowPath)
	_test_showdown_reveal_state(table_screen_source, table_flow_source)
	_test_everyone_folded_short_result(table_screen_source, table_flow_source)
	_test_training_account_balance_guard(table_screen_source)
	_test_no_duplicate_next_hand_timer(table_screen_source)
	_test_exit_cancels_pending_next_hand(table_screen_source)
	print("Hand end showdown reveal smoke test passed.")
	quit(0)


func _test_showdown_reveal_state(table_screen_source: String, table_flow_source: String) -> void:
	_require(table_flow_source.contains("\"showdown_revealed_player_ids\""), "settlement must carry showdown revealed player ids")
	_require(table_flow_source.contains("\"end_reason\": end_reason"), "settlement must carry hand end reason")
	_require(table_screen_source.contains("_showdown_reveal_active"), "screen must track showdown reveal state")
	_require(table_screen_source.contains("_showdown_revealed_player_ids.has(seat_id)"), "screen must reveal only selected showdown seats")
	_require(table_screen_source.contains("SHOWDOWN_REVEAL_HOLD_SECONDS := 5.0"), "showdown reveal must hold for 5 seconds")
	_require(table_screen_source.contains("_is_showdown_eligible_status(status)"), "showdown reveal must filter eligible active seats")


func _test_everyone_folded_short_result(table_screen_source: String, table_flow_source: String) -> void:
	_require(table_flow_source.contains("\"everyone_folded\""), "fold win must be identified as everyone_folded")
	_require(table_screen_source.contains("FOLD_WIN_HOLD_SECONDS := 2.5"), "fold win result must use shorter hold")
	_require(table_screen_source.contains("Everyone folded."), "fold win message must explain that everyone folded")
	_require(table_screen_source.contains("if end_reason == \"everyone_folded\":\n\t\treturn result"), "fold win must not reveal winner hole cards")


func _test_training_account_balance_guard(table_screen_source: String) -> void:
	_require(table_screen_source.contains("MODE_TRAINING") and table_screen_source.contains("uses_practice_chips"), "training account-balance guard must remain in table cash-out flow")
	_require(not table_screen_source.contains("_apply_session_profit_to_profile()\n\t_begin_hand_result_reveal"), "hand result reveal must not apply profile settlement directly")


func _test_no_duplicate_next_hand_timer(table_screen_source: String) -> void:
	_require(table_screen_source.contains("_pending_next_hand_token += 1"), "next hand scheduling must use a cancellation token")
	_require(table_screen_source.contains("if token != _pending_next_hand_token"), "stale hand result timers must be ignored")
	_require(table_screen_source.contains("if _hand_over_sequence_active:\n\t\treturn"), "hand over handler must not schedule duplicate result timers")


func _test_exit_cancels_pending_next_hand(table_screen_source: String) -> void:
	_require(table_screen_source.contains("func _return_home() -> void:\n\t_cancel_pending_next_hand_timer()"), "exit table must cancel pending next hand timer")
	_require(table_screen_source.contains("func _cancel_pending_next_hand_timer()"), "screen must expose a timer cancellation helper")


func _read_source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot read %s" % path)
		quit(1)
	return file.get_as_text()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
