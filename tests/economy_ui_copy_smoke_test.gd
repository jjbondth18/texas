extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	ProfileServiceScript.reset_mock_profile()
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame

	var toast_label: Label = home.get("_toast_label") as Label
	_require(toast_label != null and toast_label.visible, "Daily bonus toast must be shown on first home entry.")
	_require(toast_label.text.find("Daily Login Bonus") != -1, "Daily bonus toast must name the bonus.")
	_require(toast_label.text.find("+1,000 Chips") != -1, "Daily bonus toast must show +1,000 Chips.")

	home.call("_on_mode_selected", "quick_play")
	await process_frame
	var quick_texts: String = _collect_text(home.get("_quick_play_setup_panel") as Node)
	_require(quick_texts.find("Wallet Chips:") != -1, "Quick Play setup must show wallet chips.")
	_require(quick_texts.find("Buy-in will be moved from wallet to table.") != -1, "Quick Play setup must explain wallet-to-table transfer.")
	_require(quick_texts.find("Unused table chips return to wallet after the session.") != -1, "Quick Play setup must explain final chips return.")

	var store_texts: String = _collect_text(home.get("_store_panel") as Node)
	_require(store_texts.find("MOCK PURCHASE / DEV ONLY") != -1, "Store must clearly mark mock purchase mode.")
	_require(store_texts.find("Mock Buy") != -1, "Store buttons must use Mock Buy wording.")
	_require(store_texts.find("Gems are used for premium features such as replay access in future versions.") != -1, "Store must explain future Gems use.")

	root.remove_child(home)
	home.queue_free()
	await process_frame

	var profile: Dictionary = ProfileServiceScript.new().get_current_profile()
	TableLaunchContext.configure("quick_play", "mock_table_001", profile, {
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 5,
		"buy_in_deducted_from_wallet": true,
	})
	var table := PokerTableScene.instantiate()
	root.add_child(table)
	await process_frame
	await process_frame

	var add_panel: PanelContainer = table.get("_add_chips_panel") as PanelContainer
	_require(add_panel != null and add_panel.custom_minimum_size.x <= 340.0, "Add Chips panel must stay a compact popover width.")
	_require(add_panel.custom_minimum_size.y <= 320.0, "Add Chips panel must stay a compact popover height.")
	_require(add_panel.anchor_left == 0.0 and add_panel.anchor_right == 0.0, "Add Chips panel must not use stretch anchors.")
	table.call("_toggle_add_chips_panel")
	await process_frame
	_require(add_panel.visible, "Add Chips panel must open as a visible popover.")
	_require(add_panel.size.x <= 340.0 and add_panel.size.y <= 380.0, "Add Chips panel must not grow into a side rail. size=%s min=%s anchors=(%s,%s,%s,%s) offsets=(%s,%s,%s,%s)" % [add_panel.size, add_panel.custom_minimum_size, add_panel.anchor_left, add_panel.anchor_top, add_panel.anchor_right, add_panel.anchor_bottom, add_panel.offset_left, add_panel.offset_top, add_panel.offset_right, add_panel.offset_bottom])
	for label in ["+1,000", "+5,000", "+10,000", "MAX"]:
		var option_button: Button = _find_button(add_panel, label)
		_require(option_button != null, "Add Chips option %s must be a real Button." % label)
		_require(option_button.size.x >= 120.0 and option_button.size.y >= 40.0, "Add Chips option %s must have a full clickable area." % label)
	var add_texts: String = _collect_text(add_panel)
	_require(add_texts.find("Add Chips to Table") != -1, "Add Chips panel must be table-transfer copy.")
	_require(add_texts.find("Move chips from your wallet to this table.") != -1, "Add Chips panel must explain wallet transfer.")
	_require(add_texts.find("This is not a purchase.") != -1, "Add Chips panel must say it is not a purchase.")
	_require(add_texts.find("Buy Chips") == -1, "Add Chips panel must not say Buy Chips.")
	_require(add_texts.find("Recharge") == -1, "Add Chips panel must not say Recharge.")

	print("Economy UI copy smoke test passed.")
	quit(0)

func _collect_text(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	_collect_text_into(node, parts)
	return "\n".join(parts)

func _collect_text_into(node: Node, parts: Array[String]) -> void:
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	elif node is RichTextLabel:
		parts.append((node as RichTextLabel).text)
	for child in node.get_children():
		var child_node: Node = child as Node
		if child_node != null:
			_collect_text_into(child_node, parts)

func _find_button(node: Node, text_value: String) -> Button:
	if node is Button and (node as Button).text == text_value:
		return node as Button
	for child in node.get_children():
		var child_node: Node = child as Node
		if child_node == null:
			continue
		var found: Button = _find_button(child_node, text_value)
		if found != null:
			return found
	return null

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
