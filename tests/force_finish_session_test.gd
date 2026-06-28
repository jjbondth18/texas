extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	TableLaunchContext.configure("training", "mock_training_table_001")
	TableLaunchContext.allow_debug_tools = true
	TableLaunchContext.buy_in = 20000
	TableLaunchContext.small_blind = 25
	TableLaunchContext.big_blind = 50
	TableLaunchContext.max_hands = 5
	TableLaunchContext.table_session = {
		"mode": "training",
		"buy_in": 20000,
		"starting_chips": 20000,
		"current_table_chips": 20000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 5,
	}

	var table := PokerTableScene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	table.call("_force_finish_current_session")
	await process_frame

	var session: TableSession = table.get("_table_session") as TableSession
	_require(session != null, "table session must exist")
	_require(session.is_session_over, "force finish must mark session over")
	_require(session.end_reason == "Debug force finish", "force finish must set debug end reason")
	_require(session.session_end_chips == session.current_table_chips, "force finish must use current table chips")

	var panel: PanelContainer = table.get("_session_result_panel") as PanelContainer
	_require(panel != null and panel.visible, "force finish must show session summary panel")

	print("Force finish session test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
