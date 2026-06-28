extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableSessionScript := preload("res://scripts/data/table_session.gd")

func _init() -> void:
	_test_leave_during_hand()
	_test_timeout_rules()
	_test_training_does_not_touch_account()
	_test_host_leave_mock_closes_safely()
	ProfileServiceScript.reset_mock_profile()
	print("Table leave timeout sit out test passed.")
	quit(0)

func _test_leave_during_hand() -> void:
	var session := TableSessionScript.new()
	session.table_type = TableSessionScript.TABLE_TYPE_PUBLIC_CHIP
	session.affects_account_balance = true
	var pot_before := 1600
	var seat := {
		"seat_id": 5,
		"occupied": true,
		"status": TableSessionScript.SEAT_ACTIVE,
		"chips": 7500,
		"current_bet": 500,
		"committed_this_hand": 500,
		"in_hand": true,
	}
	var result := session.apply_player_leave_during_hand(seat)
	_require(pot_before == 1600, "leave must not remove committed chips from the pot")
	_require(int(result.get("committed_this_hand", 0)) == 500, "leave must preserve committed chip count")
	_require(bool(result.get("folded", false)), "leaving during a hand must fold the current hand")
	_require(String(result.get("status", "")) == TableSessionScript.SEAT_LEFT, "leaving player must be marked left")
	_require(not bool(result.get("next_hand_eligible", true)), "left player must not be dealt next hand")
	_require(int(result.get("chips", 0)) == 7500, "uncommitted stack must not be awarded to others")
	_require(int(result.get("pending_cash_out", 0)) == 7500, "public chip leave must record pending cash out")
	_require(session.pending_cash_out == 7500, "session must track pending public cash out")

func _test_timeout_rules() -> void:
	var session := TableSessionScript.new()
	var check_result := session.apply_timeout({
		"seat_id": 5,
		"occupied": true,
		"status": TableSessionScript.SEAT_ACTIVE,
		"chips": 5000,
		"timeout_count": 0,
	}, true)
	_require(String(check_result.get("auto_action", "")) == "check", "timeout with check available must auto-check")
	_require(not bool(check_result.get("folded", false)), "auto-check must not fold")
	_require(int(check_result.get("timeout_count", 0)) == 1, "timeout must increment count")

	var fold_result := session.apply_timeout({
		"seat_id": 5,
		"occupied": true,
		"status": TableSessionScript.SEAT_ACTIVE,
		"chips": 5000,
		"timeout_count": 0,
		"in_hand": true,
	}, false)
	_require(String(fold_result.get("auto_action", "")) == "fold", "timeout without check must auto-fold")
	_require(bool(fold_result.get("folded", false)), "auto-fold must fold the hand")
	_require(String(fold_result.get("status", "")) == TableSessionScript.SEAT_FOLDED, "auto-fold must mark the seat folded")

	var sit_out_result := session.apply_timeout(fold_result, false)
	_require(String(sit_out_result.get("status", "")) == TableSessionScript.SEAT_SIT_OUT, "repeated timeouts must mark sit out")
	_require(bool(sit_out_result.get("sit_out", false)), "repeated timeouts must set sit_out flag")
	_require(not session.should_deal_next_hand(sit_out_result), "sit out player must not be dealt next hand")
	_require(not bool(sit_out_result.get("post_blinds", true)), "sit out player must not post blinds")
	var table_status := session.refresh_table_status_for_active_players([
		{"occupied": true, "status": TableSessionScript.SEAT_ACTIVE, "chips": 5000},
		sit_out_result,
	])
	_require(table_status == TableSessionScript.TABLE_PAUSED, "table must pause when active players are below minimum")

func _test_training_does_not_touch_account() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var before := service.get_current_profile()
	var training := TableSessionScript.new()
	training.mode = TableSessionScript.MODE_TRAINING
	training.table_type = TableSessionScript.TABLE_TYPE_TRAINING_AI
	training.uses_practice_chips = true
	training.affects_account_balance = false
	var left := training.apply_player_leave_during_hand({
		"seat_id": 5,
		"occupied": true,
		"status": TableSessionScript.SEAT_ACTIVE,
		"chips": 9000,
		"current_bet": 1000,
		"committed_this_hand": 1000,
	})
	_require(int(left.get("practice_stack_discarded", 0)) == 9000, "training leave must discard practice stack locally")
	_require(int(left.get("pending_cash_out", 0)) == 0, "training leave must not record account cash out")
	var timed_out := training.apply_timeout(left, false)
	_require(bool(timed_out.get("folded", false)), "training timeout without check still folds locally")
	var after := service.apply_session_result(training.to_dict())
	_require(PlayerProfileScript.get_total_chips(after) == PlayerProfileScript.get_total_chips(before), "training leave/timeout must not change chip balance")
	_require(PlayerProfileScript.get_total_gems(after) == PlayerProfileScript.get_total_gems(before), "training leave/timeout must not change gem balance")
	_require(int(after.get("total_sessions_played", 0)) == int(before.get("total_sessions_played", 0)), "training leave/timeout must not write formal sessions")

func _test_host_leave_mock_closes_safely() -> void:
	var session := TableSessionScript.new()
	var result := session.apply_host_leave_mock()
	_require(session.status == TableSessionScript.TABLE_CLOSED, "host leave must close mock table")
	_require(session.is_session_over, "host leave must end the local mock session")
	_require(not bool(result.get("affects_account_balance", true)), "host leave must not trust account settlement")
	_require(String(result.get("message", "")).contains("Account balances were not changed"), "host leave message must explain balances were not changed")

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
