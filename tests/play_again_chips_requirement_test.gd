extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile := service.get_current_profile()
	profile["total_chips"] = 1000
	profile["chips"] = 1000
	service.save_current_profile(profile)
	TableLaunchContext.configure("quick_play", "mock_table_001", profile, {"buy_in": 5000})

	var table := PokerTableScene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.call("_show_session_result_panel")
	await process_frame
	var play_again: Button = table.get("_session_play_again_button") as Button
	_require(play_again != null and play_again.disabled, "play again must be disabled when profile chips are below buy-in")

	profile["total_chips"] = 5000
	profile["chips"] = 5000
	service.save_current_profile(profile)
	table.call("_show_session_result_panel")
	await process_frame
	_require(play_again != null and not play_again.disabled, "play again must be enabled when profile chips cover buy-in")

	ProfileServiceScript.reset_mock_profile()
	print("Play again chips requirement test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
