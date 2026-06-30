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
	var chips_label: Label = home.get("_quick_play_setup_chips_label") as Label
	var hint_label: Label = home.get("_quick_play_setup_hint_label") as Label
	_require(chips_label != null and chips_label.text.find("Wallet Chips:") != -1, "Quick Play setup must show wallet chips.")
	_require(hint_label != null and hint_label.text.find("Auto-join a public chip table.") != -1, "Quick Play setup must describe auto-join.")

	var mode_buttons: Dictionary = Dictionary(home.get("_quick_mode_buttons"))
	_require(mode_buttons.has("chip") and mode_buttons.has("gem"), "Quick Play setup must offer Chip Table and Gem Match entries.")

	var buy_in_buttons: Dictionary = Dictionary(home.get("_quick_buy_in_buttons"))
	var blinds_buttons: Dictionary = Dictionary(home.get("_quick_blinds_buttons"))
	var hand_count_buttons: Dictionary = Dictionary(home.get("_quick_hand_count_buttons"))
	_require(buy_in_buttons.is_empty(), "Quick Play setup must not expose Buy-in choices.")
	_require(blinds_buttons.is_empty(), "Quick Play setup must not expose Blinds choices.")
	_require(hand_count_buttons.is_empty(), "Quick Play setup must not expose Hand Count choices.")

	home.call("_select_quick_play_mode", "gem")
	var chip_settings: VBoxContainer = home.get("_quick_chip_settings_container") as VBoxContainer
	var gem_placeholder: VBoxContainer = home.get("_quick_gem_placeholder_container") as VBoxContainer
	var start_button: Button = home.get("_quick_start_button") as Button
	_require(chip_settings != null and not chip_settings.visible, "Gem Match must hide Chip Table settings.")
	_require(gem_placeholder != null and gem_placeholder.visible, "Gem Match must show the coming soon placeholder.")
	_require(start_button != null and start_button.disabled and start_button.text == "COMING SOON", "Gem Match must disable Quick Table join.")

	print("Quick play setup smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
