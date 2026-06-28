extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")
const TexasTableFlowScript := preload("res://scripts/core/texas_table_flow.gd")

func _initialize() -> void:
	TableLaunchContext.configure("quick_play", "mock_table_001", {}, {
		"buy_in": 20000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 5,
	})

	var table := PokerTableScene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	var flow: TexasTableFlow = table.get("_table_flow") as TexasTableFlow
	_require(flow != null, "table flow must exist")
	flow.table_state = TexasTableFlowScript.HAND_OVER
	for i in flow.seats.size():
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", 0))
		if seat_id == 5:
			seat["status"] = TexasTableFlowScript.PLAYING
			seat["chips"] = 12000
		elif String(seat.get("status", "")) != TexasTableFlowScript.EMPTY:
			seat["status"] = TexasTableFlowScript.OUT
			seat["chips"] = 0
		flow.seats[i] = seat

	table.call("_start_next_hand")
	await process_frame

	var session: TableSession = table.get("_table_session") as TableSession
	_require(session != null, "table session must exist")
	_require(session.is_session_over, "not enough eligible players must end session")
	_require(session.end_reason == "Not enough players", "session end reason must be not enough players")

	print("Not enough players session over test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
