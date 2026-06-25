extends Control
class_name PokerTableScreen

const MockTableSimulation := preload("res://scripts/demo/mock_table_simulation.gd")
const PokerSeatScene := preload("res://scenes/components/poker_seat.tscn")
const CommunityBoardScene := preload("res://scenes/components/community_board.tscn")
const ActionBarScene := preload("res://scenes/components/action_bar.tscn")
const InfoPanelScene := preload("res://scenes/components/table_info_panel.tscn")
const StatusPanelScene := preload("res://scenes/components/table_status_panel.tscn")
const PotDisplayScene := preload("res://scenes/components/pot_display.tscn")
const CardViewScene := preload("res://scenes/components/card_view.tscn")
const ScreenNavigator := preload("res://scripts/app/screen_navigator.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")
const RoomInfoPanelScene := preload("res://scripts/components/table_room_info_panel.gd")

const DESIGN_SIZE := Vector2(2560, 1000)
const TABLE_BACKGROUND_PATH := "res://assets/poker_table/backgrounds/table_neon_v1.png"

var snapshot := {}
var _content_root: Control
var _seat_layer: Control
var _seats := {}
var _community_board
var _pot_display
var _action_bar
var _info_panel
var _room_info_panel: PanelContainer
var _status_panel
var _timer_label: Label
var _dealer_label: Label
var _local_cards_root: HBoxContainer
var _local_controls_container: VBoxContainer
var _capture_output := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var args := _all_cmdline_args()
	if args.has("--training") or args.has("--table-training"):
		TableLaunchContext.configure("training", "mock_table_001")
		
	_build_scene()
	_load_phase(_phase_from_args())
	_apply_capture_args()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_return_home()
			KEY_1:
				_load_phase("preflop")
			KEY_2:
				_load_phase("flop")
			KEY_3:
				_load_phase("turn")
			KEY_4:
				_load_phase("river")
			KEY_5:
				_load_phase("showdown")
			KEY_R:
				_load_phase("preflop")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

func _build_scene() -> void:
	var bg := TextureRect.new()
	bg.name = "TableBackground"
	bg.texture = _load_texture(TABLE_BACKGROUND_PATH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_content_root = Control.new()
	_content_root.name = "TableUIRoot"
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_root)

	_info_panel = InfoPanelScene.instantiate()
	_info_panel.name = "LeftInfoPanel"
	_content_root.add_child(_info_panel)

	_room_info_panel = RoomInfoPanelScene.new()
	_room_info_panel.name = "LeftRoomInfoPanel"
	_content_root.add_child(_room_info_panel)

	_status_panel = StatusPanelScene.instantiate()
	_status_panel.name = "RightStatusPanel"
	_status_panel.exit_table_requested.connect(_return_home)
	_content_root.add_child(_status_panel)

	_seat_layer = Control.new()
	_seat_layer.name = "SeatLayer"
	_seat_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seat_layer.z_index = 1
	_content_root.add_child(_seat_layer)
	for i in range(1, 10):
		var seat = PokerSeatScene.instantiate()
		seat.name = "Seat%d%s" % [i, "_Local" if i == 5 else ""]
		_seat_layer.add_child(seat)
		_seats[i] = seat

	_dealer_label = Label.new()
	_dealer_label.name = "DealerIndicator"
	_dealer_label.text = "DEALER"
	_dealer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dealer_label.add_theme_font_size_override("font_size", 20)
	_dealer_label.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
	_content_root.add_child(_dealer_label)

	_pot_display = PotDisplayScene.instantiate()
	_content_root.add_child(_pot_display)

	_community_board = CommunityBoardScene.instantiate()
	_content_root.add_child(_community_board)

	_local_controls_container = VBoxContainer.new()
	_local_controls_container.name = "LocalControlsContainer"
	_local_controls_container.add_theme_constant_override("separation", 6)
	_local_controls_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_local_controls_container.z_index = 5
	_content_root.add_child(_local_controls_container)

	_local_cards_root = HBoxContainer.new()
	_local_cards_root.name = "LocalHoleCards"
	_local_cards_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_local_cards_root.add_theme_constant_override("separation", 14)
	_local_cards_root.custom_minimum_size = Vector2(380, 108)
	_local_cards_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_local_controls_container.add_child(_local_cards_root)
	for i in range(2):
		var card = CardViewScene.instantiate()
		card.custom_minimum_size = Vector2(78, 108)
		_local_cards_root.add_child(card)

	_timer_label = Label.new()
	_timer_label.name = "TurnTimer"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 24)
	_timer_label.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
	_timer_label.custom_minimum_size = Vector2(300, 30)
	_timer_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_local_controls_container.add_child(_timer_label)

	_action_bar = ActionBarScene.instantiate()
	_action_bar.action_pressed.connect(_on_action_pressed)
	_action_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_local_controls_container.add_child(_action_bar)
	_layout()

func _layout() -> void:
	if _content_root == null:
		return
	var scale: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var content_size: Vector2 = DESIGN_SIZE * scale
	_content_root.position = (size - content_size) * 0.5
	_content_root.size = content_size

	_set_design_rect(_room_info_panel, Rect2(0, 0, 320, 220), scale)
	_set_design_rect(_info_panel, Rect2(0, 240, 320, 760), scale)
	_set_design_rect(_status_panel, Rect2(2240, 0, 320, 1000), scale)
	_set_design_rect(_seat_layer, Rect2(0, 0, 2560, 1000), scale)
	_set_design_rect(_dealer_label, Rect2(1150, 60, 260, 40), scale)
	_set_design_rect(_pot_display, Rect2(1130, 330, 300, 82), scale)
	_set_design_rect(_community_board, Rect2(880, 430, 800, 140), scale)
	# Position the local controls container with cards, timer and action bar
	_set_design_rect(_local_controls_container, Rect2(770, 785, 1020, 215), scale)

	var normal_seat_size := Vector2(200, 80)
	var local_seat_size := Vector2(200, 150)

	var fixed_positions := {
		1: Vector2(1620, 190),  # 1号位：右上转角
		2: Vector2(1920, 310),  # 2号位：右侧上沿
		3: Vector2(2150, 520),  # 3号位：右侧正中！无条件往右边推到底，拉开大跨度！
		4: Vector2(1880, 750),  # 4号位：右下转角！彻底从5号和3号的夹缝里解放出来！
		5: Vector2(1280, 840),  # 5号位：本地玩家 You！死死压在底线正中央！
		6: Vector2(680, 750),   # 6号位：左下转角！与4号位严格镜像对齐！
		7: Vector2(410, 520),   # 7号位：左侧正中！无条件往左边推到底！
		8: Vector2(640, 310),   # 8号位：左侧上沿！与2号位严格中线镜像！
		9: Vector2(940, 190)    # 9号位：左上转角！与1号位严格镜像！
	}

	for visual_position in range(1, 10):
		var pos: Vector2 = fixed_positions[visual_position]
		var size_val := local_seat_size if visual_position == 5 else normal_seat_size
		var rect: Rect2
		if visual_position == 5:
			rect = Rect2(pos - Vector2(100, 60), size_val)
		else:
			rect = Rect2(pos - size_val * 0.5, size_val)
		_set_design_rect(_seats[visual_position], rect, scale)

func _set_design_rect(node: Control, rect: Rect2, scale: float) -> void:
	node.position = rect.position * scale
	node.size = rect.size * scale

func _load_phase(phase: String) -> void:
	snapshot = MockTableSimulation.get_phase_snapshot(phase)
	_apply_launch_context(snapshot)
	_refresh()

func _refresh() -> void:
	for seat_data in Array(snapshot.get("seats", [])):
		var data := Dictionary(seat_data)
		var visual_position := int(data.get("visual_position", data.get("seat_index", 0)))
		if _seats.has(visual_position):
			_seats[visual_position].set_seat_data(data)
	_community_board.set_cards(Array(snapshot.get("community_cards", [])))
	_pot_display.set_pot(snapshot.get("pot_data", snapshot.get("pot", 0)))
	_action_bar.set_actions(Array(snapshot.get("available_actions", [])))
	_info_panel.set_info(Array(snapshot.get("hand_history", [])), Array(snapshot.get("system_messages", [])))
	if _room_info_panel:
		_room_info_panel.set_room_info(
			snapshot.get("table_id", "mock_table_001"),
			snapshot.get("blinds_text", "25/50")
		)
	_status_panel.set_status(snapshot)
	_timer_label.text = "TURN TIMER  %ds" % int(snapshot.get("turn_seconds", 15))
	var local := Dictionary(snapshot.get("local_player", {}))
	var cards := Array(local.get("cards", []))
	for i in range(_local_cards_root.get_child_count()):
		var card = _local_cards_root.get_child(i)
		card.visible = i < cards.size()
		if i < cards.size():
			card.set_card(Dictionary(cards[i]))

func _on_action_pressed(action: Dictionary) -> void:
	var action_id := String(action.get("id", ""))
	if action_id in ["call", "bet", "raise", "all_in"] and not action.has("amount"):
		action["amount"] = int(action.get("min", 50))
	snapshot = MockTableSimulation.apply_mock_action(snapshot, action)
	_refresh()

func _phase_from_args() -> String:
	var args := _all_cmdline_args()
	var index := args.find("--table-phase")
	if index >= 0 and index + 1 < args.size():
		return String(args[index + 1])
	index = args.find("--capture-table-phase")
	if index >= 0 and index + 1 < args.size():
		return String(args[index + 1])
	return "preflop"

func _apply_capture_args() -> void:
	var args := _all_cmdline_args()
	var output_index := args.find("--capture-output")
	if output_index >= 0 and output_index + 1 < args.size():
		_capture_output = String(args[output_index + 1])
	if _capture_output != "":
		call_deferred("_capture_and_quit")

func _all_cmdline_args() -> Array:
	var args := OS.get_cmdline_args()
	if OS.has_method("get_cmdline_user_args"):
		args.append_array(OS.get_cmdline_user_args())
	return args

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Failed to load table background: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(_capture_output)
	get_tree().quit()

func _return_home() -> void:
	ScreenNavigator.return_home(get_tree())

func _apply_launch_context(target_snapshot: Dictionary) -> void:
	if TableLaunchContext.is_training or TableLaunchContext.launch_mode == "training":
		target_snapshot["table_id"] = TableLaunchContext.table_id
		target_snapshot["table_name"] = "Training Table"
		target_snapshot["connection_status"] = "OFFLINE TRAINING"
		var history: Array = Array(target_snapshot.get("hand_history", [])).duplicate()
		history.insert(0, "Training hint: use Call/Raise to observe mock pot updates")
		target_snapshot["hand_history"] = history
		var messages: Array = Array(target_snapshot.get("system_messages", [])).duplicate()
		messages.insert(0, "Training Mode: AI opponents, no network authority")
		target_snapshot["system_messages"] = messages
		var seats: Array = Array(target_snapshot.get("seats", [])).duplicate(true)
		for i in seats.size():
			var seat := Dictionary(seats[i]).duplicate(true)
			if not bool(seat.get("is_local", false)) and String(seat.get("status", "")) != "empty":
				seat["player_name"] = "AI Seat %d" % int(seat.get("seat_index", 0))
			seats[i] = seat
		target_snapshot["seats"] = seats
		target_snapshot["local_player"] = _find_local_player(seats)
	else:
		target_snapshot["table_id"] = TableLaunchContext.table_id
		target_snapshot["connection_status"] = "Mock online table"

func _find_local_player(seats: Array) -> Dictionary:
	for seat in seats:
		var data := Dictionary(seat)
		if bool(data.get("is_local", false)):
			return data
	return {}
