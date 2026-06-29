extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile := service.get_current_profile()
	var today: Dictionary = Time.get_datetime_dict_from_system()
	profile["last_daily_reward_date"] = "%04d-%02d-%02d" % [int(today.get("year", 0)), int(today.get("month", 0)), int(today.get("day", 0))]
	profile["daily_reward_claimed_today"] = true
	service.save_current_profile(profile)
	profile = service.get_current_profile()
	var starting_chips: int = PlayerProfileScript.get_total_chips(profile)
	var buy_in_profile: Dictionary = service.deduct_table_buy_in(20000)
	TableLaunchContext.configure("quick_play", "mock_table_001", buy_in_profile, {
		"buy_in": 20000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 5,
		"buy_in_deducted_from_wallet": true,
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
	session.buy_in_deducted_from_wallet = true
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
