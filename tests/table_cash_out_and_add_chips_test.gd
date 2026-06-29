extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")

func _initialize() -> void:
	await _test_exit_refunds_remaining_chips()
	await _test_exit_after_loss_refunds_remaining()
	await _test_exit_no_double_refund()
	await _test_add_chips_max_button()
	await _test_add_chips_does_not_spawn_duplicate_panel()
	await _test_add_chips_option_disabled()
	ProfileServiceScript.reset_mock_profile()
	TableLaunchContext.clear_table_session()
	print("Table cash out and Add Chips test passed.")
	quit(0)

func _test_exit_refunds_remaining_chips() -> void:
	var service := _set_wallet(24500)
	var profile_after_buy_in: Dictionary = service.deduct_table_buy_in(20000)
	var table := await _make_table(profile_after_buy_in, 20000, true)
	_set_local_chips(table, 20000)
	table.call("_cash_out_remaining_table_chips_to_wallet")
	var profile: Dictionary = service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(profile) == 24500, "exit without betting must refund full remaining table chips")
	_require(_session_chips(table) == 0, "exit cash out must zero session table chips")
	_dispose_table(table)

func _test_exit_after_loss_refunds_remaining() -> void:
	var service := _set_wallet(24500)
	var profile_after_buy_in: Dictionary = service.deduct_table_buy_in(20000)
	var table := await _make_table(profile_after_buy_in, 20000, true)
	_set_local_chips(table, 18500)
	table.call("_cash_out_remaining_table_chips_to_wallet")
	var profile: Dictionary = service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(profile) == 23000, "exit after loss must refund only remaining table chips")
	_dispose_table(table)

func _test_exit_no_double_refund() -> void:
	var service := _set_wallet(24500)
	var profile_after_buy_in: Dictionary = service.deduct_table_buy_in(20000)
	var table := await _make_table(profile_after_buy_in, 20000, true)
	_set_local_chips(table, 18500)
	table.call("_cash_out_remaining_table_chips_to_wallet")
	table.call("_cash_out_remaining_table_chips_to_wallet")
	var profile: Dictionary = service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(profile) == 23000, "exit cash out must not refund twice")
	_dispose_table(table)

func _test_add_chips_max_button() -> void:
	var service := _set_wallet(500)
	var table := await _make_table(service.get_current_profile(), 10000, false)
	_set_local_chips(table, 10000)
	table.call("_toggle_add_chips_panel")
	await process_frame
	var max_button: Button = _find_button(table.get("_add_chips_panel") as Node, "MAX")
	_require(max_button != null and not max_button.disabled, "MAX must be enabled when wallet has any chips")
	max_button.pressed.emit()
	await process_frame
	await process_frame
	var profile: Dictionary = service.get_current_profile()
	_require(PlayerProfileScript.get_total_chips(profile) == 0, "MAX must move all remaining wallet chips")
	_require(_session_chips(table) == 10500, "MAX must add wallet chips to table stack")
	_dispose_table(table)

func _test_add_chips_does_not_spawn_duplicate_panel() -> void:
	var service := _set_wallet(2500)
	var table := await _make_table(service.get_current_profile(), 10000, false)
	_set_local_chips(table, 10000)
	table.call("_toggle_add_chips_panel")
	await process_frame
	var panel: PanelContainer = table.get("_add_chips_panel") as PanelContainer
	var before_count: int = _count_nodes_named(panel.get_parent(), "AddChipsPopover")
	var before_position: Vector2 = panel.global_position
	var button: Button = _find_button(panel, "+1,000")
	_require(button != null and not button.disabled, "+1,000 must be enabled with 2,500 wallet chips")
	button.pressed.emit()
	await process_frame
	await process_frame
	var after_count: int = _count_nodes_named(panel.get_parent(), "AddChipsPopover")
	_require(after_count == before_count and after_count == 1, "Add Chips transfer must not spawn duplicate popovers")
	_require(panel.global_position.distance_to(Vector2.ZERO) > 64.0, "Add Chips popover must not jump to screen origin")
	_require(panel.global_position.distance_to(before_position) < 32.0, "Add Chips popover must stay anchored near the button after transfer")
	_dispose_table(table)

func _test_add_chips_option_disabled() -> void:
	var service := _set_wallet(1500)
	var table := await _make_table(service.get_current_profile(), 10000, false)
	table.call("_toggle_add_chips_panel")
	await process_frame
	var panel: PanelContainer = table.get("_add_chips_panel") as PanelContainer
	var plus_1000: Button = _find_button(panel, "+1,000")
	var plus_5000: Button = _find_button(panel, "+5,000")
	var plus_10000: Button = _find_button(panel, "+10,000")
	var max_button: Button = _find_button(panel, "MAX")
	_require(plus_1000 != null and not plus_1000.disabled, "+1,000 must be enabled with 1,500 wallet chips")
	_require(plus_5000 != null and plus_5000.disabled, "+5,000 must be disabled with 1,500 wallet chips")
	_require(plus_10000 != null and plus_10000.disabled, "+10,000 must be disabled with 1,500 wallet chips")
	_require(max_button != null and not max_button.disabled, "MAX must be enabled with 1,500 wallet chips")
	_dispose_table(table)

func _set_wallet(chips: int) -> ProfileService:
	ProfileServiceScript.reset_mock_profile()
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.get_current_profile()
	profile["total_chips"] = chips
	profile["chips"] = chips
	service.save_current_profile(profile)
	return service

func _make_table(profile: Dictionary, buy_in: int, buy_in_deducted: bool) -> PokerTableScreen:
	TableLaunchContext.clear_table_session()
	TableLaunchContext.configure("quick_play", "mock_table_001", profile, {
		"buy_in": buy_in,
		"small_blind": 25,
		"big_blind": 50,
		"max_hands": 5,
		"buy_in_deducted_from_wallet": buy_in_deducted,
	})
	var table := PokerTableScene.instantiate() as PokerTableScreen
	root.add_child(table)
	await process_frame
	await process_frame
	return table

func _dispose_table(table: Node) -> void:
	if table != null and table.get_parent() != null:
		table.get_parent().remove_child(table)
		table.queue_free()
	TableLaunchContext.clear_table_session()

func _set_local_chips(table: PokerTableScreen, chips: int) -> void:
	var flow: TexasTableFlow = table.get("_table_flow") as TexasTableFlow
	var found_local := false
	for i in range(flow.seats.size()):
		var seat: Dictionary = Dictionary(flow.seats[i]).duplicate(true)
		if not bool(seat.get("is_local", false)):
			continue
		seat["chips"] = chips
		flow.seats[i] = seat
		found_local = true
		break
	if not found_local and not flow.seats.is_empty():
		var fallback_seat: Dictionary = Dictionary(flow.seats[0]).duplicate(true)
		fallback_seat["is_local"] = true
		fallback_seat["player_id"] = PlayerProfileScript.DEFAULT_PLAYER_ID
		fallback_seat["player_name"] = PlayerProfileScript.DEFAULT_PLAYER_NAME
		fallback_seat["chips"] = chips
		flow.seats[0] = fallback_seat
	var session: TableSession = table.get("_table_session") as TableSession
	if session != null:
		session.current_table_chips = chips
		session.session_end_chips = chips
		session.buy_in_deducted_from_wallet = true

func _local_chips(table: PokerTableScreen) -> int:
	var flow: TexasTableFlow = table.get("_table_flow") as TexasTableFlow
	for seat_item in flow.seats:
		var seat: Dictionary = Dictionary(seat_item)
		if bool(seat.get("is_local", false)):
			return int(seat.get("chips", 0))
	return -1

func _session_chips(table: PokerTableScreen) -> int:
	var session: TableSession = table.get("_table_session") as TableSession
	return int(session.current_table_chips) if session != null else -1

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

func _count_nodes_named(node: Node, node_name: String) -> int:
	if node == null:
		return 0
	var count := 1 if node.name == node_name else 0
	for child in node.get_children():
		var child_node: Node = child as Node
		if child_node != null:
			count += _count_nodes_named(child_node, node_name)
	return count

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
