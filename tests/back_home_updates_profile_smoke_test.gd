extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile := service.get_current_profile()
	var starting_chips: int = PlayerProfileScript.get_total_chips(profile)
	TableLaunchContext.configure("quick_play", "mock_table_001", profile, {
		"buy_in": 20000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 5,
	})

	var table := PokerTableScene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	var session: TableSession = table.get("_table_session") as TableSession
	_require(session != null, "table session must exist")
	session.session_profit = 1250
	session.session_end_chips = session.session_start_chips + 1250
	session.current_table_chips = session.session_end_chips
	session.is_session_over = true
	session.end_reason = "Hands completed"
	table.call("_return_home")
	await process_frame

	var updated_profile := service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(updated_profile) == starting_chips + 1250, "back home must save updated profile chips")
	_require(TableLaunchContext.table_session.is_empty(), "back home must clear old table session context")

	ProfileServiceScript.reset_mock_profile()
	print("Back home updates profile smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
