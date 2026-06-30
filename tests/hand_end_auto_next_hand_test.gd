extends SceneTree

const TexasTableFlowScript := preload("res://scripts/core/texas_table_flow.gd")

func _init() -> void:
	_test_showdown_river_check_check_reveals_contenders()
	_test_showdown_bet_call_reveals_contenders()
	_test_fold_win_hides_hole_cards()
	_test_screen_auto_next_hand_flow_is_not_manual()
	print("Hand end auto next hand test passed.")
	quit(0)


func _test_showdown_river_check_check_reveals_contenders() -> void:
	var flow := TexasTableFlowScript.new()
	flow.reset_table()
	flow.start_new_hand(1201)
	_keep_only_two_players(flow)
	flow.force_current_hand_to_showdown()
	var settlement: Dictionary = Dictionary(flow.hand_data.get("settlement", {}))
	var revealed: Array = Array(settlement.get("showdown_revealed_player_ids", []))
	_require(String(settlement.get("end_reason", "")) == "showdown", "river check/check style finish must be showdown")
	_require(revealed.size() == 2, "showdown must reveal both remaining contenders")
	_require(revealed.has(1) and revealed.has(5), "showdown must reveal the AI/opponent and local player")
	_require(float(settlement.get("result_hold_seconds", 0.0)) == 5.0, "showdown must schedule 5 second hold")


func _test_showdown_bet_call_reveals_contenders() -> void:
	var flow := TexasTableFlowScript.new()
	flow.reset_table()
	flow.start_new_hand(1202)
	_keep_only_two_players(flow)
	flow.hand_data["pot"] = int(flow.hand_data.get("pot", 0)) + 300
	flow.force_current_hand_to_showdown()
	var settlement: Dictionary = Dictionary(flow.hand_data.get("settlement", {}))
	var revealed: Array = Array(settlement.get("showdown_revealed_player_ids", []))
	_require(String(settlement.get("end_reason", "")) == "showdown", "bet/call style finish must be showdown when two players remain")
	_require(revealed.size() == 2, "bet/call showdown must reveal both remaining players")


func _test_fold_win_hides_hole_cards() -> void:
	var flow := TexasTableFlowScript.new()
	flow.reset_table()
	flow.start_new_hand(1203)
	_keep_only_one_player(flow)
	flow.hand_data["pot"] = 1200
	flow.finish_hand()
	var settlement: Dictionary = Dictionary(flow.hand_data.get("settlement", {}))
	_require(String(settlement.get("end_reason", "")) == "everyone_folded", "single live player must be fold win")
	_require(Array(settlement.get("showdown_revealed_player_ids", [])).is_empty(), "fold win must not force reveal hole cards")
	_require(float(settlement.get("result_hold_seconds", 0.0)) == 2.5, "fold win must schedule shorter hold")


func _test_screen_auto_next_hand_flow_is_not_manual() -> void:
	var source := _read_source("res://scripts/screens/poker_table_screen.gd")
	_require(source.contains("_schedule_next_hand_after_result(_hand_result_hold_seconds)"), "hand result must schedule automatic next hand")
	_require(source.contains("if token != _pending_next_hand_token"), "automatic next hand timer must ignore stale callbacks")
	_require(source.contains("Next hand starting..."), "hand over UI must indicate automatic start")
	_require(not source.contains("Press S to Start Next Hand"), "formal UI must not show Press S next hand prompt")
	_require(source.contains("return TableLaunchContext.allow_debug_tools"), "manual key shortcuts must be disabled unless debug tools are enabled")


func _keep_only_two_players(flow) -> void:
	for i in range(flow.seats.size()):
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", 0))
		if seat_id == 1 or seat_id == 5:
			seat["status"] = TexasTableFlowScript.PLAYING
			seat["chips"] = max(int(seat.get("chips", 0)), 1000)
		else:
			seat["status"] = TexasTableFlowScript.FOLDED
		flow.seats[i] = seat


func _keep_only_one_player(flow) -> void:
	for i in range(flow.seats.size()):
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", 0))
		if seat_id == 5:
			seat["status"] = TexasTableFlowScript.PLAYING
			seat["chips"] = max(int(seat.get("chips", 0)), 1000)
		else:
			seat["status"] = TexasTableFlowScript.FOLDED
		flow.seats[i] = seat


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
