extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var profile := ProfileServiceScript.new().get_current_profile()
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
	session.session_end_chips = 23450
	session.current_table_chips = 23450
	session.session_profit = 3450
	session.hands_played = 5
	session.current_hand_index = 5
	session.hands_won = 2
	session.biggest_pot = 2700
	session.best_hand_desc = "Flush"
	session.last_winner = "Luna0581"
	session.end_reason = "Hands completed"
	table.call("_show_session_result_panel")
	await process_frame

	var panel: PanelContainer = table.get("_session_result_panel") as PanelContainer
	var text: RichTextLabel = table.get("_session_result_text") as RichTextLabel
	var avatar: TextureRect = table.get("_session_result_avatar") as TextureRect
	var hint: Label = table.get("_session_play_again_hint_label") as Label
	var play_again: Button = table.get("_session_play_again_button") as Button
	_require(panel != null and panel.visible, "session summary panel must be visible")
	_require(text != null and text.text.find("SESSION COMPLETE") == -1, "title should be a dedicated label, not debug-only text")
	_require(text != null and text.text.find("Final Table Chips") != -1, "summary must include final table chips")
	_require(text.text.find("Returned to Wallet") != -1, "summary must include returned-to-wallet amount")
	_require(text.text.find("Session Profit") != -1, "summary must label session profit")
	_require(text.text.find("Hands Won") != -1, "summary must include hands won")
	_require(text.text.find("+3450") != -1, "summary must include positive profit")
	_require(avatar != null and avatar.visible and avatar.texture != null, "summary must show local player avatar")
	_require(hint != null and hint.text == "", "play-again hint should be empty when chips are sufficient")
	_require(play_again != null and not play_again.disabled, "play again must be enabled when profile can afford buy-in")

	print("Session summary panel smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
