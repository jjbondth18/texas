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
const RuntimeLayoutEditor := preload("res://scripts/dev/poker_table_runtime_layout_editor.gd")

const DESIGN_SIZE := Vector2(2560, 1000)
const TABLE_BACKGROUND_PATH := "res://assets/poker_table/backgrounds/table_neon_v1.png"

var snapshot := {}
@onready var _content_root: Control = $TableUIRoot
@onready var _seat_layer: Control = $TableUIRoot/TableLayer/SeatLayer
@onready var _dealer_label: Label = $TableUIRoot/TableLayer/CenterBoardPanel/DealerIndicator
@onready var _pot_display: Control = $TableUIRoot/TableLayer/CenterBoardPanel/PotPanel
@onready var _community_board: Control = $TableUIRoot/TableLayer/CenterBoardPanel/CommunityCardsPanel
@onready var _info_panel: PanelContainer = $TableUIRoot/LeftPanel/ChatLogPanel
@onready var _room_info_panel: PanelContainer = $TableUIRoot/LeftPanel/TableInfoPanel
@onready var _status_panel: PanelContainer = $TableUIRoot/RightPanel/PlayerStatusList
@onready var _action_bar: ActionBar = $TableUIRoot/BottomPlayerPanel

var _seats := {}
var _chips_label_left: Label
var _profit_label_left: Label
var _winrate_label_left: Label
var _timer_label: Label
var _local_cards_root: Control
var _capture_output := ""
var _layout_editor
var _layout_targets_registered := false

func _ready() -> void:
	_hide_editor_guides(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var args := _all_cmdline_args()
	if args.has("--training") or args.has("--table-training"):
		TableLaunchContext.configure("training", "mock_table_001")
		
	_build_scene()
	_load_phase(_phase_from_args())
	_apply_capture_args()

func _input(event: InputEvent) -> void:
	if _layout_editor and _layout_editor.handle_key_event(event):
		get_viewport().set_input_as_handled()
		return
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
	# Load background texture statically defined in scene
	var bg_rect := $BackgroundLayer/TableBackground
	bg_rect.texture = _load_texture(TABLE_BACKGROUND_PATH)
	
	# Setup seats map from static scene nodes
	_seats[1] = $TableUIRoot/TableLayer/SeatLayer/Seat1Panel
	_seats[2] = $TableUIRoot/TableLayer/SeatLayer/Seat2Panel
	_seats[3] = $TableUIRoot/TableLayer/SeatLayer/Seat3Panel
	_seats[4] = $TableUIRoot/TableLayer/SeatLayer/Seat4Panel
	_seats[5] = $TableUIRoot/TableLayer/SeatLayer/Seat5Panel
	_seats[6] = $TableUIRoot/TableLayer/SeatLayer/Seat6Panel
	_seats[7] = $TableUIRoot/TableLayer/SeatLayer/Seat7Panel
	_seats[8] = $TableUIRoot/TableLayer/SeatLayer/Seat8Panel
	_seats[9] = $TableUIRoot/TableLayer/SeatLayer/Seat9Panel
	
	_dealer_label.add_theme_font_size_override("font_size", 20)
	_dealer_label.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
	
	# Connect signals
	_status_panel.exit_table_requested.connect(_return_home)
	_action_bar.action_pressed.connect(_on_action_pressed)
	
	# Wire up variables from _action_bar to keep existing logic working without change
	_chips_label_left = _action_bar.chips_label
	_profit_label_left = _action_bar.profit_label
	_winrate_label_left = _action_bar.winrate_label
	_timer_label = _action_bar.timer_label
	_local_cards_root = _action_bar.local_cards_root
	
	_layout()
	_build_layout_editor()

func _layout() -> void:
	if _content_root == null:
		return
	var scale: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_content_root.scale = Vector2(scale, scale)
	_content_root.position = (size - DESIGN_SIZE * scale) * 0.5
	_content_root.size = DESIGN_SIZE
	_update_layout_editor_space(scale)

func _set_design_rect(node: Control, rect: Rect2, scale: float) -> void:
	node.position = rect.position * scale
	node.size = rect.size * scale

func _build_layout_editor() -> void:
	if _layout_editor != null:
		return
	_layout_editor = RuntimeLayoutEditor.new()
	_layout_editor.name = "PokerTableRuntimeLayoutEditor"
	add_child(_layout_editor)
	_update_layout_editor_space(minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y))
	_register_layout_editor_targets()

func _update_layout_editor_space(scale: float) -> void:
	if _layout_editor == null:
		return
	_layout_editor.configure_layout_space(_content_root.global_position if _content_root else Vector2.ZERO, scale)
	if _layout_targets_registered:
		_layout_editor.apply_saved_layout()

func _register_layout_editor_targets() -> void:
	if _layout_editor == null:
		return
	var targets := {
		"seat_1": _seats.get(1),
		"seat_2": _seats.get(2),
		"seat_3": _seats.get(3),
		"seat_4": _seats.get(4),
		"seat_5_local": _seats.get(5),
		"seat_6": _seats.get(6),
		"seat_7": _seats.get(7),
		"seat_8": _seats.get(8),
		"seat_9": _seats.get(9),
		"left_info_panel": _info_panel,
		"right_status_panel": _status_panel,
		"local_player_info_panel": _room_info_panel,
		"local_hole_cards": _local_cards_root,
		"action_bar": _action_bar,
		"community_board": _community_board,
		"pot_display": _pot_display,
		"dealer_indicator": _dealer_label,
		"turn_timer": _timer_label,
	}
	_layout_editor.register_targets(targets)
	_layout_targets_registered = true

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
	
	var pot_data = snapshot.get("pot_data", snapshot.get("pot", 0))
	_pot_display.set_pot(pot_data)
	
	var pot_val := 0
	if pot_data is Dictionary:
		pot_val = int(pot_data.get("total", 0))
	else:
		pot_val = int(pot_data)
		
	_action_bar.set_actions(Array(snapshot.get("available_actions", [])), pot_val)
	_info_panel.set_info(Array(snapshot.get("hand_history", [])), Array(snapshot.get("system_messages", [])))
	if _room_info_panel:
		_room_info_panel.set_room_info(
			snapshot.get("table_id", "mock_table_001"),
			snapshot.get("blinds_text", "25/50")
		)
	_status_panel.set_status(snapshot)
	_timer_label.text = "TURN TIMER  %ds" % int(snapshot.get("turn_seconds", 15))
	
	var local := Dictionary(snapshot.get("local_player", {}))
	
	# Update local stats dynamically in the Left Compartment
	if not local.is_empty():
		var chips := int(local.get("chips", 24500))
		_chips_label_left.text = "Chips: %s" % _format_chips(chips)
		
		# Session Profit/Loss:
		var initial_chips := 20000
		var profit := chips - initial_chips
		if profit >= 0:
			_profit_label_left.text = "+$%s" % _format_chips(profit)
			_profit_label_left.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3)) # Bright Green
		else:
			_profit_label_left.text = "-$%s" % _format_chips(abs(profit))
			_profit_label_left.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Neon Red
			
		# Win Rate estimation based on street phase
		var phase = String(snapshot.get("phase", "preflop")).to_lower()
		var win_rate_str := "54.2%"
		if phase == "flop":
			win_rate_str = "72.8%"
		elif phase == "turn":
			win_rate_str = "85.5%"
		elif phase == "river":
			win_rate_str = "94.1%"
		elif phase == "showdown":
			win_rate_str = "100.0%"
		_winrate_label_left.text = "Win Rate: %s" % win_rate_str
		
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

func _format_chips(value: int) -> String:
	var s := str(value)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func _hide_editor_guides(node: Node) -> void:
	if node.name.begins_with("Guide"):
		if node is Control:
			node.visible = false
	for child in node.get_children():
		_hide_editor_guides(child)
