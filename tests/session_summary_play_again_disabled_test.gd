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
	TableLaunchContext.configure("quick_play", "mock_table_001", profile, {
		"buy_in": 5000,
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
	session.session_end_chips = 0
	session.current_table_chips = 0
	session.session_profit = -5000
	session.end_reason = "Out of chips"
	table.call("_show_session_result_panel")
	await process_frame

	var play_again: Button = table.get("_session_play_again_button") as Button
	var hint: Label = table.get("_session_play_again_hint_label") as Label
	var text: RichTextLabel = table.get("_session_result_text") as RichTextLabel
	_require(play_again != null and play_again.disabled, "play again must be disabled when chips are insufficient")
	_require(hint != null and hint.text == "Not enough chips for this buy-in", "disabled play again must show visible reason")
	_require(text != null and text.text.find("-5000") != -1, "summary must include negative profit")
	_require(text.text.find("Out of chips") != -1, "summary must show out-of-chips end reason")

	ProfileServiceScript.reset_mock_profile()
	print("Session summary play-again disabled test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
