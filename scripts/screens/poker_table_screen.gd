extends Control
class_name PokerTableScreen

# POKER TABLE UI FREEZE:
# Do not change layout/position/size of existing poker table UI nodes unless the task explicitly asks for visual changes.
# Logic/data binding changes are allowed, but must not move or resize frozen UI components.

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
const LayoutSchema := preload("res://scripts/dev/poker_table_layout_schema.gd")
const TexasTableFlowScript := preload("res://scripts/core/texas_table_flow.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

const DESIGN_SIZE := Vector2(2560, 1000)
const TABLE_BACKGROUND_PATH := "res://assets/poker_table/backgrounds/table_neon_v1.png"
const FLYING_CARD_BACK_PATH := "res://assets/ui/cardback/asset_02.png"
const FLYING_CHIP_PATH := "res://assets/ui/chips/chip_stack_purple.png"
const DEALER_DECK_PATH := "res://assets/ui/cardback/asset_03.png"
const DEFAULT_CROUPIER_PATH := "res://assets/croupier/processed/dealer_01_dog.png"

var snapshot := {}
var _table_flow: TexasTableFlow = TexasTableFlowScript.new()
@onready var _content_root: Control = $UIFloatingLayer
@onready var _table_surface_layer: Control = $TableSurfaceLayer
@onready var _seat_layer: Control = $TableSurfaceLayer/TableLayer/SeatLayer
@onready var _dealer_label: Label = $TableSurfaceLayer/TableLayer/DealerIndicator
@onready var _pot_display: Control = $TableSurfaceLayer/TableLayer/PotDisplay
@onready var _community_board: Control = $TableSurfaceLayer/TableLayer/CommunityBoard
@onready var _chat_panel: TableInfoPanel = $UIFloatingLayer/RightPanel/ChatPanel
@onready var _log_panel: TableInfoPanel = $UIFloatingLayer/RightPanel/LogPanel
@onready var _room_info_panel: PanelContainer = $UIFloatingLayer/LeftPanel/TableInfoPanel
@onready var _status_panel: PanelContainer = $UIFloatingLayer/LeftPanel/PlayerStatusList
@onready var _exit_button: Button = $UIFloatingLayer/RightPanel/ExitTableButton
@onready var _action_bar: ActionBar = $UIFloatingLayer/BottomHud

var _seats := {}
var _chips_label_left: Label
var _profit_label_left: Label
var _winrate_label_left: Label
var _timer_label: Label
var _local_cards_root: Control
var _capture_output := ""
var _top_bar_root: Control
var _top_left_ping_label: Label
var _top_status_bar: Control
var _top_table_label: Label
var _top_blinds_label: Label
var _top_hand_id_label: Label
var _top_dealer_label: Label
var _top_time_label: Label
var _top_right_action_bar: HBoxContainer
var _settings_button: Button
var _add_chips_button: Button
var _settings_panel: PanelContainer
var _popover_layer: Control
var _add_chips_panel: PanelContainer
var _ai_turn_loop_active: bool = false
var _ai_rng := RandomNumberGenerator.new()
var _animation_layer: Control
var _flying_cards_root: Control
var _flying_chips_root: Control
var _dealer_deck_icon: TextureRect
var _croupier_display: TextureRect
var _seen_visual_event_ids := {}
var _visual_pause_until_msec: int = 0
var _hand_over_sequence_active: bool = false
var _next_hand_ready: bool = true
var _auto_next_hand_enabled: bool = false
var _bet_marker_overrides: Dictionary = {}
var _visible_community_cards: Array = []
var _community_reveal_token: int = 0
var _local_cards_reveal_token: int = 0
var _rule_debug_panel: PanelContainer
var _rule_debug_text: RichTextLabel

func _ready() -> void:
	_hide_editor_guides(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ai_rng.randomize()
	
	var args := _all_cmdline_args()
	if args.has("--training") or args.has("--table-training"):
		TableLaunchContext.configure("training", "mock_table_001")
		
	_build_scene()
	_configure_table_flow_from_launch_context()
	_load_phase(_phase_from_args())
	_apply_capture_args()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_D:
			_toggle_rule_debug_panel()
			get_viewport().set_input_as_handled()
			return
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
			KEY_S:
				_start_next_hand()
			KEY_SPACE:
				_start_next_hand()
			KEY_N:
				_advance_test_stage()
			KEY_W:
				_force_test_showdown()
			KEY_R:
				_reset_test_table()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

func _build_scene() -> void:
	# Load background texture statically defined in scene
	var bg_rect := $BackgroundLayer/TableBackground
	bg_rect.texture = _load_texture(TABLE_BACKGROUND_PATH)
	_build_top_action_bar()
	_hide_legacy_top_center_bars()
	call_deferred("_hide_legacy_top_center_bars")
	_build_rule_debug_panel()
	
	# Setup seats map from static scene nodes
	_seats[1] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat1Panel
	_seats[2] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat2Panel
	_seats[3] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat3Panel
	_seats[4] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat4Panel
	_seats[5] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat5Panel
	_seats[6] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat6Panel
	_seats[7] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat7Panel
	_seats[8] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat8Panel
	_seats[9] = $TableSurfaceLayer/TableLayer/SeatLayer/Seat9Panel
	
	_dealer_label.add_theme_font_size_override("font_size", 20)
	_dealer_label.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
	_dealer_label.visible = false
	_build_animation_layer()
	
	# Connect signals
	_exit_button.pressed.connect(_return_home)
	_exit_button.visible = false
	_action_bar.action_pressed.connect(_on_action_pressed)
	
	# Premium neon styling for exit button
	var btn_normal := HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 18)
	var btn_hover := HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.80), Color(1.0, 0.0, 0.5, 1.0), 18)
	_exit_button.add_theme_stylebox_override("normal", btn_normal)
	_exit_button.add_theme_stylebox_override("hover", btn_hover)
	_exit_button.add_theme_stylebox_override("pressed", btn_hover)
	_exit_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_exit_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	_exit_button.add_theme_font_size_override("font_size", 14)
	
	# Wire up variables from _action_bar to keep existing logic working without change
	_chips_label_left = _action_bar.chips_label
	_profit_label_left = _action_bar.profit_label
	_winrate_label_left = _action_bar.winrate_label
	_timer_label = _action_bar.timer_label
	_local_cards_root = _action_bar.local_cards_root
	
	_layout()

func _layout() -> void:
	if _content_root == null:
		return
	var scale: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var design_position := (size - DESIGN_SIZE * scale) * 0.5
	for layer in [_table_surface_layer, _content_root]:
		if layer == null:
			continue
		layer.scale = Vector2(scale, scale)
		layer.position = design_position
		layer.size = DESIGN_SIZE

func _build_animation_layer() -> void:
	var table_layer := $TableSurfaceLayer/TableLayer as Control
	_animation_layer = Control.new()
	_animation_layer.name = "AnimationLayer"
	_animation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_animation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animation_layer.z_index = 80
	table_layer.add_child(_animation_layer)

	_croupier_display = TextureRect.new()
	_croupier_display.name = "CroupierDisplay"
	_croupier_display.texture = _load_texture(DEFAULT_CROUPIER_PATH)
	_croupier_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_croupier_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_croupier_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_croupier_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_croupier_display.size = Vector2(280, 280)
	_croupier_display.z_index = 118
	_animation_layer.add_child(_croupier_display)

	_flying_cards_root = Control.new()
	_flying_cards_root.name = "FlyingCardsRoot"
	_flying_cards_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flying_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flying_cards_root.z_index = 120
	_animation_layer.add_child(_flying_cards_root)

	_flying_chips_root = Control.new()
	_flying_chips_root.name = "FlyingChipsRoot"
	_flying_chips_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flying_chips_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flying_chips_root.z_index = 121
	_animation_layer.add_child(_flying_chips_root)

	_dealer_deck_icon = TextureRect.new()
	_dealer_deck_icon.name = "DealerDeckStack"
	_dealer_deck_icon.texture = _load_texture(DEALER_DECK_PATH)
	_dealer_deck_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dealer_deck_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dealer_deck_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dealer_deck_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dealer_deck_icon.modulate = Color(1, 1, 1, 0.86)
	_dealer_deck_icon.size = Vector2(58, 78)
	_dealer_deck_icon.z_index = 119
	_animation_layer.add_child(_dealer_deck_icon)
	_position_croupier_display()
	_position_dealer_deck_icon()

func _position_croupier_display() -> void:
	if _croupier_display == null:
		return
	var label_center: Vector2 = _animation_layer_local_from_global(_dealer_label.get_global_rect().get_center())
	_croupier_display.position = label_center + Vector2(-_croupier_display.size.x * 0.5, -238.0)
	print("[CroupierDisplay] global_position=%s size=%s" % [
		str(_croupier_display.get_global_rect().position),
		str(_croupier_display.size),
	])

func _position_dealer_deck_icon() -> void:
	if _dealer_deck_icon == null:
		return
	var origin: Vector2 = _dealer_origin()
	_dealer_deck_icon.position = origin + Vector2(78, -38)

func _set_design_rect(node: Control, rect: Rect2, scale: float) -> void:
	node.position = rect.position * scale
	node.size = rect.size * scale

func _apply_saved_major_layout() -> void:
	var loaded := LayoutSchema.load_runtime_config()
	var source := String(loaded.get("source", "default"))
	var path := String(loaded.get("path", ""))
	var config := Dictionary(loaded.get("config", LayoutSchema.default_config()))
	var items := LayoutSchema.merged_items_with_defaults(config)
	if source == "user":
		print("[PokerTableLayout] Loaded user layout config")
	else:
		print("[PokerTableLayout] Loaded default layout config: %s" % path)
	var targets := _major_layout_targets()
	for id in items.keys():
		if not targets.has(id) or targets[id] == null:
			continue
		var rect := LayoutSchema.dict_to_rect(Dictionary(items[id]))
		_apply_design_rect_to_control(targets[id], rect)
		if id == "bottom_hud":
			print("[PokerTableLayout] Applied bottom_hud rect: %s" % rect)

func _major_layout_targets() -> Dictionary:
	return {
		"seat_1": _seats.get(1),
		"seat_2": _seats.get(2),
		"seat_3": _seats.get(3),
		"seat_4": _seats.get(4),
		"seat_5_local": _seats.get(5),
		"seat_6": _seats.get(6),
		"seat_7": _seats.get(7),
		"seat_8": _seats.get(8),
		"seat_9": _seats.get(9),
		"left_panel": $UIFloatingLayer/LeftPanel,
		"right_panel": $UIFloatingLayer/RightPanel,
		"bottom_hud": _action_bar,
		"pot_display": _pot_display,
		"community_board": _community_board,
		"dealer_indicator": _dealer_label,
	}

func _apply_design_rect_to_control(target: Control, design_rect: Rect2) -> void:
	var target_parent := target.get_parent() as Control
	if target_parent == null:
		target.position = design_rect.position
		target.size = design_rect.size
		return
	var parent_design_origin: Vector2 = (target_parent.get_global_rect().position - _content_root.get_global_rect().position) / max(_content_root.scale.x, 0.0001)
	var parent_design_scale: Vector2 = target_parent.get_global_transform().get_scale() / _content_root.get_global_transform().get_scale()
	target.position = (design_rect.position - parent_design_origin) / parent_design_scale
	target.size = design_rect.size / parent_design_scale

func _load_phase(phase: String) -> void:
	if phase.to_lower() == "waiting":
		_configure_table_flow_from_launch_context()
		_table_flow.reset_table()
		_sync_launch_profile_to_table_flow()
		snapshot = _table_flow_to_ui_snapshot(_table_flow.to_snapshot())
	else:
		snapshot = MockTableSimulation.get_phase_snapshot(phase)
	_apply_launch_context(snapshot)
	_refresh()

func _start_test_hand() -> void:
	_hand_over_sequence_active = false
	_next_hand_ready = true
	_reset_visual_hand_state()
	_configure_table_flow_from_launch_context()
	_sync_launch_profile_to_table_flow()
	snapshot = _table_flow_to_ui_snapshot(_table_flow.start_new_hand())
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _start_next_hand() -> void:
	var state: String = String(_table_flow.table_state)
	if state == TexasTableFlowScript.HAND_OVER and not _next_hand_ready:
		return
	if state not in [TexasTableFlowScript.WAITING, TexasTableFlowScript.HAND_OVER]:
		return
	_hand_over_sequence_active = false
	_next_hand_ready = true
	_reset_visual_hand_state()
	_configure_table_flow_from_launch_context()
	_sync_launch_profile_to_table_flow()
	snapshot = _table_flow_to_ui_snapshot(_table_flow.start_new_hand())
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _advance_test_stage() -> void:
	snapshot = _table_flow_to_ui_snapshot(_table_flow.advance_stage())
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _force_test_showdown() -> void:
	if String(_table_flow.table_state) == TexasTableFlowScript.WAITING:
		_sync_launch_profile_to_table_flow()
		_table_flow.start_new_hand()
	var guard: int = 0
	while String(_table_flow.table_state) not in [TexasTableFlowScript.SHOWDOWN, TexasTableFlowScript.HAND_OVER]:
		guard += 1
		if guard > 8:
			break
		_table_flow.advance_stage()
	snapshot = _table_flow_to_ui_snapshot(_table_flow.to_snapshot())
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _reset_test_table() -> void:
	_ai_turn_loop_active = false
	_hand_over_sequence_active = false
	_next_hand_ready = true
	_visual_pause_until_msec = 0
	_reset_visual_hand_state()
	_configure_table_flow_from_launch_context()
	_table_flow.reset_table()
	_sync_launch_profile_to_table_flow()
	snapshot = _table_flow_to_ui_snapshot(_table_flow.to_snapshot())
	_apply_launch_context(snapshot)
	_refresh()

func _sync_launch_profile_to_table_flow() -> void:
	var profile: Dictionary = TableLaunchContext.get_player_profile()
	var local_name: String = PlayerProfileScript.get_player_name(profile)
	var local_avatar_id: String = PlayerProfileScript.get_avatar_id(profile)
	var table_chips: int = PlayerProfileScript.table_buy_in(profile)
	for i in range(_table_flow.seats.size()):
		var seat: Dictionary = Dictionary(_table_flow.seats[i]).duplicate(true)
		if not bool(seat.get("is_local", false)):
			continue
		seat["player_id"] = String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID))
		seat["player_name"] = local_name
		seat["avatar_id"] = local_avatar_id
		if String(_table_flow.table_state) in [TexasTableFlowScript.WAITING, TexasTableFlowScript.HAND_OVER]:
			seat["chips"] = table_chips
		_table_flow.seats[i] = seat
		return

func _table_flow_to_ui_snapshot(source: Dictionary) -> Dictionary:
	var hand: Dictionary = Dictionary(source.get("hand_data", {})).duplicate(true)
	var stage: String = String(source.get("table_state", hand.get("stage", "waiting")))
	var pot_amount: int = int(hand.get("pot", 0))
	var local_seat_index: int = 5
	var seats: Array = []
	for seat_item in Array(source.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		if bool(seat.get("is_local", false)):
			local_seat_index = seat_id
		var avatar_id: String = String(seat.get("avatar_id", ""))
		if avatar_id == "":
			avatar_id = AvatarLibraryScript.avatar_id_for_seat(seat_id, bool(seat.get("is_local", false)))
		var avatar_texture: Texture2D = AvatarLibraryScript.get_avatar_by_id(avatar_id)
		var raw_status: String = String(seat.get("status", "empty"))
		var ui_status: String = "empty" if raw_status == TexasTableFlowScript.EMPTY else ("folded" if raw_status == TexasTableFlowScript.FOLDED else "active")
		var cards: Array[Dictionary] = []
		for card_item in Array(seat.get("hole_cards", [])):
			var card: Dictionary = Dictionary(card_item).duplicate(true)
			card["face_up"] = bool(seat.get("is_local", false)) or stage in [TexasTableFlowScript.SHOWDOWN, TexasTableFlowScript.HAND_OVER]
			cards.append(card)
		seats.append({
			"seat_index": seat_id,
			"seat_id": seat_id,
			"visual_position": MockTableSimulation.visual_position_for_seat_index(seat_id, local_seat_index),
			"player_id": String(seat.get("player_id", "")),
			"player_name": String(seat.get("player_name", "Seat %d" % seat_id)),
			"avatar_id": avatar_id,
			"avatar_texture": avatar_texture,
			"chips": int(seat.get("chips", 0)),
			"current_bet": int(seat.get("current_bet", 0)),
			"status": ui_status,
			"raw_status": raw_status,
			"cards": cards,
			"is_local": bool(seat.get("is_local", false)),
			"is_dealer": bool(seat.get("is_dealer", false)),
			"is_small_blind": bool(seat.get("is_small_blind", false)),
			"is_big_blind": bool(seat.get("is_big_blind", false)),
			"is_turn": seat_id == int(hand.get("current_turn_seat", -1)),
			"last_action": String(seat.get("last_action", "")),
			"last_action_amount": int(seat.get("last_action_amount", 0)),
			"last_action_seq": int(seat.get("last_action_seq", 0)),
			"buy_in": 20000,
		})
	var local_player: Dictionary = _find_local_player(seats)
	return {
		"source_model": "texas_table_flow",
		"table_id": "mock_table_001",
		"table_name": "Neon Table 01",
		"hand_id": String(hand.get("hand_id", "waiting")),
		"blinds_text": "%d / %d" % [_table_flow.small_blind, _table_flow.big_blind],
		"phase": stage,
		"room_state": stage,
		"pot": pot_amount,
		"pot_data": {"main": pot_amount, "side_pots": []},
		"community_cards": Array(hand.get("community_cards", [])).duplicate(true),
		"seats": seats,
		"local_player": local_player,
		"local_seat_index": local_seat_index,
		"turn_seat_index": int(hand.get("current_turn_seat", -1)),
		"turn_seconds": 15,
		"available_actions": _table_flow.get_legal_actions(local_seat_index),
		"hand_history": Array(source.get("table_log", [])).duplicate(),
		"system_messages": ["TexasTableFlow data binding active"],
		"visual_events": Array(hand.get("visual_events", [])).duplicate(true),
		"rule_debug_log": Array(source.get("rule_debug_log", [])).duplicate(),
	}

func _refresh() -> void:
	_hide_legacy_top_center_bars()
	var visual_events: Array = Array(snapshot.get("visual_events", []))
	var has_new_hole_deal: bool = _has_unseen_visual_event(visual_events, "deal_hole")
	var has_new_community_deal: bool = _has_unseen_visual_event(visual_events, "deal_community")
	_prime_collect_bet_overrides(visual_events)
	for seat_data in Array(snapshot.get("seats", [])):
		var data := Dictionary(seat_data)
		var visual_position := int(data.get("visual_position", data.get("seat_index", 0)))
		var seat_id := int(data.get("seat_id", data.get("seat_index", 0)))
		if _bet_marker_overrides.has(seat_id):
			data["current_bet"] = int(_bet_marker_overrides[seat_id])
		if _seats.has(visual_position):
			_seats[visual_position].set_seat_data(data)
				
	var community_cards: Array = Array(snapshot.get("community_cards", []))
	if has_new_community_deal:
		_schedule_community_cards_reveal(community_cards, _deal_reveal_delay(visual_events, "deal_community"))
	else:
		_apply_community_cards(community_cards)
	_play_visual_events(visual_events)
	
	var pot_data = snapshot.get("pot_data", snapshot.get("pot", 0))
	_pot_display.set_pot(pot_data)
	
	var pot_val := 0
	if pot_data is Dictionary:
		pot_val = int(pot_data.get("total", pot_data.get("main", 0)))
	else:
		pot_val = int(pot_data)
		
	_action_bar.set_actions(Array(snapshot.get("available_actions", [])), pot_val)
	_log_panel.set_info(Array(snapshot.get("hand_history", [])), Array(snapshot.get("system_messages", [])))
	if _room_info_panel:
		if _room_info_panel.has_method("set_table_context"):
			_room_info_panel.call(
				"set_table_context",
				String(snapshot.get("phase", "waiting")),
				String(snapshot.get("hand_id", snapshot.get("table_id", "mock_table_001"))),
				int(snapshot.get("local_seat_index", 5)),
				String(snapshot.get("blinds_text", "25/50"))
			)
		else:
			_room_info_panel.set_room_info(
				snapshot.get("table_id", "mock_table_001"),
				snapshot.get("blinds_text", "25/50")
			)
	_status_panel.set_status(snapshot)
	_timer_label.text = "TURN TIMER  %ds" % int(snapshot.get("turn_seconds", 15))
	
	var local := Dictionary(snapshot.get("local_player", {}))
	
	if not local.is_empty():
		_action_bar.set_local_player_info(local, String(snapshot.get("phase", "preflop")))
		if _room_info_panel != null and _room_info_panel.has_method("set_seat"):
			_room_info_panel.call("set_seat", int(local.get("seat_index", snapshot.get("local_seat_index", 5))))
		
	var cards := Array(local.get("cards", []))
	if has_new_hole_deal:
		_schedule_local_cards_reveal(cards, _deal_reveal_delay(visual_events, "deal_hole"))
	else:
		_apply_local_cards(cards)
	_handle_hand_over_state()
	_refresh_rule_debug_panel()

func _on_action_pressed(action: Dictionary) -> void:
	var action_id := String(action.get("id", ""))
	if action_id in ["call", "bet", "raise", "all_in"] and not action.has("amount"):
		action["amount"] = int(action.get("min_amount", action.get("min", 50)))
	if String(snapshot.get("source_model", "")) == "texas_table_flow":
		var local_seat: int = int(snapshot.get("local_seat_index", 5))
		snapshot = _table_flow_to_ui_snapshot(_table_flow.apply_player_action(local_seat, action))
	else:
		snapshot = MockTableSimulation.apply_mock_action(snapshot, action)
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _schedule_ai_turns() -> void:
	if _ai_turn_loop_active:
		return
	if String(snapshot.get("source_model", "")) != "texas_table_flow":
		return
	if not _is_ai_turn_active():
		return
	_ai_turn_loop_active = true
	call_deferred("_run_ai_turn_loop")

func _run_ai_turn_loop() -> void:
	while _is_ai_turn_active():
		var delay: float = _ai_rng.randf_range(0.5, 1.0)
		var remaining_visual_pause: float = max(float(_visual_pause_until_msec - Time.get_ticks_msec()) / 1000.0, 0.0)
		delay = max(delay, remaining_visual_pause)
		await get_tree().create_timer(delay).timeout
		if not _is_ai_turn_active():
			break
		var ai_seat: int = int(_table_flow.hand_data.get("current_turn_seat", -1))
		var action: Dictionary = _choose_ai_action(ai_seat)
		if action.is_empty():
			break
		snapshot = _table_flow_to_ui_snapshot(_table_flow.apply_player_action(ai_seat, action))
		_apply_launch_context(snapshot)
		_refresh()
	_ai_turn_loop_active = false
	if _is_ai_turn_active():
		_schedule_ai_turns()

func _is_ai_turn_active() -> bool:
	var stage: String = String(_table_flow.table_state)
	if stage in [TexasTableFlowScript.WAITING, TexasTableFlowScript.HAND_OVER, TexasTableFlowScript.SHOWDOWN]:
		return false
	var turn_seat: int = int(_table_flow.hand_data.get("current_turn_seat", -1))
	var local_seat: int = int(snapshot.get("local_seat_index", 5))
	return turn_seat > 0 and turn_seat != local_seat

func _choose_ai_action(seat_id: int) -> Dictionary:
	var actions: Array = _table_flow.get_legal_actions(seat_id)
	if actions.is_empty():
		return {}
	var call_action: Dictionary = _find_action(actions, "call")
	var check_action: Dictionary = _find_action(actions, "check")
	var raise_action: Dictionary = _find_action(actions, "raise")
	if raise_action.is_empty():
		raise_action = _find_action(actions, "bet")
	var fold_action: Dictionary = _find_action(actions, "fold")
	var all_in_action: Dictionary = _find_action(actions, "all_in")
	var seat: Dictionary = _table_flow.get_seat_data(seat_id)
	var chips: int = int(seat.get("chips", 0))
	if not call_action.is_empty() and bool(call_action.get("enabled", false)):
		var call_amount: int = int(call_action.get("amount", 0))
		if chips <= call_amount and not all_in_action.is_empty():
			return all_in_action
		var roll: float = _ai_rng.randf()
		if roll < 0.70:
			return call_action
		if roll < 0.90:
			return fold_action
		if not raise_action.is_empty() and bool(raise_action.get("enabled", false)):
			var min_raise: int = int(raise_action.get("min_amount", raise_action.get("amount", 0)))
			raise_action["amount"] = min_raise
			return raise_action
		return call_action
	if not check_action.is_empty() and bool(check_action.get("enabled", false)):
		var check_roll: float = _ai_rng.randf()
		if check_roll < 0.80:
			return check_action
		if not raise_action.is_empty() and bool(raise_action.get("enabled", false)):
			var min_bet: int = int(raise_action.get("min_amount", raise_action.get("amount", _table_flow.big_blind)))
			raise_action["amount"] = min_bet
			return raise_action
		return check_action
	if not all_in_action.is_empty() and bool(all_in_action.get("enabled", false)):
		return all_in_action
	return fold_action

func _find_action(actions: Array, action_id: String) -> Dictionary:
	for action in actions:
		var data: Dictionary = Dictionary(action)
		if String(data.get("id", "")) == action_id:
			return data.duplicate(true)
	return {}

func _play_visual_events(events: Array) -> void:
	if _animation_layer == null:
		return
	_position_croupier_display()
	_position_dealer_deck_icon()
	var deal_order: int = 0
	var deal_delay_offset: float = 0.0
	for event_item in events:
		var event: Dictionary = Dictionary(event_item)
		var event_id: int = int(event.get("id", -1))
		if event_id == -1 or _seen_visual_event_ids.has(event_id):
			continue
		_seen_visual_event_ids[event_id] = true
		var event_type: String = String(event.get("type", ""))
		var seat_id: int = int(event.get("seat_id", -1))
		var action_label: String = String(event.get("action", ""))
		var amount: int = int(event.get("amount", 0))
		match event_type:
			"player_action":
				_show_seat_action_toast(seat_id, action_label, amount)
			"chip_move":
				_play_flying_chip(seat_id)
			"collect_bets":
				deal_delay_offset += _play_collect_bets(event)
			"deal_hole":
				var hole_delay: float = deal_delay_offset + float(deal_order) * 0.14
				_play_flying_card(_dealer_origin(), _seat_animation_point(seat_id), hole_delay, "deal_hole", "seat %d" % seat_id)
				_extend_visual_pause(hole_delay + 0.88)
				deal_order += 1
			"deal_community":
				var board_delay: float = deal_delay_offset + float(deal_order) * 0.14
				var board_index: int = int(event.get("board_index", 0))
				_play_flying_card(_dealer_origin(), _community_card_point(board_index), board_delay, "deal_community", "board slot %d" % (board_index + 1))
				_extend_visual_pause(board_delay + 0.88)
				deal_order += 1


func _has_unseen_visual_event(events: Array, event_type: String) -> bool:
	for event_item in events:
		var event: Dictionary = Dictionary(event_item)
		var event_id: int = int(event.get("id", -1))
		if event_id != -1 and not _seen_visual_event_ids.has(event_id) and String(event.get("type", "")) == event_type:
			return true
	return false


func _deal_reveal_delay(events: Array, event_type: String) -> float:
	var deal_order: int = 0
	var deal_delay_offset: float = 0.0
	var last_delay: float = 0.0
	for event_item in events:
		var event: Dictionary = Dictionary(event_item)
		var event_id: int = int(event.get("id", -1))
		if event_id == -1 or _seen_visual_event_ids.has(event_id):
			continue
		var current_type: String = String(event.get("type", ""))
		if current_type == "collect_bets":
			deal_delay_offset += _collect_bets_duration(event)
		if current_type in ["deal_hole", "deal_community"]:
			if current_type == event_type:
				last_delay = deal_delay_offset + float(deal_order) * 0.14
			deal_order += 1
	return last_delay + 0.56


func _schedule_community_cards_reveal(cards: Array, delay: float) -> void:
	_community_reveal_token += 1
	var token: int = _community_reveal_token
	await get_tree().create_timer(delay).timeout
	if token != _community_reveal_token:
		return
	_apply_community_cards(cards)


func _apply_community_cards(cards: Array) -> void:
	_visible_community_cards = cards.duplicate(true)
	_community_board.set_cards(_visible_community_cards)


func _schedule_local_cards_reveal(cards: Array, delay: float) -> void:
	_local_cards_reveal_token += 1
	var token: int = _local_cards_reveal_token
	_apply_local_cards([])
	await get_tree().create_timer(delay).timeout
	if token != _local_cards_reveal_token:
		return
	_apply_local_cards(cards)


func _apply_local_cards(cards: Array) -> void:
	for i in range(_local_cards_root.get_child_count()):
		var card_node: Node = _local_cards_root.get_child(i)
		var card_control := card_node as Control
		if card_control != null:
			card_control.visible = i < cards.size()
		if i < cards.size() and card_node.has_method("set_card"):
			card_node.call("set_card", Dictionary(cards[i]))


func _reset_visual_hand_state() -> void:
	_bet_marker_overrides.clear()
	_visual_pause_until_msec = 0
	_visible_community_cards.clear()
	_community_reveal_token += 1
	_local_cards_reveal_token += 1
	if _community_board != null:
		_community_board.set_cards([])
	if _local_cards_root != null:
		_apply_local_cards([])


func _prime_collect_bet_overrides(events: Array) -> void:
	for event_item in events:
		var event: Dictionary = Dictionary(event_item)
		var event_id: int = int(event.get("id", -1))
		if event_id == -1 or _seen_visual_event_ids.has(event_id):
			continue
		if String(event.get("type", "")) != "collect_bets":
			continue
		for bet_item in Array(event.get("bets", [])):
			var bet: Dictionary = Dictionary(bet_item)
			var seat_id: int = int(bet.get("seat_id", -1))
			var amount: int = int(bet.get("amount", 0))
			if seat_id > 0 and amount > 0:
				_bet_marker_overrides[seat_id] = amount


func _show_seat_action_toast(seat_id: int, action_label: String, amount: int) -> void:
	var visual_position: int = _visual_position_for_seat_id(seat_id)
	if _seats.has(visual_position) and _seats[visual_position].has_method("show_action_toast"):
		_seats[visual_position].call("show_action_toast", action_label, amount)


func _play_flying_card(start: Vector2, finish: Vector2, delay: float = 0.0, deal_type: String = "deal", target_label: String = "") -> void:
	if _flying_cards_root == null:
		return
	print("%s animation start" % deal_type)
	print("DealerDealOrigin global_position=%s" % str(_dealer_origin_global()))
	print("flying card from origin to %s: %s -> %s z=%d layer_z=%d" % [target_label, start, finish, _flying_cards_root.z_index, _animation_layer.z_index])
	var card := TextureRect.new()
	card.texture = _load_texture(FLYING_CARD_BACK_PATH)
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size = Vector2(72, 108)
	card.z_index = 120
	card.position = start - card.size * 0.5
	card.modulate = Color(1, 1, 1, 0.0)
	card.rotation_degrees = -7.0
	_flying_cards_root.add_child(card)
	var target_pos: Vector2 = finish - card.size * 0.5
	var tween := create_tween().set_parallel(true)
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.chain().set_parallel(true)
	tween.tween_property(card, "position", target_pos, 0.46).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.10)
	tween.tween_property(card, "scale", Vector2(0.86, 0.86), 0.46).from(Vector2(0.42, 0.42))
	tween.tween_property(card, "rotation_degrees", 4.0, 0.46)
	tween.chain().tween_interval(0.10)
	tween.chain().tween_property(card, "modulate:a", 0.0, 0.16)
	tween.finished.connect(func() -> void:
		print("%s animation finished" % deal_type)
		card.queue_free()
	)


func _play_flying_chip(seat_id: int, delay: float = 0.0) -> void:
	if _flying_chips_root == null:
		return
	var chip := TextureRect.new()
	chip.texture = _load_texture(FLYING_CHIP_PATH)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size = Vector2(42, 34)
	chip.z_index = 121
	chip.position = _seat_animation_point(seat_id) - chip.size * 0.5
	chip.modulate = Color(1, 1, 1, 0.95)
	_flying_chips_root.add_child(chip)
	var target: Vector2 = _pot_animation_point() - chip.size * 0.5
	var midpoint: Vector2 = (chip.position + target) * 0.5 + Vector2(0, -34)
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(chip, "position", midpoint, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(chip, "position", target, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(chip, "modulate:a", 0.0, 0.20).set_delay(0.18)
	tween.finished.connect(chip.queue_free)


func _play_collect_bets(event: Dictionary) -> float:
	print("collect_all_bets_to_pot start")
	print("collect bets animation start")
	var bets: Array = Array(event.get("bets", []))
	var longest_delay: float = 0.0
	for i in range(bets.size()):
		var bet: Dictionary = Dictionary(bets[i])
		var seat_id: int = int(bet.get("seat_id", -1))
		var amount: int = int(bet.get("amount", 0))
		print("collecting seat %d bet %d" % [seat_id, amount])
		var delay: float = float(i) * 0.04
		longest_delay = max(longest_delay, delay + 0.42)
		_play_flying_chip(seat_id, delay)
	_extend_visual_pause(longest_delay + 0.25)
	call_deferred("_clear_collected_bet_markers_after_delay", bets, longest_delay)
	return longest_delay + 0.22


func _collect_bets_duration(event: Dictionary) -> float:
	var bets: Array = Array(event.get("bets", []))
	if bets.is_empty():
		return 0.0
	var last_index: int = max(bets.size() - 1, 0)
	return float(last_index) * 0.04 + 0.64


func _clear_collected_bet_markers_after_delay(bets: Array, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	for bet_item in bets:
		var bet: Dictionary = Dictionary(bet_item)
		_bet_marker_overrides.erase(int(bet.get("seat_id", -1)))
	for seat_data in Array(snapshot.get("seats", [])):
		var data := Dictionary(seat_data)
		var visual_position := int(data.get("visual_position", data.get("seat_index", 0)))
		if _seats.has(visual_position):
			_seats[visual_position].set_seat_data(data)
	for seat_data in Array(snapshot.get("seats", [])):
		var data := Dictionary(seat_data)
		print("after clear: seat %d current_bet %d" % [
			int(data.get("seat_id", data.get("seat_index", -1))),
			int(data.get("current_bet", 0)),
		])
	print("collect_all_bets_to_pot finished")
	print("collect bets animation finished")


func _dealer_origin() -> Vector2:
	if _croupier_display != null:
		return _croupier_display.position + Vector2(_croupier_display.size.x * 0.5, _croupier_display.size.y * 0.70)
	if _animation_layer == null or _dealer_label == null:
		return Vector2.ZERO
	return _animation_layer_local_from_global(_dealer_label.get_global_rect().get_center())


func _dealer_origin_global() -> Vector2:
	if _animation_layer == null:
		return _dealer_origin()
	return _animation_layer.get_global_transform() * _dealer_origin()


func _seat_animation_point(seat_id: int) -> Vector2:
	var visual_position: int = _visual_position_for_seat_id(seat_id)
	if _animation_layer == null or not _seats.has(visual_position):
		return _dealer_origin()
	var seat_control := _seats[visual_position] as Control
	return _animation_layer_local_from_global(seat_control.get_global_rect().get_center())


func _pot_animation_point() -> Vector2:
	if _animation_layer == null or _pot_display == null:
		return _dealer_origin()
	return _animation_layer_local_from_global(_pot_display.get_global_rect().get_center())


func _community_card_point(board_index: int) -> Vector2:
	if _animation_layer == null or _community_board == null:
		return _dealer_origin()
	var rect: Rect2 = _community_board.get_global_rect()
	var spacing: float = rect.size.x / 5.0
	var x: float = rect.position.x + spacing * (float(board_index) + 0.5)
	var y: float = rect.position.y + rect.size.y * 0.5
	return _animation_layer_local_from_global(Vector2(x, y))


func _animation_layer_local_from_global(global_point: Vector2) -> Vector2:
	if _animation_layer == null:
		return global_point
	var rect: Rect2 = _animation_layer.get_global_rect()
	var layer_scale: Vector2 = _animation_layer.get_global_transform().get_scale()
	return Vector2(
		(global_point.x - rect.position.x) / max(layer_scale.x, 0.0001),
		(global_point.y - rect.position.y) / max(layer_scale.y, 0.0001)
	)


func _visual_position_for_seat_id(seat_id: int) -> int:
	for seat_item in Array(snapshot.get("seats", [])):
		var data: Dictionary = Dictionary(seat_item)
		if int(data.get("seat_id", data.get("seat_index", 0))) == seat_id:
			return int(data.get("visual_position", data.get("seat_index", seat_id)))
	return seat_id

func _extend_visual_pause(seconds: float) -> void:
	var until_msec: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	_visual_pause_until_msec = max(_visual_pause_until_msec, until_msec)

func _handle_hand_over_state() -> void:
	if String(snapshot.get("source_model", "")) != "texas_table_flow":
		return
	if String(_table_flow.table_state) != TexasTableFlowScript.HAND_OVER:
		_hand_over_sequence_active = false
		return
	if _hand_over_sequence_active:
		return
	_hand_over_sequence_active = true
	_next_hand_ready = false
	call_deferred("_unlock_next_hand_after_showdown_pause")

func _unlock_next_hand_after_showdown_pause() -> void:
	await get_tree().create_timer(2.0).timeout
	if String(_table_flow.table_state) != TexasTableFlowScript.HAND_OVER:
		_hand_over_sequence_active = false
		return
	_next_hand_ready = true
	if _auto_next_hand_enabled:
		_start_next_hand()


func _build_rule_debug_panel() -> void:
	_rule_debug_panel = _content_root.get_node_or_null("PokerRuleDebugPanel") as PanelContainer
	if _rule_debug_panel == null:
		_rule_debug_panel = PanelContainer.new()
		_rule_debug_panel.name = "PokerRuleDebugPanel"
		_rule_debug_panel.position = Vector2(1810, 86)
		_rule_debug_panel.size = Vector2(680, 520)
		_rule_debug_panel.custom_minimum_size = _rule_debug_panel.size
		_rule_debug_panel.z_index = 30
		_rule_debug_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		_rule_debug_panel.add_theme_stylebox_override("panel", _rule_debug_panel_style())
		_content_root.add_child(_rule_debug_panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		_rule_debug_panel.add_child(margin)
		_rule_debug_text = RichTextLabel.new()
		_rule_debug_text.name = "RuleDebugText"
		_rule_debug_text.fit_content = false
		_rule_debug_text.scroll_active = true
		_rule_debug_text.mouse_filter = Control.MOUSE_FILTER_PASS
		_rule_debug_text.add_theme_font_size_override("normal_font_size", 14)
		_rule_debug_text.add_theme_color_override("default_color", Color(0.88, 0.92, 1.0))
		_rule_debug_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rule_debug_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(_rule_debug_text)
	else:
		_rule_debug_text = _rule_debug_panel.get_node_or_null("RuleDebugText") as RichTextLabel
	_rule_debug_panel.visible = false


func _toggle_rule_debug_panel() -> void:
	print("Debug panel toggle requested")
	if _rule_debug_panel == null:
		push_warning("PokerRuleDebugPanel not found; toggle ignored.")
		print("Debug panel not found")
		return
	print("Debug panel found")
	_rule_debug_panel.visible = not _rule_debug_panel.visible
	print("Debug panel visible = %s" % str(_rule_debug_panel.visible))
	_refresh_rule_debug_panel()


func _refresh_rule_debug_panel() -> void:
	if _rule_debug_panel == null or _rule_debug_text == null or not _rule_debug_panel.visible:
		return
	if _table_flow == null:
		_rule_debug_text.text = "NO DEBUG DATA\nmissing texas_table_flow"
		push_warning("PokerRuleDebugPanel refresh skipped: texas_table_flow missing.")
		return
	var hand: Dictionary = Dictionary(_table_flow.hand_data)
	if hand.is_empty() or _table_flow.seats.is_empty():
		_rule_debug_text.text = "NO DEBUG DATA"
		push_warning("PokerRuleDebugPanel refresh skipped: missing hand or seat data.")
		return
	var acted: Array = Array(hand.get("acted_this_round", []))
	var lines: Array[String] = []
	lines.append("POKER RULE DEBUG  (Ctrl+D hide/show)")
	lines.append("state=%s  hand=%s" % [String(_table_flow.table_state), String(hand.get("hand_id", "-"))])
	lines.append("dealer=%d  SB=%d  BB=%d  current_turn=%d" % [
		int(hand.get("dealer_seat", -1)),
		int(hand.get("small_blind_seat", -1)),
		int(hand.get("big_blind_seat", -1)),
		int(hand.get("current_turn_seat", -1)),
	])
	lines.append("current_bet=%d  pot=%d  acted=%s" % [
		int(hand.get("current_bet", 0)),
		int(hand.get("pot", 0)),
		str(acted),
	])
	var settlement: Dictionary = Dictionary(hand.get("settlement", {}))
	if not settlement.is_empty():
		var winner_name_items: Array[String] = []
		for winner_name in Array(settlement.get("winner_names", [])):
			winner_name_items.append(String(winner_name))
		lines.append("settlement winner_seat=%s winner=%s win_amount=%d rank=%s pot=%d->%d" % [
			str(Array(settlement.get("winner_seats", []))),
			", ".join(winner_name_items),
			int(settlement.get("win_amount", 0)),
			String(settlement.get("hand_description", settlement.get("hand_rank", "-"))),
			int(settlement.get("pot_before_settlement", 0)),
			int(settlement.get("pot_after_settlement", 0)),
		])
	lines.append("")
	lines.append("SEATS")
	for seat_item in _table_flow.seats:
		var seat: Dictionary = Dictionary(seat_item)
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		var status: String = _debug_seat_status(seat)
		lines.append(
			"Seat %d | %s | chips=%d | bet=%d | status=%s | has_acted=%s" % [
				seat_id,
				String(seat.get("player_name", "")),
				int(seat.get("chips", 0)),
				int(seat.get("current_bet", 0)),
				status,
				"yes" if acted.has(seat_id) else "no",
			]
		)
	lines.append("")
	lines.append("RULE LOG")
	var debug_log: Array = Array(snapshot.get("rule_debug_log", []))
	var start_index: int = max(debug_log.size() - 14, 0)
	for i in range(start_index, debug_log.size()):
		lines.append(String(debug_log[i]))
	_rule_debug_text.text = "\n".join(lines)


func _debug_seat_status(seat: Dictionary) -> String:
	var status: String = String(seat.get("status", "")).to_upper()
	if status in ["EMPTY", "SITTING", ""]:
		return "OUT"
	return status


func _rule_debug_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.012, 0.024, 0.90)
	style.border_color = Color(0.36, 0.72, 1.0, 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _phase_from_args() -> String:
	var args := _all_cmdline_args()
	var index := args.find("--table-phase")
	if index >= 0 and index + 1 < args.size():
		return String(args[index + 1])
	index = args.find("--capture-table-phase")
	if index >= 0 and index + 1 < args.size():
		return String(args[index + 1])
	return "waiting"

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
		if TableLaunchContext.launch_mode == "friends_room":
			target_snapshot["table_name"] = "Friends Room"
			target_snapshot["connection_status"] = "LOCAL MOCK ROOM"
		else:
			target_snapshot["connection_status"] = "Mock online table"
	_apply_local_profile_to_snapshot(target_snapshot)

func _apply_local_profile_to_snapshot(target_snapshot: Dictionary) -> void:
	var profile: Dictionary = TableLaunchContext.get_player_profile()
	var local_name: String = PlayerProfileScript.get_player_name(profile)
	var local_avatar_id: String = PlayerProfileScript.get_avatar_id(profile)
	var local_avatar_texture: Texture2D = AvatarLibraryScript.get_avatar_by_id(local_avatar_id)
	var seats: Array = Array(target_snapshot.get("seats", [])).duplicate(true)
	for i in range(seats.size()):
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		if not bool(seat.get("is_local", false)):
			seats[i] = seat
			continue
		seat["player_id"] = String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID))
		seat["player_name"] = local_name
		seat["avatar_id"] = local_avatar_id
		seat["avatar_texture"] = local_avatar_texture
		seat["buy_in"] = PlayerProfileScript.table_buy_in(profile)
		seats[i] = seat
	target_snapshot["seats"] = seats
	target_snapshot["local_player"] = _find_local_player(seats)

func _build_top_status_bar() -> void:
	if _top_right_action_bar != null:
		return
	_hide_legacy_top_center_bars()
	_build_top_action_bar()
	return

func _configure_table_flow_from_launch_context() -> void:
	var context: Dictionary = TableLaunchContext.get_current_table_context()
	if context.is_empty():
		return
	_table_flow.configure_from_launch_context(context)
	return
	_top_bar_root = Control.new()
	_top_bar_root.name = "TopBar"
	_top_bar_root.position = Vector2(32, 10)
	_top_bar_root.size = Vector2(2496, 72)
	_top_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_top_bar_root)

	var left_pill := PanelContainer.new()
	left_pill.name = "LeftSystemPill"
	left_pill.position = Vector2(0, 0)
	left_pill.size = Vector2(300, 54)
	left_pill.custom_minimum_size = left_pill.size
	left_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_pill.add_theme_stylebox_override("panel", _top_status_bar_style(10, Color(0.38, 0.26, 0.72, 0.36), Color(0.010, 0.006, 0.030, 0.62)))
	_top_bar_root.add_child(left_pill)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 18)
	left_margin.add_theme_constant_override("margin_right", 18)
	left_margin.add_theme_constant_override("margin_top", 10)
	left_margin.add_theme_constant_override("margin_bottom", 10)
	left_pill.add_child(left_margin)

	var left_row := HBoxContainer.new()
	left_row.alignment = BoxContainer.ALIGNMENT_CENTER
	left_row.add_theme_constant_override("separation", 10)
	left_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_margin.add_child(left_row)
	left_row.add_child(_top_small_label("◆", 14, Color(0.84, 0.16, 1.0)))
	left_row.add_child(_top_small_label("NEON POKER ROOM", 12, Color(0.92, 0.90, 1.0)))
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_row.add_child(left_spacer)
	left_row.add_child(_top_small_label("▮▮▮", 12, Color(0.18, 1.0, 0.68)))
	_top_left_ping_label = _top_small_label("78ms", 12, Color(0.92, 0.94, 1.0))
	left_row.add_child(_top_left_ping_label)

	_top_status_bar = PanelContainer.new()
	_top_status_bar.name = "CenterSegmentedBar"
	_top_status_bar.position = Vector2(728, 0)
	_top_status_bar.size = Vector2(1040, 64)
	_top_status_bar.custom_minimum_size = _top_status_bar.size
	_top_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_status_bar.add_theme_stylebox_override("panel", _top_status_bar_style(12, Color(0.92, 0.26, 1.0, 0.58), Color(0.018, 0.008, 0.045, 0.72)))
	_top_bar_root.add_child(_top_status_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_status_bar.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "StatusItems"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	_top_table_label = _add_top_status_cell(row, "TABLE", "Texas Hold'em", Color(0.96, 0.94, 1.0))
	row.add_child(_top_status_divider())
	_top_blinds_label = _add_top_status_cell(row, "BLINDS", "NLH 25/50", Color(0.96, 0.94, 1.0))
	row.add_child(_top_status_divider())
	_top_hand_id_label = _add_top_status_cell(row, "HAND ID", "#70482470", Color(0.96, 0.94, 1.0))
	row.add_child(_top_status_divider())
	_top_dealer_label = _add_top_status_cell(row, "DEALER", "Seat 5", Color(0.96, 0.94, 1.0))
	row.add_child(_top_status_divider())
	_top_time_label = _add_top_status_cell(row, "TIME", "14:07", Color(1.0, 0.86, 0.26))

	var right_row := HBoxContainer.new()
	right_row.name = "RightControls"
	right_row.position = Vector2(1904, 0)
	right_row.size = Vector2(592, 60)
	right_row.alignment = BoxContainer.ALIGNMENT_END
	right_row.add_theme_constant_override("separation", 14)
	_top_bar_root.add_child(right_row)

	var top_exit := _top_control_button("EXIT TABLE", Vector2(180, 56))
	top_exit.pressed.connect(_return_home)
	right_row.add_child(top_exit)
	right_row.add_child(_top_control_button("⚙", Vector2(56, 56)))
	right_row.add_child(_top_control_button("♪", Vector2(56, 56)))
	right_row.add_child(_top_control_button("^", Vector2(56, 56)))


func _build_top_bar_container_layout() -> void:
	_build_top_action_bar()
	_hide_legacy_top_center_bars()
	return
	_top_bar_root = _content_root.get_node_or_null("TopBarRoot") as Control
	if _top_bar_root == null:
		_top_bar_root = Control.new()
		_top_bar_root.name = "TopBarRoot"
		_top_bar_root.anchor_left = 0.0
		_top_bar_root.anchor_top = 0.0
		_top_bar_root.anchor_right = 1.0
		_top_bar_root.anchor_bottom = 0.0
		_top_bar_root.offset_left = 0.0
		_top_bar_root.offset_top = 0.0
		_top_bar_root.offset_right = 0.0
		_top_bar_root.offset_bottom = 82.0
		_top_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(_top_bar_root)

	var background_glass := _top_bar_root.get_node_or_null("BackgroundGlass") as Control
	if background_glass == null:
		background_glass = Control.new()
		background_glass.name = "BackgroundGlass"
		background_glass.set_anchors_preset(Control.PRESET_FULL_RECT)
		background_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_top_bar_root.add_child(background_glass)

	var left_glass := PanelContainer.new()
	left_glass.name = "LeftGlass"
	_anchor_top_element(left_glass, 0.0, 0.0, 32.0, 10.0, 332.0, 64.0)
	left_glass.visible = false
	left_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_glass.add_theme_stylebox_override("panel", _top_status_bar_style(10, Color(0.38, 0.26, 0.72, 0.36), Color(0.010, 0.006, 0.030, 0.62)))
	background_glass.add_child(left_glass)

	var center_glass := PanelContainer.new()
	center_glass.name = "CenterGlass"
	_anchor_top_element(center_glass, 0.5, 0.5, -768.0, 10.0, 768.0, 58.0)
	center_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_glass.add_theme_stylebox_override("panel", _top_status_bar_style(12, Color(0.92, 0.26, 1.0, 0.58), Color(0.018, 0.008, 0.045, 0.72)))
	background_glass.add_child(center_glass)

	var left_container := _top_bar_root.get_node_or_null("LeftContainer") as HBoxContainer
	if left_container == null:
		left_container = HBoxContainer.new()
		left_container.name = "LeftContainer"
		_anchor_top_element(left_container, 0.0, 0.0, 50.0, 10.0, 314.0, 64.0)
		_top_bar_root.add_child(left_container)
	left_container.alignment = BoxContainer.ALIGNMENT_CENTER
	left_container.add_theme_constant_override("separation", 10)
	left_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_container.visible = false

	left_container.add_child(_top_small_label("◆", 14, Color(0.84, 0.16, 1.0)))
	left_container.add_child(_top_small_label("NEON POKER ROOM", 12, Color(0.92, 0.90, 1.0)))
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_container.add_child(left_spacer)
	left_container.add_child(_top_small_label("▮▮▮", 12, Color(0.18, 1.0, 0.68)))
	_top_left_ping_label = _top_small_label("78ms", 12, Color(0.92, 0.94, 1.0))
	left_container.add_child(_top_left_ping_label)

	var center_container := _top_bar_root.get_node_or_null("CenterContainer") as HBoxContainer
	if center_container == null:
		center_container = HBoxContainer.new()
		center_container.name = "CenterContainer"
		_top_bar_root.add_child(center_container)
	_anchor_top_element(center_container, 0.5, 0.5, -744.0, 15.0, 744.0, 54.0)
	center_container.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_theme_constant_override("separation", 0)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_status_bar = center_container

	_top_table_label = _add_top_status_cell(center_container, "CHIPS", "24,500", Color(0.96, 0.94, 1.0))
	center_container.add_child(_top_status_divider())
	_top_blinds_label = _add_top_status_cell(center_container, "SEAT", "Seat 5", Color(0.96, 0.94, 1.0))
	center_container.add_child(_top_status_divider())
	_top_hand_id_label = _add_top_status_cell(center_container, "STAGE", "PRE-FLOP", Color(0.96, 0.94, 1.0))
	center_container.add_child(_top_status_divider())
	_top_dealer_label = _add_top_status_cell(center_container, "PING", "78ms", Color(0.96, 0.94, 1.0))
	center_container.add_child(_top_status_divider())
	_top_time_label = _add_top_status_cell(center_container, "HAND TIME", "14:07", Color(0.96, 0.94, 1.0))

	var right_container := _top_bar_root.get_node_or_null("RightContainer") as HBoxContainer
	if right_container == null:
		right_container = HBoxContainer.new()
		right_container.name = "RightContainer"
		_anchor_top_element(right_container, 1.0, 1.0, -624.0, 8.0, -32.0, 66.0)
		_top_bar_root.add_child(right_container)
	right_container.alignment = BoxContainer.ALIGNMENT_END
	right_container.add_theme_constant_override("separation", 14)
	right_container.visible = false

	var top_exit := _top_control_button("EXIT TABLE", Vector2(180, 56))
	top_exit.pressed.connect(_return_home)
	right_container.add_child(top_exit)
	right_container.add_child(_top_control_button("⚙", Vector2(56, 56)))
	right_container.add_child(_top_control_button("♪", Vector2(56, 56)))
	right_container.add_child(_top_control_button("^", Vector2(56, 56)))


func _build_top_action_bar() -> void:
	_top_bar_root = _content_root.get_node_or_null("TopRoot") as Control
	if _top_bar_root == null:
		_top_bar_root = _content_root.get_node_or_null("TopBarRoot") as Control
	if _top_bar_root == null:
		_top_bar_root = Control.new()
		_top_bar_root.name = "TopRoot"
		_top_bar_root.anchor_left = 0.0
		_top_bar_root.anchor_top = 0.0
		_top_bar_root.anchor_right = 1.0
		_top_bar_root.anchor_bottom = 0.0
		_top_bar_root.offset_left = 0.0
		_top_bar_root.offset_top = 0.0
		_top_bar_root.offset_right = 0.0
		_top_bar_root.offset_bottom = 82.0
		_top_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content_root.add_child(_top_bar_root)
	_top_bar_root.visible = true
	_top_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for node_name in ["BackgroundGlass", "LeftContainer", "CenterContainer", "RightContainer", "CenterSegmentedBar", "LeftSystemPill"]:
		var old_node := _top_bar_root.get_node_or_null(node_name) as CanvasItem
		if old_node != null:
			old_node.visible = false

	_top_status_bar = null

	_top_right_action_bar = _top_bar_root.get_node_or_null("TopRightActionBar") as HBoxContainer
	if _top_right_action_bar == null:
		_top_right_action_bar = HBoxContainer.new()
		_top_right_action_bar.name = "TopRightActionBar"
		_anchor_top_element(_top_right_action_bar, 1.0, 1.0, -590.0, 10.0, -32.0, 66.0)
		_top_bar_root.add_child(_top_right_action_bar)
	_top_right_action_bar.visible = true
	_top_right_action_bar.alignment = BoxContainer.ALIGNMENT_END
	_top_right_action_bar.add_theme_constant_override("separation", 14)

	_clear_children(_top_right_action_bar)
	var exit_button := _top_control_button("EXIT TABLE", Vector2(180, 56))
	exit_button.pressed.connect(_return_home)
	_top_right_action_bar.add_child(exit_button)
	_start_exit_button_pulse(exit_button)

	var settings_button := _top_control_button("⚙", Vector2(56, 56))
	_settings_button = settings_button
	settings_button.tooltip_text = "Settings"
	settings_button.pressed.connect(_toggle_settings_panel)
	_top_right_action_bar.add_child(settings_button)

	var add_chips_button := _top_control_button("ADD CHIPS", Vector2(150, 56))
	_add_chips_button = add_chips_button
	add_chips_button.tooltip_text = "Add chips"
	add_chips_button.pressed.connect(_toggle_add_chips_panel)
	_top_right_action_bar.add_child(add_chips_button)

	_build_popover_layer()
	_build_settings_panel()
	_build_add_chips_panel()

func _hide_legacy_top_center_bars() -> void:
	for root_name in ["TopBar", "TopBarRoot", "TopRoot"]:
		var root := _content_root.get_node_or_null(root_name) as Node
		if root == null:
			continue
		_hide_legacy_top_descendants(root)
	_top_status_bar = null
	_top_table_label = null
	_top_blinds_label = null
	_top_hand_id_label = null
	_top_dealer_label = null
	_top_time_label = null

func _hide_legacy_top_descendants(node: Node) -> void:
	var legacy_names := {
		"CenterSegmentedBar": true,
		"CenterContainer": true,
		"BackgroundGlass": true,
		"LeftContainer": true,
		"RightContainer": true,
		"LeftSystemPill": true,
	}
	if legacy_names.has(String(node.name)) and node is CanvasItem:
		(node as CanvasItem).visible = false
	for child in node.get_children():
		_hide_legacy_top_descendants(child)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()


func _build_popover_layer() -> void:
	_popover_layer = _content_root.get_node_or_null("PopoverLayer") as Control
	if _popover_layer == null:
		_popover_layer = _content_root.get_node_or_null("OverlayLayer") as Control
	if _popover_layer == null:
		_popover_layer = Control.new()
		_content_root.add_child(_popover_layer)
	_popover_layer.name = "PopoverLayer"
	_popover_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popover_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popover_layer.z_index = 10
	_popover_layer.visible = true
	for node_name in ["ModalMask", "BlurScrim", "ModalContainer"]:
		var old_node := _popover_layer.get_node_or_null(node_name) as CanvasItem
		if old_node != null:
			old_node.visible = false


func _build_settings_panel() -> void:
	_settings_panel = _popover_layer.get_node_or_null("SettingsPopover") as PanelContainer
	if _settings_panel == null:
		_settings_panel = _popover_layer.get_node_or_null("SettingsModal") as PanelContainer
	if _settings_panel == null:
		_settings_panel = PanelContainer.new()
		_anchor_top_element(_settings_panel, 1.0, 1.0, -330.0, 78.0, -32.0, 292.0)
		_settings_panel.add_theme_stylebox_override("panel", _top_settings_panel_style())
		_popover_layer.add_child(_settings_panel)
	_settings_panel.name = "SettingsPopover"
	_prepare_popover_panel(_settings_panel, Vector2(298, 214))
	_settings_panel.visible = false

	_clear_children(_settings_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_settings_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	title_row.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "SETTINGS"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 1.0))
	title_row.add_child(title)

	var close_button := _top_control_button("X", Vector2(40, 34))
	close_button.pressed.connect(func() -> void: _debug_click("settings close"))
	close_button.pressed.connect(_close_modal_overlay)
	title_row.add_child(close_button)

	_add_volume_row(vbox, "Master Volume", 85)
	_add_volume_row(vbox, "Music Volume", 70)
	_add_volume_row(vbox, "SFX Volume", 80)


func _build_add_chips_panel() -> void:
	_add_chips_panel = _popover_layer.get_node_or_null("AddChipsPopover") as PanelContainer
	if _add_chips_panel == null:
		_add_chips_panel = _popover_layer.get_node_or_null("AddChipsModal") as PanelContainer
	if _add_chips_panel == null:
		_add_chips_panel = PanelContainer.new()
		_anchor_top_element(_add_chips_panel, 1.0, 1.0, -310.0, 78.0, -32.0, 230.0)
		_add_chips_panel.add_theme_stylebox_override("panel", _add_chips_panel_style())
		_popover_layer.add_child(_add_chips_panel)
	_add_chips_panel.name = "AddChipsPopover"
	_prepare_popover_panel(_add_chips_panel, Vector2(278, 152))
	_add_chips_panel.visible = false

	_clear_children(_add_chips_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_add_chips_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "ADD CHIPS"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.62, 1.0, 0.88))
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(title_row)
	title_row.add_child(title)
	var close_button := _top_control_button("X", Vector2(34, 30))
	close_button.pressed.connect(func() -> void: _debug_click("add chips close"))
	close_button.pressed.connect(_close_overlay_panels)
	title_row.add_child(close_button)

	for amount in ["+1,000", "+5,000", "+10,000"]:
		var amount_label: String = String(amount)
		var button := _top_control_button(amount, Vector2(220, 34))
		button.pressed.connect(func() -> void: _debug_click("add chips %s" % amount_label))
		vbox.add_child(button)


func _add_volume_row(parent: Container, label_text: String, value: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(128, 0)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.76, 0.72, 0.90))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(slider)


func _toggle_settings_panel() -> void:
	_debug_click("settings button")
	if _settings_panel == null:
		return
	if _add_chips_panel != null:
		_add_chips_panel.visible = false
	var opening: bool = not _settings_panel.visible
	_settings_panel.visible = opening
	if not opening:
		return
	_position_popover_near_button(_settings_panel, _settings_button)
	_animate_popover(_settings_panel, Vector2(0.95, 0.95), 0.18)


func _close_modal_overlay() -> void:
	_close_overlay_panels()


func _close_overlay_panels() -> void:
	if _settings_panel != null:
		_settings_panel.visible = false
		_settings_panel.scale = Vector2.ONE
	if _add_chips_panel != null:
		_add_chips_panel.visible = false
		_add_chips_panel.scale = Vector2.ONE


func _prepare_popover_panel(panel: Control, panel_size: Vector2) -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.pivot_offset = panel_size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _position_popover_near_button(popover: Control, anchor_button: Control) -> void:
	if popover == null or anchor_button == null:
		return
	var button_rect: Rect2 = anchor_button.get_global_rect()
	var viewport_size: Vector2 = get_viewport_rect().size
	var popover_size: Vector2 = popover.size
	if popover_size.x <= 0.0 or popover_size.y <= 0.0:
		popover_size = popover.custom_minimum_size
	var target: Vector2 = Vector2(
		button_rect.position.x + button_rect.size.x - popover_size.x,
		button_rect.position.y + button_rect.size.y + 10.0
	)
	target.x = clamp(target.x, 16.0, viewport_size.x - popover_size.x - 16.0)
	target.y = clamp(target.y, 16.0, viewport_size.y - popover_size.y - 16.0)
	popover.global_position = target


func _animate_popover(popover: Control, start_scale: Vector2, duration: float) -> void:
	popover.modulate = Color(1, 1, 1, 0)
	popover.scale = start_scale
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popover, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.tween_property(popover, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _toggle_add_chips_panel() -> void:
	_debug_click("add chips button")
	if _add_chips_panel == null:
		return
	var opening: bool = not _add_chips_panel.visible
	if _settings_panel != null:
		_settings_panel.visible = false
	_add_chips_panel.visible = opening
	if opening:
		_position_popover_near_button(_add_chips_panel, _add_chips_button)
		_animate_popover(_add_chips_panel, Vector2(0.98, 0.98), 0.14)


func _top_settings_panel_style() -> StyleBoxFlat:
	var style := HomeTheme.make_panel_style(Color(0.018, 0.008, 0.045, 0.84), Color(0.92, 0.26, 1.0, 0.52), 12, 1)
	style.shadow_color = Color(0.86, 0.18, 1.0, 0.22)
	style.shadow_size = 14
	return style


func _add_chips_panel_style() -> StyleBoxFlat:
	var style := HomeTheme.make_panel_style(Color(0.010, 0.055, 0.050, 0.86), Color(0.0, 0.95, 0.72, 0.56), 12, 1)
	style.shadow_color = Color(0.0, 0.95, 0.72, 0.20)
	style.shadow_size = 12
	return style


func _start_exit_button_pulse(button: Button) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(button, "modulate", Color(1.0, 0.88, 0.94, 1.0), 1.2)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.2)


func _anchor_top_element(node: Control, anchor_left: float, anchor_right: float, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = anchor_left
	node.anchor_right = anchor_right
	node.anchor_top = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


func _add_top_status_cell(parent: Container, title: String, value: String, value_color: Color) -> Label:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(280, 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)

	var value_label := Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", value_color)
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(value_label)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 9)
	title_label.add_theme_color_override("font_color", Color(0.64, 0.58, 0.82, 0.86))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_label)
	return value_label


func _top_small_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _top_status_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(1, 34)
	divider.color = Color(0.74, 0.50, 1.0, 0.10)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider


func _top_status_bar_style(radius: int, border_color: Color, bg_color: Color) -> StyleBoxFlat:
	var style := HomeTheme.make_panel_style(bg_color, border_color, radius, 1)
	style.shadow_color = Color(0.86, 0.18, 1.0, 0.26)
	style.shadow_size = 18
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _top_control_button(text_value: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = min_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.disabled = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 13 if text_value == "EXIT TABLE" else 18)
	button.add_theme_color_override("font_color", Color(0.94, 0.92, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _top_control_style(false, text_value))
	button.add_theme_stylebox_override("hover", _top_control_style(true, text_value))
	button.add_theme_stylebox_override("pressed", _top_control_style(true, text_value))
	return button


func _debug_click(label: String) -> void:
	print("clicked: %s focus=%s" % [label, get_viewport().gui_get_focus_owner()])


func _top_control_style(hovered: bool, text_value: String = "") -> StyleBoxFlat:
	var accent := Color(0.92, 0.26, 1.0, 0.72)
	var bg := Color(0.055, 0.025, 0.080, 0.60)
	if text_value == "EXIT TABLE":
		accent = Color(1.0, 0.0, 0.32, 0.95)
		bg = Color(0.18, 0.035, 0.090, 0.74)
	elif text_value == "ADD CHIPS" or text_value.begins_with("+"):
		accent = Color(0.0, 0.95, 0.72, 0.90)
		bg = Color(0.020, 0.120, 0.100, 0.66)
	var style := HomeTheme.make_panel_style(
		bg.lightened(0.08) if hovered else bg,
		Color(accent.r, accent.g, accent.b, accent.a if hovered else accent.a * 0.70),
		18,
		1
	)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.34 if hovered else 0.16)
	style.shadow_size = 16 if hovered else 9
	return style


func _update_top_status_bar(local: Dictionary) -> void:
	if _top_status_bar == null:
		return
	var chips := int(local.get("chips", 0))
	var seat_id := int(local.get("seat_index", snapshot.get("local_seat_index", 5)))
	var is_local_connection := String(snapshot.get("connection_status", "")).to_lower().find("offline") != -1
	_top_table_label.text = _format_chips(chips)
	_top_blinds_label.text = "Seat %d" % seat_id
	_top_hand_id_label.text = _phase_label(String(snapshot.get("phase", "preflop")))
	_top_dealer_label.text = "LOCAL" if is_local_connection else "78ms"
	_top_time_label.text = _top_time_text()


func _top_time_text() -> String:
	var t := Time.get_time_dict_from_system()
	return "%02d:%02d" % [int(t.hour), int(t.minute)]


func _phase_label(phase: String) -> String:
	match phase.to_lower():
		"preflop":
			return "PRE-FLOP"
		"flop":
			return "FLOP"
		"turn":
			return "TURN"
		"river":
			return "RIVER"
		"showdown":
			return "SHOWDOWN"
	return phase.to_upper()

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
