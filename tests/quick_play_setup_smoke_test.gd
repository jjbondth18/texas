extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")

func _initialize() -> void:
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	home.call("_on_mode_selected", "quick_play")
	await process_frame

	var panel: PanelContainer = home.get("_quick_play_setup_panel") as PanelContainer
	_require(panel != null and panel.visible, "Quick Play must show setup panel instead of opening table immediately.")
	_require(String(home.get("_quick_play_mode")) == "chip", "Quick Play setup must default to Chip Table mode.")

	var mode_buttons: Dictionary = Dictionary(home.get("_quick_mode_buttons"))
	_require(mode_buttons.has("chip") and mode_buttons.has("gem"), "Quick Play setup must offer Chip Table and Gem Match entries.")

	var buy_in_buttons: Dictionary = Dictionary(home.get("_quick_buy_in_buttons"))
	var high_buy_in_button: Button = buy_in_buttons.get(50000) as Button
	_require(high_buy_in_button != null and high_buy_in_button.disabled, "Buy-in above total_chips must be disabled.")

	var hand_count_buttons: Dictionary = Dictionary(home.get("_quick_hand_count_buttons"))
	var five_hand_button: Button = hand_count_buttons.get(5) as Button
	_require(five_hand_button != null, "Quick Play setup must offer 5 hands.")

	home.call("_select_quick_buy_in", 10000)
	home.call("_select_quick_blinds", 50, 100)
	home.call("_select_quick_hand_count", 20)
	_require(int(home.get("_selected_quick_buy_in")) == 10000, "Selected buy-in must update.")
	_require(int(home.get("_selected_quick_small_blind")) == 50, "Selected small blind must update.")
	_require(int(home.get("_selected_quick_big_blind")) == 100, "Selected big blind must update.")
	_require(int(home.get("_selected_quick_max_hands")) == 20, "Selected hand count must update.")

	home.call("_select_quick_play_mode", "gem")
	var chip_settings: VBoxContainer = home.get("_quick_chip_settings_container") as VBoxContainer
	var gem_placeholder: VBoxContainer = home.get("_quick_gem_placeholder_container") as VBoxContainer
	var start_button: Button = home.get("_quick_start_button") as Button
	_require(chip_settings != null and not chip_settings.visible, "Gem Match must hide Chip Table settings.")
	_require(gem_placeholder != null and gem_placeholder.visible, "Gem Match must show the coming soon placeholder.")
	_require(start_button != null and start_button.disabled and start_button.text == "COMING SOON", "Gem Match must disable Start Table.")

	print("Quick play setup smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
