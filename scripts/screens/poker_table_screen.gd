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
const DealerLibraryScript := preload("res://scripts/data/dealer_library.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const TableSessionScript := preload("res://scripts/data/table_session.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PokerWsClientScript := preload("res://scripts/network/poker_ws_client.gd")
const PokerProtocolScript := preload("res://scripts/network/poker_protocol.gd")
const NetworkConfigScript := preload("res://scripts/network/network_config.gd")
const ServerTableSnapshotScript := preload("res://scripts/state/table_snapshot.gd")

const DESIGN_SIZE := Vector2(2560, 1000)
const SERVER_DEFAULT_BUY_IN := 5000
const TABLE_BACKGROUND_PATH := "res://assets/poker_table/backgrounds/table_neon_v1.png"
const FLYING_CARD_BACK_PATH := "res://assets/ui/cardback/asset_02.png"
const FLYING_CHIP_PATH := "res://assets/ui/chips/chip_stack_purple.png"
const DEALER_DECK_PATH := "res://assets/ui/cardback/asset_03.png"
const ADD_CHIPS_POPOVER_SIZE := Vector2(312, 286)
const POPOVER_LAYER_Z_INDEX := 240
const SERVER_UI_VERBOSE_LOGS := false
const SERVER_UI_SLOW_APPLY_WARNING_MS := 16
const SERVER_UI_SLOW_PLAYBACK_WARNING_MS := 16
const SERVER_UI_WARNING_THROTTLE_MS := 1000
const SHOWDOWN_REVEAL_HOLD_SECONDS := 5.0
const FOLD_WIN_HOLD_SECONDS := 2.5

var snapshot := {}
var server_authoritative := true
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
var _dealer_cosmetic_button: Button
var _settings_panel: PanelContainer
var _popover_layer: Control
var _add_chips_panel: PanelContainer
var _dealer_cosmetic_panel: PanelContainer
var _ai_turn_loop_active: bool = false
var _ai_rng := RandomNumberGenerator.new()
var _animation_layer: Control
var _flying_cards_root: Control
var _flying_chips_root: Control
var _dealer_deck_icon: TextureRect
var _croupier_display: TextureRect
var _dealer_cosmetic_name_label: Label
var _seen_visual_event_ids := {}
var _visual_pause_until_msec: int = 0
var _hand_over_sequence_active: bool = false
var _next_hand_ready: bool = true
var _auto_next_hand_enabled: bool = false
var _showdown_reveal_active: bool = false
var _showdown_revealed_player_ids: Array[int] = []
var _hand_result_message: String = ""
var _hand_result_hold_seconds: float = 0.0
var _pending_next_hand_token: int = 0
var _bet_marker_overrides: Dictionary = {}
var _visible_community_cards: Array = []
var _community_reveal_token: int = 0
var _local_cards_reveal_token: int = 0
var _rule_debug_panel: PanelContainer
var _rule_debug_text: RichTextLabel
var _table_session: TableSession
var _session_log: Array[String] = []
var _session_result_scrim: ColorRect
var _session_result_panel: PanelContainer
var _session_result_text: RichTextLabel
var _session_result_avatar: TextureRect
var _session_result_name_label: Label
var _session_unlock_avatar: TextureRect
var _session_unlock_label: Label
var _session_play_again_hint_label: Label
var _session_play_again_button: Button
var _hand_result_banner: PanelContainer
var _hand_result_title_label: Label
var _hand_result_body_label: Label
var _recorded_session_hand_ids := {}
var _session_started := false
var _profile_settlement_applied := false
var _session_unlocked_avatar_ids: Array[String] = []
var _poker_ws_client: PokerWsClient
var _server_table_snapshot: TableSnapshot
var _server_room_id := ""
var _server_connected := false
var _server_create_room_requested := false
var _server_join_room_requested := false
var _server_setup_done := false
var _server_start_hand_requested := false
var _server_local_player_id := ""
var _server_local_player_name := ""
var _server_local_seat_index := 0
var _server_private_snapshot: Dictionary = {}
var _server_last_error := ""
var _server_latest_ui_snapshot: Dictionary = {}
var _server_snapshot_initialized := false
var _server_pending_action_events: Array = []
var _server_pending_event_sequences := {}
var _server_played_event_sequences := {}
var _server_last_played_event_sequence := 0
var _server_playback_running := false
var _server_visible_action_history: Array = []
var _server_visible_seat_actions := {}
var _server_visible_community_count := -1
var _server_waiting_for_action_ack := false
var _server_cash_out_pending_return := false
var _server_last_slow_ui_warning_msec := 0
var _server_visible_hand_id := 0

func _ready() -> void:
	_hide_editor_guides(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ai_rng.randomize()
	
	var args := _all_cmdline_args()
	if args.has("--training") or args.has("--table-training"):
		TableLaunchContext.configure("training", "mock_table_001")
		
	_build_scene()
	_configure_table_flow_from_launch_context()
	_configure_table_session_from_launch_context()
	if server_authoritative:
		_boot_server_authoritative_table()
	else:
		_load_phase(_phase_from_args())
		call_deferred("_auto_start_session_if_ready")
	_apply_capture_args()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_F:
			_force_finish_current_session()
			get_viewport().set_input_as_handled()
			return
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_H:
			_force_current_hand_to_showdown()
			get_viewport().set_input_as_handled()
			return
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
				if _can_use_debug_start_key():
					_start_next_hand()
			KEY_SPACE:
				if _can_use_space_next_hand():
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
	_build_session_result_panel()
	_build_hand_result_banner()
	
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


func _build_hand_result_banner() -> void:
	_hand_result_banner = PanelContainer.new()
	_hand_result_banner.name = "HandEndResultBanner"
	_hand_result_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_result_banner.visible = false
	_hand_result_banner.z_index = 260
	_hand_result_banner.size = Vector2(640, 124)
	_hand_result_banner.position = Vector2((DESIGN_SIZE.x - _hand_result_banner.size.x) * 0.5, 286.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.008, 0.045, 0.88)
	style.border_color = Color(1.0, 0.0, 0.58, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(1.0, 0.0, 0.58, 0.22)
	style.shadow_size = 18
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_hand_result_banner.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	_hand_result_banner.add_child(box)

	_hand_result_title_label = Label.new()
	_hand_result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hand_result_title_label.add_theme_font_size_override("font_size", 23)
	_hand_result_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.96, 1.0))
	box.add_child(_hand_result_title_label)

	_hand_result_body_label = Label.new()
	_hand_result_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hand_result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hand_result_body_label.add_theme_font_size_override("font_size", 17)
	_hand_result_body_label.add_theme_color_override("font_color", Color(0.88, 0.91, 1.0, 0.96))
	box.add_child(_hand_result_body_label)

	_content_root.add_child(_hand_result_banner)

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
	_croupier_display.texture = _load_texture(DealerLibraryScript.texture_path(DealerLibraryScript.DEFAULT_DEALER_ID))
	_croupier_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_croupier_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_croupier_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_croupier_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_croupier_display.size = Vector2(280, 280)
	_croupier_display.z_index = 118
	_animation_layer.add_child(_croupier_display)
	_dealer_cosmetic_name_label = Label.new()
	_dealer_cosmetic_name_label.name = "DealerCosmeticName"
	_dealer_cosmetic_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dealer_cosmetic_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dealer_cosmetic_name_label.add_theme_font_size_override("font_size", 13)
	_dealer_cosmetic_name_label.add_theme_color_override("font_color", Color(0.94, 0.86, 1.0, 0.92))
	_dealer_cosmetic_name_label.z_index = 119
	_animation_layer.add_child(_dealer_cosmetic_name_label)

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
	if _dealer_cosmetic_name_label != null:
		_dealer_cosmetic_name_label.position = _croupier_display.position + Vector2(42, 228)
		_dealer_cosmetic_name_label.size = Vector2(196, 28)
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
	_cancel_pending_next_hand_timer()
	if phase.to_lower() == "waiting":
		_configure_table_flow_from_launch_context()
		_table_flow.reset_table()
		_sync_launch_profile_to_table_flow()
		snapshot = _table_flow_to_ui_snapshot(_table_flow.to_snapshot())
	else:
		snapshot = MockTableSimulation.get_phase_snapshot(phase)
	_apply_launch_context(snapshot)
	_refresh()

func _boot_server_authoritative_table() -> void:
	_ai_turn_loop_active = false
	_server_table_snapshot = ServerTableSnapshotScript.new()
	_server_private_snapshot = {}
	_server_room_id = String(TableLaunchContext.room_id)
	_server_connected = false
	_server_create_room_requested = false
	_server_join_room_requested = false
	_server_setup_done = false
	_server_start_hand_requested = false
	_server_last_error = ""
	_server_latest_ui_snapshot = {}
	_server_snapshot_initialized = false
	_server_pending_action_events.clear()
	_server_pending_event_sequences.clear()
	_server_played_event_sequences.clear()
	_server_last_played_event_sequence = 0
	_server_playback_running = false
	_server_visible_action_history = []
	_server_visible_seat_actions.clear()
	_server_visible_community_count = -1
	_server_waiting_for_action_ack = false
	_load_server_profile_identity()
	snapshot = _empty_server_ui_snapshot("Connecting to local authoritative server...")
	_refresh()
	_connect_authoritative_server()

func _load_server_profile_identity() -> void:
	var profile: Dictionary = ProfileServiceScript.new().get_current_profile()
	if profile.is_empty():
		profile = TableLaunchContext.get_player_profile()
	_server_local_player_id = String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID))
	if _server_local_player_id == "":
		_server_local_player_id = PlayerProfileScript.DEFAULT_PLAYER_ID
	_server_local_player_name = PlayerProfileScript.get_player_name(profile)
	if _server_local_player_name == "":
		_server_local_player_name = PlayerProfileScript.DEFAULT_PLAYER_NAME

func _connect_authoritative_server() -> void:
	if _poker_ws_client == null:
		_poker_ws_client = PokerWsClientScript.new()
		_poker_ws_client.name = "AuthoritativePokerWsClient"
		_poker_ws_client.connected.connect(_on_server_connected)
		_poker_ws_client.disconnected.connect(_on_server_disconnected)
		_poker_ws_client.hello_received.connect(_on_server_hello_received)
		_poker_ws_client.profile_synced.connect(_on_server_profile_synced)
		_poker_ws_client.wallet_synced.connect(_on_server_wallet_synced)
		_poker_ws_client.daily_login_awarded.connect(_on_server_daily_login_awarded)
		_poker_ws_client.table_created.connect(_on_server_table_created)
		_poker_ws_client.table_joined.connect(_on_server_table_joined)
		_poker_ws_client.table_snapshot_received.connect(_on_server_table_snapshot_received)
		_poker_ws_client.private_snapshot_received.connect(_on_server_private_snapshot_received)
		_poker_ws_client.server_error.connect(_on_server_error)
		add_child(_poker_ws_client)
	var server_url := NetworkConfigScript.server_url()
	var err := _poker_ws_client.connect_to_server(server_url)
	if err != OK:
		_on_server_error("Connect failed: %s" % error_string(err))
		return
	_append_session_log("Connecting to authoritative server %s" % server_url)

func _on_server_connected() -> void:
	_server_connected = true
	_append_session_log("Connected to authoritative server.")
	var err := _poker_ws_client.send_hello(_server_local_player_name, _server_local_player_id, PlayerProfileScript.get_avatar_id(ProfileServiceScript.new().get_current_profile()))
	if err != OK:
		_on_server_error("Failed to send hello: %s" % error_string(err))

func _on_server_disconnected() -> void:
	_server_connected = false
	_server_setup_done = false
	_on_server_error("Disconnected from authoritative server.")

func _on_server_hello_received(player_id: String, room_id: String) -> void:
	if player_id != "":
		_append_session_log("Server player id: %s" % player_id)
	if room_id != "":
		_server_room_id = room_id
		_append_session_log("Authoritative room_id: %s" % _server_room_id)
	if _server_room_id != "" and room_id == "" and not _server_join_room_requested:
		_server_join_room_requested = true
		_send_server_message(_poker_ws_client.join_room(_server_room_id), "join_room %s" % _server_room_id)
	if _server_room_id == "" and not _server_create_room_requested:
		_server_create_room_requested = true
		_send_server_message(_poker_ws_client.create_table(_server_create_table_name(), _server_create_table_config()), "create_table")
		return
	_try_server_sit_ready()

func _on_server_profile_synced(profile: Dictionary, wallet: Dictionary, unlocked_avatar_ids: Array) -> void:
	var synced_profile := ProfileServiceScript.new().apply_server_profile_snapshot(profile, wallet, unlocked_avatar_ids, false)
	TableLaunchContext.set_player_profile(synced_profile)
	_load_server_profile_identity()
	if not wallet.is_empty():
		_append_session_log("Server wallet synced: %s chips, %s gems." % [
			_format_chips(PlayerProfileScript.get_total_chips(synced_profile)),
			_format_chips(PlayerProfileScript.get_total_gems(synced_profile)),
		])

func _on_server_wallet_synced(wallet: Dictionary) -> void:
	var synced_profile := ProfileServiceScript.new().apply_server_wallet_snapshot(wallet)
	TableLaunchContext.set_player_profile(synced_profile)
	if _add_chips_panel != null and _add_chips_panel.visible:
		_refresh_add_chips_panel_content()
	if _server_cash_out_pending_return:
		_complete_return_home()

func _on_server_daily_login_awarded(chips: int) -> void:
	if chips > 0:
		var synced_profile := ProfileServiceScript.new().apply_server_profile_snapshot({}, {}, [], true)
		TableLaunchContext.set_player_profile(synced_profile)
		_append_session_log("Daily bonus +%s chips" % _format_chips(chips))

func _try_server_sit_ready() -> void:
	if _server_setup_done or _server_room_id == "" or _poker_ws_client == null:
		return
	_server_setup_done = true
	var buy_in: int = PlayerProfileScript.table_buy_in(ProfileServiceScript.new().get_current_profile())
	if buy_in <= 0:
		buy_in = 5000
	_append_session_log("Authoritative room_id: %s" % _server_room_id)
	_send_server_message(_poker_ws_client.sit_down(_server_local_seat_index, buy_in), "sit_down seat %d" % _server_local_seat_index)
	_send_server_message(_poker_ws_client.ready(true), "ready")
	_append_session_log("Start bots with: npm.cmd run bot -- --room %s --count 2 --start-seat 1" % _server_room_id)
	_append_session_log("Press S to request start_hand from the authoritative server.")

func _server_create_table_name() -> String:
	var player_name := PlayerProfileScript.get_player_name(ProfileServiceScript.new().get_current_profile())
	if player_name == "":
		player_name = _server_local_player_name
	return "%s's Table" % player_name

func _server_create_table_config() -> Dictionary:
	var hand_count := TableLaunchContext.max_hands
	if hand_count >= 999:
		hand_count = 0
	var buy_in := TableLaunchContext.buy_in
	var wallet_chips := PlayerProfileScript.get_total_chips(ProfileServiceScript.new().get_current_profile())
	if not [5000, 10000, 20000, 50000].has(buy_in) or buy_in > wallet_chips:
		buy_in = 5000
		for option in [5000, 10000, 20000, 50000]:
			var value := int(option)
			if value <= wallet_chips:
				buy_in = value
	return {
		"buy_in": buy_in,
		"small_blind": TableLaunchContext.small_blind,
		"big_blind": TableLaunchContext.big_blind,
		"hand_count": hand_count,
		"max_players": 6,
		"is_public": true,
	}

func _on_server_table_created(room_id: String, table_info: Dictionary) -> void:
	_apply_server_table_info(room_id, table_info)
	_try_server_sit_ready()

func _on_server_table_joined(room_id: String, table_info: Dictionary) -> void:
	_apply_server_table_info(room_id, table_info)
	_try_server_sit_ready()

func _apply_server_table_info(room_id: String, table_info: Dictionary) -> void:
	if room_id != "":
		_server_room_id = room_id
		_append_session_log("Authoritative room_id: %s" % _server_room_id)
	var buy_in := int(table_info.get("buy_in", TableLaunchContext.buy_in))
	var small_blind := int(table_info.get("small_blind", TableLaunchContext.small_blind))
	var big_blind := int(table_info.get("big_blind", TableLaunchContext.big_blind))
	var max_hands := int(table_info.get("hand_count", TableLaunchContext.max_hands))
	if max_hands <= 0:
		max_hands = 999
	TableLaunchContext.buy_in = buy_in
	TableLaunchContext.small_blind = small_blind
	TableLaunchContext.big_blind = big_blind
	TableLaunchContext.max_hands = max_hands
	if _table_session != null:
		_table_session.buy_in = buy_in
		_table_session.starting_chips = buy_in
		_table_session.current_table_chips = buy_in
		_table_session.session_start_chips = buy_in
		_table_session.session_end_chips = buy_in
		_table_session.session_profit = 0
		_table_session.small_blind = small_blind
		_table_session.big_blind = big_blind
		_table_session.max_hands = max_hands
	_append_session_log("Server table config: buy-in %s, blinds %s / %s, hands %s." % [
		_format_chips(buy_in),
		str(small_blind),
		str(big_blind),
		"Unlimited" if max_hands >= 999 else str(max_hands),
	])

func _on_server_table_snapshot_received(server_snapshot: Dictionary) -> void:
	var apply_start := Time.get_ticks_msec()
	_server_last_error = ""
	_server_waiting_for_action_ack = false
	if _server_table_snapshot == null:
		_server_table_snapshot = ServerTableSnapshotScript.new()
	_server_table_snapshot.apply_table_snapshot(server_snapshot)
	_server_room_id = String(server_snapshot.get("room_id", _server_room_id))
	var next_snapshot := _server_snapshot_to_ui_snapshot(server_snapshot, _server_private_snapshot)
	_queue_server_action_events(server_snapshot, next_snapshot)
	_server_latest_ui_snapshot = next_snapshot.duplicate(true)
	snapshot = _server_apply_playback_projection(_server_latest_ui_snapshot)
	_apply_launch_context(snapshot)
	_refresh()
	_warn_if_server_ui_slow("server snapshot apply", apply_start, SERVER_UI_SLOW_APPLY_WARNING_MS)
	_start_server_action_playback()

func _on_server_private_snapshot_received(private_snapshot: Dictionary) -> void:
	_server_private_snapshot = private_snapshot.duplicate(true)
	if _server_table_snapshot == null:
		_server_table_snapshot = ServerTableSnapshotScript.new()
	_server_table_snapshot.apply_private_snapshot(private_snapshot)
	if not snapshot.is_empty() and String(snapshot.get("source_model", "")) == "server_authoritative":
		var apply_start := Time.get_ticks_msec()
		_server_latest_ui_snapshot = _server_snapshot_to_ui_snapshot(_server_table_snapshot.to_dict(), _server_private_snapshot)
		snapshot = _server_apply_playback_projection(_server_latest_ui_snapshot)
		_apply_launch_context(snapshot)
		_refresh()
		_warn_if_server_ui_slow("server private snapshot apply", apply_start, SERVER_UI_SLOW_APPLY_WARNING_MS)

func _on_server_error(message: String) -> void:
	_server_last_error = message
	_server_waiting_for_action_ack = false
	_server_cash_out_pending_return = false
	_append_session_log("Server error: %s" % message)
	if _server_table_snapshot != null:
		_server_latest_ui_snapshot = _server_snapshot_to_ui_snapshot(_server_table_snapshot.to_dict(), _server_private_snapshot)
		snapshot = _server_apply_playback_projection(_server_latest_ui_snapshot)
	var current_history: Array = Array(snapshot.get("hand_history", [])).duplicate()
	current_history.append("Server error: %s" % message)
	snapshot["hand_history"] = current_history
	_refresh()

func _send_server_message(err: int, label: String) -> void:
	if err == OK:
		_append_session_log("Sent server %s" % label)
	else:
		_on_server_error("%s failed: %s" % [label, error_string(err)])

func _empty_server_ui_snapshot(message: String) -> Dictionary:
	var profile: Dictionary = ProfileServiceScript.new().get_current_profile()
	var local_name: String = PlayerProfileScript.get_player_name(profile)
	if local_name == "":
		local_name = PlayerProfileScript.DEFAULT_PLAYER_NAME
	var local_avatar_id: String = PlayerProfileScript.get_avatar_id(profile)
	var local_chips: int = SERVER_DEFAULT_BUY_IN
	var seats: Array = []
	for i in range(6):
		var is_local := i == _server_local_seat_index
		seats.append({
			"seat_index": i,
			"seat_id": i,
			"visual_position": MockTableSimulation.visual_position_for_seat_index(i, _server_local_seat_index),
			"player_id": _server_local_player_id if is_local else "",
			"player_name": local_name if is_local else "Seat %d" % i,
			"avatar_id": local_avatar_id if is_local else AvatarLibraryScript.avatar_id_for_seat(i + 1, false),
			"avatar_texture": AvatarLibraryScript.get_avatar_by_id(local_avatar_id if is_local else AvatarLibraryScript.avatar_id_for_seat(i + 1, false)),
			"chips": local_chips if is_local else 0,
			"current_bet": 0,
			"status": "active" if is_local else "empty",
			"raw_status": "connecting" if is_local else "empty",
			"cards": [],
			"is_local": is_local,
			"is_dealer": false,
			"is_small_blind": false,
			"is_big_blind": false,
			"is_turn": false,
			"last_action": "",
			"buy_in": SERVER_DEFAULT_BUY_IN,
			"server_authoritative": true,
			"win_rate": "N/A",
		})
	var local_player: Dictionary = _find_local_player(seats)
	return {
		"source_model": "server_authoritative",
		"table_id": _server_room_id if _server_room_id != "" else "authoritative_local",
		"table_name": "Authoritative Local Table",
		"hand_id": "waiting",
		"blinds_text": "25 / 50",
		"phase": "waiting",
		"room_state": "waiting",
		"pot": 0,
		"pot_data": {"main": 0, "side_pots": []},
		"community_cards": [],
		"seats": seats,
		"local_player": local_player,
		"local_seat_index": _server_local_seat_index,
		"turn_seat_index": -1,
		"turn_seconds": 15,
		"turn_prompt": "Connecting...",
		"available_actions": [],
		"hand_history": [message],
		"system_messages": ["Server authoritative mode: waiting for table_snapshot"],
		"visual_events": [],
		"rule_debug_log": [],
		"table_session": {},
	}

func _server_snapshot_to_ui_snapshot(server_snapshot: Dictionary, private_snapshot: Dictionary) -> Dictionary:
	var phase: String = String(server_snapshot.get("betting_round", server_snapshot.get("hand_state", server_snapshot.get("phase", "waiting"))))
	var room_id: String = String(server_snapshot.get("room_id", _server_room_id))
	var table_info: Dictionary = Dictionary(server_snapshot.get("table_info", {}))
	var server_buy_in: int = int(server_snapshot.get("buy_in", table_info.get("buy_in", SERVER_DEFAULT_BUY_IN)))
	if server_buy_in <= 0:
		server_buy_in = SERVER_DEFAULT_BUY_IN
	var server_small_blind := int(table_info.get("small_blind", server_snapshot.get("small_blind", 25)))
	var server_big_blind := int(table_info.get("big_blind", server_snapshot.get("big_blind", 50)))
	var server_hand_id := int(server_snapshot.get("hand_id", 0))
	var private_hand_id := int(private_snapshot.get("hand_id", -1))
	var private_matches_hand := private_hand_id == server_hand_id
	var local_server_seat: int = int(private_snapshot.get("seat_index", _server_local_seat_index))
	_server_local_seat_index = local_server_seat
	var current_turn_seat: int = int(server_snapshot.get("current_turn_seat", -1))
	var seats: Array = []
	for seat_item in Array(server_snapshot.get("seats", [])):
		var server_seat: Dictionary = Dictionary(seat_item).duplicate(true)
		var seat_index: int = int(server_seat.get("seat_id", server_seat.get("seat_index", 0)))
		var is_local := seat_index == local_server_seat and String(server_seat.get("player_id", "")) != ""
		var raw_status: String = String(server_seat.get("status", "empty"))
		var ui_status: String = _server_status_to_ui_status(raw_status)
		var avatar_id: String = AvatarLibraryScript.avatar_id_for_seat(seat_index + 1, is_local)
		if is_local:
			avatar_id = PlayerProfileScript.get_avatar_id(ProfileServiceScript.new().get_current_profile())
		var cards: Array = []
		if is_local and private_matches_hand:
			for card_item in Array(private_snapshot.get("hole_cards", [])):
				cards.append(_server_card_to_ui_card(Dictionary(card_item), true))
		else:
			for _i in range(int(server_seat.get("hole_card_count", 0))):
				cards.append({"rank": "", "suit": "", "face_up": false})
		seats.append({
			"seat_index": seat_index,
			"seat_id": seat_index,
			"visual_position": MockTableSimulation.visual_position_for_seat_index(seat_index, local_server_seat),
			"player_id": String(server_seat.get("player_id", "")),
			"player_name": String(server_seat.get("player_name", server_seat.get("name", "Seat %d" % seat_index))),
			"avatar_id": avatar_id,
			"avatar_texture": AvatarLibraryScript.get_avatar_by_id(avatar_id),
			"chips": int(server_seat.get("chips", 0)),
			"current_bet": int(server_seat.get("current_bet", 0)),
			"status": ui_status,
			"raw_status": raw_status,
			"cards": cards,
			"is_local": is_local,
			"is_dealer": bool(server_seat.get("is_dealer", false)),
			"is_small_blind": bool(server_seat.get("is_small_blind", false)),
			"is_big_blind": bool(server_seat.get("is_big_blind", false)),
			"is_turn": seat_index == current_turn_seat,
			"last_action": _server_action_label(String(server_seat.get("last_action", ""))),
			"last_action_amount": int(server_seat.get("last_action_amount", 0)),
			"last_action_seq": int(server_snapshot.get("hand_id", 0)) * 1000 + int(server_seat.get("last_action_amount", 0)),
			"buy_in": server_buy_in,
			"server_authoritative": true,
			"win_rate": "N/A",
		})
	var community_cards: Array = []
	for card_item in Array(server_snapshot.get("community_cards", [])):
		community_cards.append(_server_card_to_ui_card(Dictionary(card_item), true))
	var total_pot: int = int(server_snapshot.get("pot", 0))
	var side_pots: Array = Array(server_snapshot.get("side_pots", [])).duplicate(true)
	var history: Array = _server_history_lines(server_snapshot, room_id, side_pots)
	if _server_last_error != "":
		history.append("Server error: %s" % _server_last_error)
	var local_player: Dictionary = _find_local_player(seats)
	var available_actions: Array = _server_legal_actions_to_ui_actions(Array(private_snapshot.get("legal_actions", [])), total_pot)
	if current_turn_seat != local_server_seat:
		available_actions = []
	var turn_prompt := _server_turn_message(seats, current_turn_seat, local_server_seat, phase)
	return {
		"source_model": "server_authoritative",
		"table_id": room_id if room_id != "" else "authoritative_local",
		"table_name": "Authoritative Local Table",
		"buy_in": server_buy_in,
		"table_info": table_info,
		"hand_id": "hand_%s" % str(server_hand_id),
		"blinds_text": "%d / %d" % [server_small_blind, server_big_blind],
		"phase": phase,
		"room_state": phase,
		"pot": total_pot,
		"pot_data": {"main": total_pot, "side_pots": side_pots, "total": total_pot},
		"community_cards": community_cards,
		"seats": seats,
		"local_player": local_player,
		"local_seat_index": local_server_seat,
		"turn_seat_index": current_turn_seat,
		"turn_seconds": 15,
		"turn_prompt": turn_prompt,
		"available_actions": available_actions,
		"hand_history": history,
		"system_messages": [
			"Server authoritative mode",
			"Room: %s" % room_id,
			turn_prompt,
		],
		"visual_events": [],
		"server_recent_actions": Array(server_snapshot.get("recent_actions", server_snapshot.get("action_log", []))).duplicate(true),
		"server_hand_id": server_hand_id,
		"server_winners": Array(server_snapshot.get("winners", [])).duplicate(true),
		"server_last_hand_results": Array(server_snapshot.get("last_hand_results", [])).duplicate(true),
		"rule_debug_log": history,
		"table_session": {},
	}

func _server_card_to_ui_card(card: Dictionary, face_up: bool) -> Dictionary:
	var rank: String = String(card.get("rank", ""))
	var suit_code: String = String(card.get("suit", ""))
	return {
		"rank": rank,
		"suit": _server_suit_to_ui_suit(suit_code),
		"code": String(card.get("code", "%s%s" % [rank, suit_code])),
		"face_up": face_up,
	}

func _server_suit_to_ui_suit(suit_code: String) -> String:
	match suit_code:
		"C":
			return "clubs"
		"D":
			return "diamonds"
		"H":
			return "hearts"
		"S":
			return "spades"
	return suit_code

func _server_action_label(action_id: String) -> String:
	match action_id:
		"small_blind":
			return "SB"
		"big_blind":
			return "BB"
		"all_in":
			return "ALL-IN"
		"win":
			return "WIN"
		"fold":
			return "FOLD"
		"check":
			return "CHECK"
		"call":
			return "CALL"
		"bet":
			return "BET"
		"raise":
			return "RAISE"
	return action_id.to_upper()

func _server_status_to_ui_status(status: String) -> String:
	match status:
		"empty":
			return "empty"
		"folded":
			return "folded"
		"sit_out", "disconnected":
			return "out"
	return "active"

func _queue_server_action_events(server_snapshot: Dictionary, ui_snapshot: Dictionary) -> void:
	var action_entries: Array = Array(server_snapshot.get("recent_actions", server_snapshot.get("action_log", []))).duplicate(true)
	var hand_id := int(server_snapshot.get("hand_id", 0))
	if not _server_snapshot_initialized:
		_server_snapshot_initialized = true
		_server_visible_hand_id = hand_id
		_server_visible_action_history = _server_history_lines(server_snapshot, String(server_snapshot.get("room_id", _server_room_id)), Array(server_snapshot.get("side_pots", [])))
		_server_visible_community_count = Array(ui_snapshot.get("community_cards", [])).size()
		_seed_visible_seat_actions(Array(ui_snapshot.get("seats", [])))
		for entry_item in action_entries:
			var sequence := _server_event_sequence(Dictionary(entry_item))
			if sequence <= 0:
				continue
			_server_played_event_sequences[sequence] = true
			_server_last_played_event_sequence = max(_server_last_played_event_sequence, sequence)
		return
	if hand_id != _server_visible_hand_id:
		_reset_server_visible_hand_state(hand_id)
	action_entries.sort_custom(func(a, b): return _server_event_sequence(Dictionary(a)) < _server_event_sequence(Dictionary(b)))
	for entry_item in action_entries:
		var event: Dictionary = Dictionary(entry_item).duplicate(true)
		var sequence := _server_event_sequence(event)
		if sequence <= 0:
			continue
		if sequence <= _server_last_played_event_sequence:
			continue
		if _server_played_event_sequences.has(sequence) or _server_pending_event_sequences.has(sequence):
			continue
		_server_pending_action_events.append(event)
		_server_pending_event_sequences[sequence] = true

func _reset_server_visible_hand_state(hand_id: int) -> void:
	_server_visible_hand_id = hand_id
	_server_visible_seat_actions.clear()
	_server_visible_community_count = 0
	_reset_visual_hand_state()

func _seed_visible_seat_actions(seats: Array) -> void:
	_server_visible_seat_actions.clear()
	for seat_item in seats:
		var seat: Dictionary = Dictionary(seat_item)
		var action_label := String(seat.get("last_action", ""))
		if action_label == "":
			continue
		var seat_id := int(seat.get("seat_id", seat.get("seat_index", -1)))
		if seat_id < 0:
			continue
		_server_visible_seat_actions[seat_id] = {
			"action": action_label,
			"amount": int(seat.get("last_action_amount", 0)),
		}

func _server_apply_playback_projection(source_snapshot: Dictionary) -> Dictionary:
	var projected := source_snapshot.duplicate(true)
	projected["visual_events"] = []
	if not _server_visible_action_history.is_empty():
		projected["hand_history"] = _server_visible_action_history.duplicate(true)
	if _server_visible_community_count >= 0:
		var community_cards: Array = Array(projected.get("community_cards", []))
		projected["community_cards"] = community_cards.slice(0, min(_server_visible_community_count, community_cards.size()))
	var projected_seats: Array = []
	for seat_item in Array(projected.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item).duplicate(true)
		var seat_id := int(seat.get("seat_id", seat.get("seat_index", -1)))
		if _server_visible_seat_actions.has(seat_id):
			var action_data: Dictionary = Dictionary(_server_visible_seat_actions[seat_id])
			seat["last_action"] = String(action_data.get("action", ""))
			seat["last_action_amount"] = int(action_data.get("amount", 0))
		else:
			seat["last_action"] = ""
			seat["last_action_amount"] = 0
		projected_seats.append(seat)
	projected["seats"] = projected_seats
	if _server_waiting_for_action_ack:
		projected["available_actions"] = []
		projected["turn_prompt"] = "Waiting for server..."
	return projected

func _start_server_action_playback() -> void:
	if _server_playback_running or _server_pending_action_events.is_empty():
		return
	_server_playback_running = true
	call_deferred("_run_server_action_playback")

func _run_server_action_playback() -> void:
	while not _server_pending_action_events.is_empty():
		var event: Dictionary = Dictionary(_server_pending_action_events.pop_front())
		var sequence := _server_event_sequence(event)
		_server_pending_event_sequences.erase(sequence)
		if sequence <= 0 or _server_played_event_sequences.has(sequence):
			continue
		_server_played_event_sequences[sequence] = true
		_server_last_played_event_sequence = max(_server_last_played_event_sequence, sequence)
		_apply_server_playback_event(event)
		if not _server_latest_ui_snapshot.is_empty():
			snapshot = _server_apply_playback_projection(_server_latest_ui_snapshot)
			_refresh_server_playback_event_ui(event)
		var delay := _server_playback_delay(event)
		await get_tree().create_timer(delay).timeout
	_server_playback_running = false
	if not _server_pending_action_events.is_empty():
		_start_server_action_playback()

func _apply_server_playback_event(event: Dictionary) -> void:
	var message := String(event.get("message", ""))
	if message != "":
		_server_visible_action_history.append(message)
		if _server_visible_action_history.size() > 80:
			_server_visible_action_history = _server_visible_action_history.slice(_server_visible_action_history.size() - 80)
	var event_type := String(event.get("type", ""))
	var action_id := String(event.get("action", ""))
	if event_type == "phase":
		_apply_server_phase_playback(action_id)
		return
	var seat_id := int(event.get("seat_id", event.get("seat_index", -1)))
	if seat_id < 0:
		return
	var action_label := _server_action_label(action_id)
	var amount := int(event.get("amount", 0))
	_server_visible_seat_actions[seat_id] = {"action": action_label, "amount": amount}
	_show_seat_action_toast(seat_id, action_label, amount)

func _apply_server_phase_playback(action_id: String) -> void:
	match action_id:
		"flop":
			_server_visible_community_count = max(_server_visible_community_count, 3)
		"turn":
			_server_visible_community_count = max(_server_visible_community_count, 4)
		"river", "showdown":
			_server_visible_community_count = max(_server_visible_community_count, 5)

func _server_playback_delay(event: Dictionary) -> float:
	match String(event.get("type", "")):
		"phase":
			return 0.58
		"winner":
			return 0.72
	return 0.46

func _refresh_server_playback_event_ui(event: Dictionary) -> void:
	var apply_start := Time.get_ticks_msec()
	var event_type := String(event.get("type", ""))
	var message := String(event.get("message", ""))
	var seat_id := int(event.get("seat_id", event.get("seat_index", -1)))
	if seat_id >= 0:
		_refresh_projected_server_seat(seat_id)
	if event_type == "phase":
		_apply_community_cards(Array(snapshot.get("community_cards", [])))
	if message != "":
		_append_server_history_line(message)
	_warn_if_server_ui_slow("server playback event", apply_start, SERVER_UI_SLOW_PLAYBACK_WARNING_MS)


func _refresh_projected_server_seat(seat_id: int) -> void:
	for seat_item in Array(snapshot.get("seats", [])):
		var data := Dictionary(seat_item)
		var current_seat_id := int(data.get("seat_id", data.get("seat_index", -1)))
		if current_seat_id != seat_id:
			continue
		var visual_position := int(data.get("visual_position", data.get("seat_index", 0)))
		if _seats.has(visual_position):
			_seats[visual_position].set_seat_data(data)
		return


func _append_server_history_line(message: String) -> void:
	if _log_panel == null:
		return
	if _log_panel.has_method("append_history_line"):
		_log_panel.call("append_history_line", message)
	else:
		_log_panel.set_info(Array(snapshot.get("hand_history", [])), Array(snapshot.get("system_messages", [])))


func _refresh_server_action_controls() -> void:
	var pot_data = snapshot.get("pot_data", snapshot.get("pot", 0))
	var pot_val := 0
	if pot_data is Dictionary:
		pot_val = int(pot_data.get("total", pot_data.get("main", 0)))
	else:
		pot_val = int(pot_data)
	_action_bar.set_actions(Array(snapshot.get("available_actions", [])), pot_val)
	if _action_bar.has_method("set_turn_prompt"):
		_action_bar.call("set_turn_prompt", String(snapshot.get("turn_prompt", "Waiting for server...")))


func _warn_if_server_ui_slow(label: String, start_msec: int, threshold_msec: int) -> void:
	var elapsed := Time.get_ticks_msec() - start_msec
	if elapsed < threshold_msec:
		return
	var now := Time.get_ticks_msec()
	if now - _server_last_slow_ui_warning_msec < SERVER_UI_WARNING_THROTTLE_MS:
		return
	_server_last_slow_ui_warning_msec = now
	print("%s slow: %d ms" % [label, elapsed])

func _server_event_sequence(event: Dictionary) -> int:
	return int(event.get("sequence", event.get("event_id", event.get("id", 0))))

func _server_history_lines(server_snapshot: Dictionary, room_id: String, side_pots: Array) -> Array:
	var history: Array = []
	for session_item in _session_log:
		history.append(session_item)
	if room_id != "":
		history.append("Authoritative room_id: %s" % room_id)
	history.append("State: %s | Round: %s | Turn seat: %d" % [
		String(server_snapshot.get("hand_state", server_snapshot.get("phase", "waiting"))),
		String(server_snapshot.get("betting_round", server_snapshot.get("phase", "waiting"))),
		int(server_snapshot.get("current_turn_seat", -1)),
	])
	if not side_pots.is_empty():
		history.append("Side pots: %s" % str(side_pots))
	var explicit_history_messages := {}
	if String(server_snapshot.get("phase", "")) == "hand_over":
		for winner_item in Array(server_snapshot.get("winners", [])):
			var winner: Dictionary = Dictionary(winner_item)
			var winner_name := _server_player_name_for_seat(server_snapshot, int(winner.get("seat_index", winner.get("seat_id", -1))))
			var hand_rank := String(winner.get("hand_rank", ""))
			var suffix := " with %s" % hand_rank if hand_rank != "" else ""
			var winner_line := "%s wins %d%s." % [winner_name, int(winner.get("amount", 0)), suffix]
			history.append(winner_line)
			explicit_history_messages[winner_line] = true
		for result_item in Array(server_snapshot.get("last_hand_results", [])):
			var result: Dictionary = Dictionary(result_item)
			var delta := int(result.get("delta", 0))
			var sign := "+" if delta >= 0 else ""
			var result_line := "%s stack %d -> %d (%s%d)." % [
				String(result.get("player_name", "Seat %d" % int(result.get("seat_index", -1)))),
				int(result.get("before_chips", 0)),
				int(result.get("after_chips", 0)),
				sign,
				delta,
			]
			history.append(result_line)
			explicit_history_messages[result_line] = true
	var action_entries: Array = Array(server_snapshot.get("recent_actions", server_snapshot.get("action_log", [])))
	if not action_entries.is_empty():
		for action_item in action_entries:
			var action_data: Dictionary = Dictionary(action_item)
			var message := String(action_data.get("message", ""))
			if message != "" and not explicit_history_messages.has(message):
				history.append(message)
	else:
		for log_item in Array(server_snapshot.get("log", [])):
			history.append(log_item)
	if String(server_snapshot.get("phase", "")) == "waiting":
		history.append("Press S to Start Hand after at least two players are ready.")
	elif String(server_snapshot.get("phase", "")) == "hand_over":
		history.append("Hand over. Press S to Start Next Hand.")
	return history

func _server_turn_message(seats: Array, current_turn_seat: int, local_server_seat: int, phase: String = "") -> String:
	if current_turn_seat < 0:
		if phase == "hand_over":
			return "Hand Over - Press S to Start Next Hand"
		return "Press S to Start Hand when players are ready."
	if current_turn_seat == local_server_seat:
		return "Your Turn"
	for seat_item in seats:
		var seat: Dictionary = Dictionary(seat_item)
		if int(seat.get("seat_id", seat.get("seat_index", -1))) == current_turn_seat:
			return "Waiting for %s" % String(seat.get("player_name", "seat %d" % current_turn_seat))
	return "Waiting for seat %d" % current_turn_seat

func _server_player_name_for_seat(server_snapshot: Dictionary, seat_index: int) -> String:
	for seat_item in Array(server_snapshot.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item)
		if int(seat.get("seat_id", seat.get("seat_index", -1))) == seat_index:
			return String(seat.get("player_name", seat.get("name", "Seat %d" % seat_index)))
	return "Seat %d" % seat_index

func _server_recent_actions_to_visual_events(server_snapshot: Dictionary) -> Array:
	var events: Array = []
	for action_item in Array(server_snapshot.get("recent_actions", server_snapshot.get("action_log", []))):
		var action: Dictionary = Dictionary(action_item)
		var entry_type := String(action.get("type", ""))
		if not (entry_type in ["player_action", "winner"]):
			continue
		var seat_index := int(action.get("seat_id", action.get("seat_index", -1)))
		if seat_index < 0:
			continue
		events.append({
			"id": 1000000 + _server_event_sequence(action),
			"type": "player_action",
			"seat_id": seat_index,
			"action": _server_action_label(String(action.get("action", ""))),
			"amount": int(action.get("amount", 0)),
		})
	return events

func _server_legal_actions_to_ui_actions(actions: Array, pot_value: int) -> Array:
	var result: Array = []
	for action_item in actions:
		var action: Dictionary = Dictionary(action_item)
		var action_id: String = String(action.get("action", ""))
		if action_id == "":
			continue
		var ui_action := {
			"id": action_id,
			"label": _server_action_label(action_id),
			"enabled": true,
		}
		if action.has("amount"):
			ui_action["amount"] = int(action.get("amount", 0))
		if action.has("min_amount"):
			ui_action["min_amount"] = int(action.get("min_amount", 0))
			ui_action["max_amount"] = int(action.get("max_amount", action.get("min_amount", 0)))
		result.append(ui_action)
	return result

func _start_test_hand() -> void:
	_start_next_hand()

func _start_next_hand() -> void:
	if server_authoritative:
		if _poker_ws_client == null or not _server_connected:
			_on_server_error("Cannot start hand: authoritative server is not connected.")
			return
		_server_start_hand_requested = true
		_send_server_message(_poker_ws_client.start_hand(), "start_hand")
		return
	if _table_session == null:
		_configure_table_session_from_launch_context()
	if _table_session != null and not _table_session.can_start_next_hand():
		_enter_session_over()
		return
	var state: String = String(_table_flow.table_state)
	if state == TexasTableFlowScript.HAND_OVER and not _next_hand_ready:
		return
	if state not in [TexasTableFlowScript.WAITING, TexasTableFlowScript.HAND_OVER]:
		return
	if _session_result_panel != null:
		_session_result_panel.visible = false
	_cancel_pending_next_hand_timer()
	_hand_over_sequence_active = false
	_next_hand_ready = true
	_reset_visual_hand_state()
	if String(_table_flow.table_state) == TexasTableFlowScript.WAITING:
		_configure_table_flow_from_launch_context()
	_sync_launch_profile_to_table_flow()
	if not _can_table_flow_start_next_hand():
		_enter_session_over_with_reason("Not enough players")
		return
	var hand_number: int = _table_session.begin_next_hand() if _table_session != null else 0
	if hand_number > 0:
		_append_session_log("Hand %s started." % _session_hand_count_text())
	snapshot = _table_flow_to_ui_snapshot(_table_flow.start_new_hand())
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _advance_test_stage() -> void:
	if server_authoritative:
		_append_session_log("Client-side stage advance is disabled in server authoritative mode.")
		return
	snapshot = _table_flow_to_ui_snapshot(_table_flow.advance_stage())
	_apply_launch_context(snapshot)
	_refresh()
	_schedule_ai_turns()

func _force_test_showdown() -> void:
	if server_authoritative:
		_append_session_log("Client-side showdown is disabled in server authoritative mode.")
		return
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


func _force_current_hand_to_showdown() -> void:
	if server_authoritative:
		_append_session_log("Force showdown is disabled in server authoritative mode.")
		return
	if not _can_use_debug_start_key():
		return
	if String(_table_flow.table_state) == TexasTableFlowScript.WAITING:
		_start_next_hand()
		return
	snapshot = _table_flow_to_ui_snapshot(_table_flow.force_current_hand_to_showdown())
	_apply_launch_context(snapshot)
	_refresh()


func _force_finish_current_session() -> void:
	if server_authoritative:
		_append_session_log("Force finish is disabled in server authoritative mode.")
		return
	if not _can_use_debug_start_key():
		return
	if _table_session == null:
		_configure_table_session_from_launch_context()
	if _table_session == null:
		return
	_table_session.current_table_chips = _local_table_chips()
	_table_session.session_end_chips = _table_session.current_table_chips
	_table_session.session_profit = _table_session.session_end_chips - _table_session.session_start_chips
	_table_session.is_session_over = true
	_table_session.end_reason = "Debug force finish"
	_append_session_log("Debug: force finish current session.")
	_enter_session_over()

func _reset_test_table() -> void:
	_cancel_pending_next_hand_timer()
	if server_authoritative:
		_boot_server_authoritative_table()
		return
	_ai_turn_loop_active = false
	_hand_over_sequence_active = false
	_next_hand_ready = true
	_visual_pause_until_msec = 0
	_reset_visual_hand_state()
	_configure_table_flow_from_launch_context()
	_configure_table_session_from_launch_context()
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
	if _table_session != null:
		table_chips = _table_session.current_table_chips
	var should_seed_chips: bool = String(_table_flow.table_state) == TexasTableFlowScript.WAITING
	if _table_session != null:
		should_seed_chips = should_seed_chips and _table_session.hands_played == 0 and _table_session.current_hand_index == 0
	for i in range(_table_flow.seats.size()):
		var seat: Dictionary = Dictionary(_table_flow.seats[i]).duplicate(true)
		if not bool(seat.get("is_local", false)):
			continue
		seat["player_id"] = String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID))
		seat["player_name"] = local_name
		seat["avatar_id"] = local_avatar_id
		if should_seed_chips:
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
			card["face_up"] = _should_show_hole_cards(seat, stage)
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
	var table_log: Array = []
	for session_item in _session_log:
		table_log.append(session_item)
	for log_item in Array(source.get("table_log", [])):
		table_log.append(log_item)
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
		"hand_history": table_log,
		"system_messages": ["TexasTableFlow data binding active"],
		"visual_events": Array(hand.get("visual_events", [])).duplicate(true),
		"rule_debug_log": Array(source.get("rule_debug_log", [])).duplicate(),
		"table_session": _table_session.to_dict() if _table_session != null else {},
	}


func _should_show_hole_cards(seat: Dictionary, stage: String) -> bool:
	if bool(seat.get("is_local", false)):
		return true
	var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
	var status: String = String(seat.get("status", ""))
	if stage == TexasTableFlowScript.SHOWDOWN and _is_showdown_eligible_status(status):
		return true
	if _showdown_reveal_active and _showdown_revealed_player_ids.has(seat_id):
		return true
	return false


func _is_showdown_eligible_status(status: String) -> bool:
	return status not in [
		TexasTableFlowScript.EMPTY,
		TexasTableFlowScript.FOLDED,
		TexasTableFlowScript.OUT,
		"empty",
		"folded",
		"left",
		"out",
	]

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
	if _action_bar.has_method("set_turn_prompt"):
		_action_bar.call("set_turn_prompt", String(snapshot.get("turn_prompt", "BET AMOUNT")))
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
			if _room_info_panel.has_method("set_hand_progress"):
				_room_info_panel.call("set_hand_progress", _session_progress_text())
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
	if server_authoritative:
		if _poker_ws_client == null or not _server_connected:
			_on_server_error("Cannot send action: authoritative server is not connected.")
			return
		var amount := 0
		if action_id in ["bet", "raise"]:
			amount = int(action.get("amount", action.get("min_amount", 0)))
		_server_waiting_for_action_ack = true
		_send_server_message(_poker_ws_client.player_action(action_id, amount), "player_action %s" % action_id)
		snapshot["available_actions"] = []
		snapshot["turn_prompt"] = "Waiting for server..."
		_refresh_server_action_controls()
		return
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
	if server_authoritative:
		return
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
	_clear_hand_result_reveal_state()
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
	if SERVER_UI_VERBOSE_LOGS:
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
		if SERVER_UI_VERBOSE_LOGS:
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
	if SERVER_UI_VERBOSE_LOGS:
		print("collect_all_bets_to_pot start")
		print("collect bets animation start")
	var bets: Array = Array(event.get("bets", []))
	var longest_delay: float = 0.0
	for i in range(bets.size()):
		var bet: Dictionary = Dictionary(bets[i])
		var seat_id: int = int(bet.get("seat_id", -1))
		var amount: int = int(bet.get("amount", 0))
		if SERVER_UI_VERBOSE_LOGS:
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
		if SERVER_UI_VERBOSE_LOGS:
			print("after clear: seat %d current_bet %d" % [
				int(data.get("seat_id", data.get("seat_index", -1))),
				int(data.get("current_bet", 0)),
			])
	if SERVER_UI_VERBOSE_LOGS:
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
		_clear_hand_result_reveal_state()
		return
	if _hand_over_sequence_active:
		return
	_hand_over_sequence_active = true
	_next_hand_ready = false
	_record_session_hand_result_once()
	_begin_hand_result_reveal()

func _begin_hand_result_reveal() -> void:
	var hand: Dictionary = Dictionary(_table_flow.hand_data)
	var settlement: Dictionary = Dictionary(hand.get("settlement", {}))
	var end_reason: String = String(settlement.get("end_reason", hand.get("end_reason", "")))
	var reveal_ids: Array[int] = _hand_result_reveal_ids(hand, settlement, end_reason)
	_showdown_revealed_player_ids = reveal_ids
	_showdown_reveal_active = reveal_ids.size() >= 2 and end_reason != "everyone_folded"
	_hand_result_hold_seconds = float(settlement.get(
		"result_hold_seconds",
		SHOWDOWN_REVEAL_HOLD_SECONDS if _showdown_reveal_active else FOLD_WIN_HOLD_SECONDS
	))
	if _hand_result_hold_seconds <= 0.0:
		_hand_result_hold_seconds = SHOWDOWN_REVEAL_HOLD_SECONDS if _showdown_reveal_active else FOLD_WIN_HOLD_SECONDS
	_hand_result_message = _hand_result_summary_text(settlement, end_reason)
	_apply_showdown_reveal_to_snapshot()
	_refresh_revealed_seat_cards()
	_show_hand_result_banner("SHOWDOWN" if _showdown_reveal_active else "HAND RESULT", _hand_result_message)
	_append_session_log(_hand_result_message)
	_schedule_next_hand_after_result(_hand_result_hold_seconds)


func _hand_result_reveal_ids(hand: Dictionary, settlement: Dictionary, end_reason: String) -> Array[int]:
	var result: Array[int] = []
	if end_reason == "everyone_folded":
		return result
	var raw_ids: Array = Array(settlement.get("showdown_revealed_player_ids", hand.get("showdown_revealed_player_ids", [])))
	for item in raw_ids:
		var seat_id: int = int(item)
		if seat_id > 0 and not result.has(seat_id):
			result.append(seat_id)
	if result.size() >= 2:
		return result
	for seat_item in _table_flow.seats:
		var seat: Dictionary = Dictionary(seat_item)
		var status: String = String(seat.get("status", ""))
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		if seat_id > 0 and _is_showdown_eligible_status(status) and not result.has(seat_id):
			result.append(seat_id)
	if result.size() >= 2:
		return result
	return []


func _hand_result_summary_text(settlement: Dictionary, end_reason: String) -> String:
	var explicit_summary: String = String(settlement.get("showdown_summary", ""))
	if explicit_summary != "":
		return explicit_summary
	var winner_names: Array[String] = []
	for winner_name in Array(settlement.get("winner_names", [])):
		winner_names.append(String(winner_name))
	var winner_text: String = ", ".join(winner_names) if not winner_names.is_empty() else "Winner"
	var pot_amount: int = int(settlement.get("pot_before_settlement", settlement.get("win_amount", 0)))
	var hand_rank: String = String(settlement.get("hand_description", settlement.get("hand_rank", "")))
	if end_reason == "everyone_folded":
		return "Everyone folded.\n%s wins %d chips." % [winner_text, pot_amount]
	var rank_suffix: String = " with %s" % hand_rank if hand_rank != "" else ""
	if winner_names.size() > 1:
		return "%s split %d chips%s." % [winner_text, pot_amount, rank_suffix]
	return "%s wins %d chips%s." % [winner_text, pot_amount, rank_suffix]


func _apply_showdown_reveal_to_snapshot() -> void:
	var seats: Array = Array(snapshot.get("seats", [])).duplicate(true)
	for i in range(seats.size()):
		var seat: Dictionary = Dictionary(seats[i]).duplicate(true)
		var seat_id: int = int(seat.get("seat_id", seat.get("seat_index", 0)))
		var cards: Array = Array(seat.get("cards", [])).duplicate(true)
		for card_index in range(cards.size()):
			var card: Dictionary = Dictionary(cards[card_index]).duplicate(true)
			if _showdown_reveal_active and _showdown_revealed_player_ids.has(seat_id):
				card["face_up"] = true
			elif not bool(seat.get("is_local", false)):
				card["face_up"] = false
			cards[card_index] = card
		seat["cards"] = cards
		seats[i] = seat
	snapshot["seats"] = seats
	snapshot["showdown_revealed_player_ids"] = _showdown_revealed_player_ids.duplicate()
	snapshot["hand_result_message"] = _hand_result_message
	snapshot["hand_result_hold_seconds"] = _hand_result_hold_seconds


func _refresh_revealed_seat_cards() -> void:
	for seat_data in Array(snapshot.get("seats", [])):
		var data: Dictionary = Dictionary(seat_data)
		var visual_position: int = int(data.get("visual_position", data.get("seat_index", 0)))
		if _seats.has(visual_position):
			_seats[visual_position].set_seat_data(data)


func _show_hand_result_banner(title: String, body: String) -> void:
	if _hand_result_banner == null:
		return
	_hand_result_title_label.text = title
	_hand_result_body_label.text = body
	_hand_result_banner.visible = true


func _hide_hand_result_banner() -> void:
	if _hand_result_banner != null:
		_hand_result_banner.visible = false


func _schedule_next_hand_after_result(delay_seconds: float) -> void:
	_pending_next_hand_token += 1
	var token: int = _pending_next_hand_token
	call_deferred("_wait_and_start_next_hand_after_result", token, delay_seconds)


func _wait_and_start_next_hand_after_result(token: int, delay_seconds: float) -> void:
	await get_tree().create_timer(delay_seconds).timeout
	if token != _pending_next_hand_token:
		return
	if String(_table_flow.table_state) != TexasTableFlowScript.HAND_OVER:
		_hand_over_sequence_active = false
		_clear_hand_result_reveal_state()
		return
	_next_hand_ready = true
	if _table_session != null and _table_session.is_session_over:
		_enter_session_over()
		return
	if _table_session != null and _table_session.can_start_next_hand():
		_start_next_hand()


func _cancel_pending_next_hand_timer() -> void:
	_pending_next_hand_token += 1
	_next_hand_ready = true
	_clear_hand_result_reveal_state()


func _clear_hand_result_reveal_state() -> void:
	_showdown_reveal_active = false
	_showdown_revealed_player_ids.clear()
	_hand_result_message = ""
	_hand_result_hold_seconds = 0.0
	_hide_hand_result_banner()


func _record_session_hand_result_once() -> void:
	if _table_session == null:
		return
	var hand: Dictionary = Dictionary(_table_flow.hand_data)
	var hand_id: String = String(hand.get("hand_id", ""))
	if hand_id == "":
		return
	if _recorded_session_hand_ids.has(hand_id):
		return
	_recorded_session_hand_ids[hand_id] = true
	var settlement: Dictionary = Dictionary(hand.get("settlement", {}))
	var local_seat_id: int = int(snapshot.get("local_seat_index", 5))
	var local_chips: int = _local_table_chips()
	_table_session.record_hand_result(settlement, local_seat_id, local_chips)
	var winner_names: Array[String] = []
	for winner_name in Array(settlement.get("winner_names", [])):
		winner_names.append(String(winner_name))
	_append_session_log("Hand %s complete. Winner: %s +%d." % [
		_session_hand_count_text(),
		", ".join(winner_names) if not winner_names.is_empty() else "-",
		int(settlement.get("win_amount", 0)),
	])
	if _table_session.is_session_over:
		_append_session_log("Table session complete. Profit %+d." % _table_session.session_profit)


func _enter_session_over() -> void:
	if _table_session == null:
		return
	_table_session.is_session_over = true
	_next_hand_ready = false
	_auto_next_hand_enabled = false
	_apply_session_profit_to_profile()
	_update_launch_context_session()
	_show_session_result_panel()
	_refresh_rule_debug_panel()


func _enter_session_over_with_reason(reason: String) -> void:
	if _table_session == null:
		_configure_table_session_from_launch_context()
	if _table_session == null:
		return
	if reason != "":
		_table_session.end_reason = reason
	_table_session.current_table_chips = _local_table_chips()
	_table_session.session_end_chips = _table_session.current_table_chips
	_table_session.session_profit = _table_session.session_end_chips - _table_session.session_start_chips
	_append_session_log("Table session complete: %s." % reason)
	_enter_session_over()


func _can_table_flow_start_next_hand() -> bool:
	if _table_flow == null:
		return false
	var eligible: Array[int] = _table_flow.eligible_next_hand_seat_ids()
	for line in _table_flow.next_hand_eligibility_report():
		print("[NextHandEligibility] %s" % line)
	if eligible.size() < 2:
		_append_session_log("Cannot start next hand: only %d eligible player%s." % [
			eligible.size(),
			"" if eligible.size() == 1 else "s",
		])
		return false
	return true


func _configure_table_session_from_launch_context() -> void:
	var context: Dictionary = TableLaunchContext.get_current_table_context()
	_table_session = TableSessionScript.from_context(context)
	_auto_next_hand_enabled = _table_session.mode != TableSessionScript.MODE_TRAINING
	_apply_dealer_cosmetic()
	_session_log.clear()
	_recorded_session_hand_ids.clear()
	_session_unlocked_avatar_ids.clear()
	_session_started = false
	_profile_settlement_applied = false
	_append_session_log("Table session ready.")
	_append_session_log("Buy-in: %d. Blinds: %d / %d. Hands: %s." % [
		_table_session.buy_in,
		_table_session.small_blind,
		_table_session.big_blind,
		"Unlimited" if _table_session.max_hands >= 999 else str(_table_session.max_hands),
	])


func _auto_start_session_if_ready() -> void:
	if _table_session == null:
		_configure_table_session_from_launch_context()
	if _table_session == null or _session_started:
		return
	if String(_table_flow.table_state) != TexasTableFlowScript.WAITING:
		return
	_session_started = true
	_append_session_log("Table session started.")
	if _table_session.mode == TableSessionScript.MODE_TRAINING:
		_append_session_log("Training mode. Space starts next hand after HAND_OVER.")
	_start_next_hand()


func _can_use_debug_start_key() -> bool:
	return TableLaunchContext.allow_debug_tools or TableLaunchContext.is_training or OS.is_debug_build()


func _can_use_space_next_hand() -> bool:
	return TableLaunchContext.is_training or TableLaunchContext.allow_debug_tools


func _append_session_log(message: String) -> void:
	if message == "":
		return
	_session_log.append(message)
	if _session_log.size() > 16:
		while _session_log.size() > 16:
			_session_log.remove_at(0)
	print("[TableSession] %s" % message)


func _session_hand_count_text() -> String:
	if _table_session == null:
		return "-"
	return _table_session.hand_count_text()


func _session_progress_text() -> String:
	if _table_session == null:
		return "Hand 0 / 0"
	if _table_session.max_hands <= 0 or _table_session.max_hands >= 999:
		return "Hand %d / ∞" % max(_table_session.current_hand_index, _table_session.hands_played)
	return "Hand %d / %d" % [max(_table_session.current_hand_index, _table_session.hands_played), _table_session.max_hands]


func _local_table_chips() -> int:
	for seat_item in _table_flow.seats:
		var seat: Dictionary = Dictionary(seat_item)
		if bool(seat.get("is_local", false)):
			return int(seat.get("chips", 0))
	return _table_session.current_table_chips if _table_session != null else 0


func _update_launch_context_session() -> void:
	if _table_session == null:
		return
	TableLaunchContext.table_session = _table_session.to_dict()


func _build_session_result_panel() -> void:
	_session_result_scrim = _content_root.get_node_or_null("SessionResultScrim") as ColorRect
	if _session_result_scrim == null:
		_session_result_scrim = ColorRect.new()
		_session_result_scrim.name = "SessionResultScrim"
		_session_result_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_session_result_scrim.color = Color(0.005, 0.003, 0.012, 0.18)
		_session_result_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_session_result_scrim.z_index = 41
		_content_root.add_child(_session_result_scrim)
	_session_result_scrim.visible = false

	_session_result_panel = _content_root.get_node_or_null("SessionResultPanel") as PanelContainer
	if _session_result_panel == null:
		_session_result_panel = PanelContainer.new()
		_session_result_panel.name = "SessionResultPanel"
		_session_result_panel.position = Vector2(885, 220)
		_session_result_panel.size = Vector2(790, 500)
		_session_result_panel.custom_minimum_size = _session_result_panel.size
		_session_result_panel.z_index = 42
		_session_result_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		_session_result_panel.add_theme_stylebox_override("panel", _session_result_panel_style())
		_content_root.add_child(_session_result_panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 30)
		margin.add_theme_constant_override("margin_right", 30)
		margin.add_theme_constant_override("margin_top", 28)
		margin.add_theme_constant_override("margin_bottom", 24)
		_session_result_panel.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 18)
		margin.add_child(column)

		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 18)
		column.add_child(header_row)

		var avatar_frame := PanelContainer.new()
		avatar_frame.custom_minimum_size = Vector2(86, 86)
		avatar_frame.add_theme_stylebox_override("panel", _session_avatar_frame_style())
		header_row.add_child(avatar_frame)
		_session_result_avatar = TextureRect.new()
		_session_result_avatar.name = "SessionResultAvatar"
		_session_result_avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_session_result_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_session_result_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_session_result_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_session_result_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_frame.add_child(_session_result_avatar)

		var title_box := VBoxContainer.new()
		title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_box.add_theme_constant_override("separation", 5)
		header_row.add_child(title_box)
		var title_label := Label.new()
		title_label.text = "SESSION COMPLETE"
		title_label.add_theme_font_size_override("font_size", 34)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 1.0))
		title_box.add_child(title_label)
		_session_result_name_label = Label.new()
		_session_result_name_label.name = "SessionResultPlayerName"
		_session_result_name_label.add_theme_font_size_override("font_size", 18)
		_session_result_name_label.add_theme_color_override("font_color", Color(0.74, 0.86, 1.0, 0.86))
		title_box.add_child(_session_result_name_label)

		_session_result_text = RichTextLabel.new()
		_session_result_text.name = "SessionResultText"
		_session_result_text.bbcode_enabled = true
		_session_result_text.fit_content = false
		_session_result_text.scroll_active = false
		_session_result_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_session_result_text.add_theme_font_size_override("normal_font_size", 20)
		_session_result_text.add_theme_color_override("default_color", Color(0.92, 0.94, 1.0))
		_session_result_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_session_result_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(_session_result_text)
		var unlock_row := HBoxContainer.new()
		unlock_row.name = "SessionUnlockRow"
		unlock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		unlock_row.add_theme_constant_override("separation", 12)
		column.add_child(unlock_row)
		_session_unlock_avatar = TextureRect.new()
		_session_unlock_avatar.name = "SessionUnlockAvatar"
		_session_unlock_avatar.custom_minimum_size = Vector2(54, 54)
		_session_unlock_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_session_unlock_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_session_unlock_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_session_unlock_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		unlock_row.add_child(_session_unlock_avatar)
		_session_unlock_label = Label.new()
		_session_unlock_label.name = "SessionUnlockLabel"
		_session_unlock_label.add_theme_font_size_override("font_size", 15)
		_session_unlock_label.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0, 0.96))
		unlock_row.add_child(_session_unlock_label)
		_session_play_again_hint_label = Label.new()
		_session_play_again_hint_label.name = "PlayAgainHintLabel"
		_session_play_again_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_session_play_again_hint_label.add_theme_font_size_override("font_size", 14)
		_session_play_again_hint_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.70, 0.92))
		column.add_child(_session_play_again_hint_label)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 18)
		column.add_child(row)
		var play_again := Button.new()
		play_again.name = "PlayAgainButton"
		play_again.text = "PLAY AGAIN"
		play_again.custom_minimum_size = Vector2(180, 48)
		play_again.pressed.connect(_restart_session)
		row.add_child(play_again)
		_session_play_again_button = play_again
		var home_button := Button.new()
		home_button.name = "BackHomeButton"
		home_button.text = "BACK TO HOME"
		home_button.custom_minimum_size = Vector2(190, 48)
		home_button.pressed.connect(_return_home)
		row.add_child(home_button)
	else:
		_session_result_text = _session_result_panel.find_child("SessionResultText", true, false) as RichTextLabel
		_session_result_avatar = _session_result_panel.find_child("SessionResultAvatar", true, false) as TextureRect
		_session_result_name_label = _session_result_panel.find_child("SessionResultPlayerName", true, false) as Label
		_session_unlock_avatar = _session_result_panel.find_child("SessionUnlockAvatar", true, false) as TextureRect
		_session_unlock_label = _session_result_panel.find_child("SessionUnlockLabel", true, false) as Label
		_session_play_again_hint_label = _session_result_panel.find_child("PlayAgainHintLabel", true, false) as Label
		_session_play_again_button = _session_result_panel.find_child("PlayAgainButton", true, false) as Button
	_session_result_panel.visible = false


func _show_session_result_panel() -> void:
	if _session_result_panel == null or _session_result_text == null or _table_session == null:
		return
	var can_play_again := _can_play_again()
	if _session_play_again_button != null:
		_session_play_again_button.name = "PlayAgainButton"
		_session_play_again_button.disabled = not can_play_again
		_session_play_again_button.tooltip_text = "" if can_play_again else "Not enough chips for this buy-in."
		_apply_session_button_style(_session_play_again_button, "primary", not can_play_again)
	var back_button: Button = _session_result_panel.find_child("BackHomeButton", true, false) as Button
	if back_button != null:
		_apply_session_button_style(back_button, "secondary", false)
	if _session_play_again_hint_label != null:
		_session_play_again_hint_label.text = "" if can_play_again else "Not enough chips for this buy-in"
	var profile: Dictionary = TableLaunchContext.get_player_profile()
	if _session_result_name_label != null:
		_session_result_name_label.text = "%s  |  %s" % [PlayerProfileScript.get_player_name(profile), _session_mode_label()]
	if _session_result_avatar != null:
		var avatar_texture: Texture2D = AvatarLibraryScript.get_avatar_by_id(PlayerProfileScript.get_avatar_id(profile))
		_session_result_avatar.texture = avatar_texture
		_session_result_avatar.visible = avatar_texture != null
	if _session_unlock_label != null and _session_unlock_avatar != null:
		if _session_unlocked_avatar_ids.is_empty():
			_session_unlock_label.visible = false
			_session_unlock_avatar.visible = false
		else:
			var unlocked_id: String = _session_unlocked_avatar_ids[0]
			_session_unlock_label.text = "New Avatar Unlocked!  %s" % unlocked_id
			_session_unlock_label.visible = true
			_session_unlock_avatar.texture = AvatarLibraryScript.get_avatar_by_id(unlocked_id)
			_session_unlock_avatar.visible = _session_unlock_avatar.texture != null
	var is_practice := _table_session.mode == TableSessionScript.MODE_TRAINING or _table_session.uses_practice_chips
	var profit_color := "#35f5c8" if _table_session.session_profit >= 0 else "#ff4f9a"
	var reason: String = _table_session.end_reason if _table_session.end_reason != "" else "Session ended"
	var result_lines: Array[String] = [
		"[center][font_size=30][color=%s][b]%+d[/b][/color][/font_size][/center]" % [profit_color, _table_session.session_profit],
		"[center][color=#8fa8ff]%s[/color][/center]" % ("Practice chips only. Results do not affect your account balance." if is_practice else "Buy-in moved from wallet to table. Final table chips returned to wallet."),
		"",
		"[table=2][cell][color=#9aa8d8]Buy-in[/color]\n[b]%s[/b][/cell][cell][color=#9aa8d8]Final Table Chips[/color]\n[b]%s[/b][/cell]" % [
			_format_chips(_table_session.buy_in),
			_format_chips(_table_session.session_end_chips),
		],
		"[cell][color=#9aa8d8]Returned to Wallet[/color]\n[b]%s[/b][/cell][cell][color=#9aa8d8]Session Profit[/color]\n[color=%s][b]%+d[/b][/color][/cell]" % [
			_format_chips(_table_session.session_end_chips),
			profit_color,
			_table_session.session_profit,
		],
		"[cell][color=#9aa8d8]Hands Won[/color]\n[b]%d[/b][/cell][cell][color=#9aa8d8]Biggest Pot[/color]\n[b]%s[/b][/cell][/table]" % [
			_table_session.hands_won,
			_format_chips(_table_session.biggest_pot),
		],
		"",
		"Mode: %s    Blinds: %d / %d" % [_session_mode_label(), _table_session.small_blind, _table_session.big_blind],
		"Hands Played: %s" % _table_session.hand_count_text(),
		"Starting Chips: %s" % _format_chips(_table_session.session_start_chips),
		"Best Hand: %s" % _table_session.best_hand_desc,
		"Last Winner: %s" % _table_session.last_winner,
		"End Reason: %s" % reason,
	]
	if is_practice:
		result_lines.append("Training uses practice chips only. Results do not affect your account balance.")
	_session_result_text.text = "\n".join(result_lines)
	if _session_result_scrim != null:
		_session_result_scrim.visible = true
	_session_result_panel.visible = true


func _restart_session() -> void:
	if not _can_play_again():
		_append_session_log("Play Again blocked: not enough chips for buy-in %d." % (_table_session.buy_in if _table_session != null else 0))
		return
	if _session_result_panel != null:
		_session_result_panel.visible = false
	if _session_result_scrim != null:
		_session_result_scrim.visible = false
	if _table_session != null and not (_table_session.mode == TableSessionScript.MODE_TRAINING or _table_session.uses_practice_chips):
		var service := ProfileServiceScript.new()
		var buy_in_profile: Dictionary = service.deduct_table_buy_in(_table_session.buy_in)
		if buy_in_profile.is_empty():
			_append_session_log("Play Again blocked: not enough chips for buy-in %d." % _table_session.buy_in)
			return
		TableLaunchContext.set_player_profile(buy_in_profile)
	_reset_launch_context_session_for_play_again()
	_configure_table_flow_from_launch_context()
	_configure_table_session_from_launch_context()
	_table_flow.reset_table()
	_sync_launch_profile_to_table_flow()
	snapshot = _table_flow_to_ui_snapshot(_table_flow.to_snapshot())
	_apply_launch_context(snapshot)
	_refresh()
	_session_started = false
	_auto_start_session_if_ready()


func _apply_session_profit_to_profile() -> void:
	if _profile_settlement_applied or _table_session == null:
		return
	_profile_settlement_applied = true
	if _table_session.mode == TableSessionScript.MODE_TRAINING or _table_session.uses_practice_chips or not _table_session.affects_account_balance:
		_session_unlocked_avatar_ids.clear()
		_append_session_log("Training results use practice chips only; account balance and stats were not updated.")
		return
	var service := ProfileServiceScript.new()
	var profile := service.apply_session_result(_table_session.to_dict())
	_session_unlocked_avatar_ids = service.get_last_unlocked_avatar_ids()
	TableLaunchContext.set_player_profile(profile)
	_append_session_log("Profile wallet refunded %d table chips. Session profit %+d." % [_table_session.session_end_chips, _table_session.session_profit])


func _reset_launch_context_session_for_play_again() -> void:
	if _table_session == null:
		return
	TableLaunchContext.buy_in = _table_session.buy_in
	TableLaunchContext.small_blind = _table_session.small_blind
	TableLaunchContext.big_blind = _table_session.big_blind
	TableLaunchContext.max_hands = _table_session.max_hands
	TableLaunchContext.table_session = {
		"mode": _table_session.mode,
		"table_type": _table_session.table_type,
		"uses_practice_chips": _table_session.uses_practice_chips,
		"affects_account_balance": _table_session.affects_account_balance,
		"buy_in_deducted_from_wallet": _table_session.buy_in_deducted_from_wallet,
		"buy_in": _table_session.buy_in,
		"starting_chips": _table_session.buy_in,
		"current_table_chips": _table_session.buy_in,
		"small_blind": _table_session.small_blind,
		"big_blind": _table_session.big_blind,
		"max_hands": _table_session.max_hands,
		"current_hand_index": 0,
		"session_start_chips": _table_session.buy_in,
		"session_end_chips": _table_session.buy_in,
		"session_profit": 0,
		"hands_played": 0,
		"hands_won": 0,
		"biggest_pot": 0,
		"best_hand_desc": "-",
		"is_session_over": false,
		"end_reason": "",
		"last_winner": "-",
		"last_win_amount": 0,
		"selected_dealer_id": _table_session.selected_dealer_id,
	}


func _can_play_again() -> bool:
	if _table_session == null:
		return false
	if _table_session.mode == TableSessionScript.MODE_TRAINING or _table_session.uses_practice_chips:
		return true
	var profile := ProfileServiceScript.new().get_current_profile()
	return PlayerProfileScript.get_total_chips(profile) >= _table_session.buy_in


func _session_mode_label() -> String:
	if _table_session == null:
		return "-"
	match _table_session.mode:
		TableSessionScript.MODE_QUICK_PLAY:
			return "Quick Play"
		TableSessionScript.MODE_TRAINING:
			return "Training"
		TableSessionScript.MODE_FRIENDS_ROOM:
			return "Friends Room"
		_:
			return _table_session.mode.capitalize()


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
	if server_authoritative:
		_rule_debug_text.text = _server_rule_debug_text()
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
	if _table_session != null:
		lines.append("SESSION mode=%s hand=%s buy_in=%d over=%s reason=%s" % [
			_table_session.mode,
			_table_session.hand_count_text(),
			_table_session.buy_in,
			str(_table_session.is_session_over),
			_table_session.end_reason if _table_session.end_reason != "" else "-",
		])
		lines.append("session_start=%d final=%d table_chips=%d profit=%+d played=%d won=%d biggest=%d best=%s" % [
			_table_session.session_start_chips,
			_table_session.session_end_chips,
			_table_session.current_table_chips,
			_table_session.session_profit,
			_table_session.hands_played,
			_table_session.hands_won,
			_table_session.biggest_pot,
			_table_session.best_hand_desc,
		])
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

func _server_rule_debug_text() -> String:
	var lines: Array[String] = []
	lines.append("SERVER AUTHORITATIVE DEBUG  (Ctrl+D hide/show)")
	lines.append("connected=%s room_id=%s local_seat=%d" % [str(_server_connected), _server_room_id if _server_room_id != "" else "-", _server_local_seat_index])
	lines.append("state=%s hand=%s current_turn=%d pot=%d" % [
		String(snapshot.get("phase", "waiting")),
		String(snapshot.get("hand_id", "-")),
		int(snapshot.get("turn_seat_index", -1)),
		int(snapshot.get("pot", 0)),
	])
	if _server_last_error != "":
		lines.append("last_error=%s" % _server_last_error)
	lines.append("")
	lines.append("SEATS")
	for seat_item in Array(snapshot.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item)
		lines.append("Seat %d | %s | chips=%d | bet=%d | status=%s | turn=%s" % [
			int(seat.get("seat_index", -1)),
			String(seat.get("player_name", "")),
			int(seat.get("chips", 0)),
			int(seat.get("current_bet", 0)),
			String(seat.get("raw_status", seat.get("status", ""))),
			str(bool(seat.get("is_turn", false))),
		])
	lines.append("")
	lines.append("SERVER LOG")
	var history: Array = Array(snapshot.get("hand_history", []))
	var start_index: int = max(history.size() - 18, 0)
	for i in range(start_index, history.size()):
		lines.append(String(history[i]))
	return "\n".join(lines)


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


func _session_result_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.006, 0.036, 0.92)
	style.border_color = Color(1.0, 0.0, 0.76, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.75, 0.0, 1.0, 0.34)
	style.shadow_size = 24
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _session_avatar_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.012, 0.032, 0.86)
	style.border_color = Color(0.60, 0.92, 1.0, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.72, 1.0, 0.20)
	style.shadow_size = 14
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _apply_session_button_style(button: Button, variant: String, disabled: bool) -> void:
	var accent: Color = Color(0.35, 0.95, 1.0, 0.86) if variant == "primary" else Color(0.82, 0.58, 1.0, 0.66)
	var bg: Color = Color(0.03, 0.07, 0.13, 0.90) if variant == "primary" else Color(0.032, 0.022, 0.06, 0.82)
	if disabled:
		accent = Color(0.30, 0.32, 0.42, 0.42)
		bg = Color(0.014, 0.014, 0.026, 0.68)
	button.add_theme_stylebox_override("normal", _session_button_style(bg, accent, disabled))
	button.add_theme_stylebox_override("hover", _session_button_style(bg.lightened(0.08), accent.lightened(0.15), disabled))
	button.add_theme_stylebox_override("pressed", _session_button_style(bg.darkened(0.08), accent, disabled))
	button.add_theme_stylebox_override("disabled", _session_button_style(bg, accent, true))
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 0.96))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.50, 0.60, 0.92))
	button.add_theme_font_size_override("font_size", 15)


func _session_button_style(bg: Color, border: Color, disabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(border.r, border.g, border.b, 0.0 if disabled else 0.24)
	style.shadow_size = 0 if disabled else 12
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
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
	_cancel_pending_next_hand_timer()
	if server_authoritative:
		if _server_cash_out_pending_return:
			return
		if _poker_ws_client != null and _server_connected:
			_server_cash_out_pending_return = true
			_append_session_log("Requesting server cash out...")
			_send_server_message(_poker_ws_client.cash_out(), "cash_out")
			return
		_complete_return_home()
		return
	_complete_return_home()


func _complete_return_home() -> void:
	if _poker_ws_client != null:
		_poker_ws_client.close()
	if not server_authoritative:
		if _table_session != null and _table_session.is_session_over:
			_apply_session_profit_to_profile()
		else:
			_cash_out_remaining_table_chips_to_wallet()
	TableLaunchContext.clear_table_session()
	ScreenNavigator.return_home(get_tree())


func _cash_out_remaining_table_chips_to_wallet() -> void:
	if _profile_settlement_applied or _table_session == null:
		return
	if _table_session.mode == TableSessionScript.MODE_TRAINING or _table_session.uses_practice_chips or not _table_session.affects_account_balance:
		return
	if not _table_session.buy_in_deducted_from_wallet:
		return
	var refund_amount: int = max(_local_table_chips(), 0)
	_profile_settlement_applied = true
	if refund_amount <= 0:
		_append_session_log("%s left table. No table chips returned to wallet." % PlayerProfileScript.get_player_name(ProfileServiceScript.new().get_current_profile()))
		return
	var service := ProfileServiceScript.new()
	var profile: Dictionary = service.refund_table_chips(refund_amount)
	TableLaunchContext.set_player_profile(profile)
	_zero_local_table_chips()
	if _table_session != null:
		_table_session.current_table_chips = 0
		_table_session.session_end_chips = 0
		_table_session.session_profit = -_table_session.session_start_chips
		_update_launch_context_session()
	var player_name: String = PlayerProfileScript.get_player_name(profile)
	if _table_flow.table_state == TexasTableFlowScript.WAITING or _table_flow.table_state == TexasTableFlowScript.HAND_OVER:
		_append_session_log("%s left table. Returned %s chips to wallet." % [player_name, _format_chips(refund_amount)])
	else:
		_append_session_log("%s left during hand. Returned remaining stack %s to wallet. Committed chips stay in pot." % [player_name, _format_chips(refund_amount)])


func _zero_local_table_chips() -> void:
	for i in range(_table_flow.seats.size()):
		var seat: Dictionary = Dictionary(_table_flow.seats[i]).duplicate(true)
		if not bool(seat.get("is_local", false)):
			continue
		seat["chips"] = 0
		seat["current_bet"] = 0
		seat["status"] = "left"
		seat["folded"] = true
		_table_flow.seats[i] = seat
		break

func _apply_launch_context(target_snapshot: Dictionary) -> void:
	if String(target_snapshot.get("source_model", "")) == "server_authoritative":
		target_snapshot["connection_status"] = "LOCAL AUTHORITATIVE SERVER"
		_apply_local_profile_to_snapshot(target_snapshot)
		return
	if TableLaunchContext.is_training or TableLaunchContext.launch_mode == "training":
		target_snapshot["table_id"] = TableLaunchContext.table_id
		target_snapshot["table_name"] = "Training Table"
		target_snapshot["connection_status"] = "OFFLINE TRAINING"
		var history: Array = Array(target_snapshot.get("hand_history", [])).duplicate()
		history.insert(0, "Training hint: use Call/Raise to observe mock pot updates")
		target_snapshot["hand_history"] = history
		var messages: Array = Array(target_snapshot.get("system_messages", [])).duplicate()
		messages.insert(0, "Training Mode: AI opponents, no network authority")
		messages.insert(1, "Training uses practice chips only. Results do not affect your account balance.")
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
	var is_server_snapshot := String(target_snapshot.get("source_model", "")) == "server_authoritative"
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
		if is_server_snapshot:
			seat["buy_in"] = int(target_snapshot.get("buy_in", seat.get("buy_in", SERVER_DEFAULT_BUY_IN)))
			seat["server_authoritative"] = true
			seat["win_rate"] = "N/A"
		else:
			seat["buy_in"] = TableLaunchContext.buy_in
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

	var dealer_button := _top_control_button("DEALER", Vector2(118, 56))
	_dealer_cosmetic_button = dealer_button
	dealer_button.tooltip_text = "Choose dealer character."
	dealer_button.pressed.connect(_toggle_dealer_cosmetic_panel)
	_top_right_action_bar.add_child(dealer_button)

	var add_chips_button := _top_control_button("ADD CHIPS", Vector2(150, 56))
	_add_chips_button = add_chips_button
	add_chips_button.tooltip_text = "Move wallet chips to this table."
	add_chips_button.pressed.connect(_toggle_add_chips_panel)
	_top_right_action_bar.add_child(add_chips_button)

	_build_popover_layer()
	_build_settings_panel()
	_build_dealer_cosmetic_panel()
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
	_popover_layer.z_as_relative = false
	_popover_layer.z_index = POPOVER_LAYER_Z_INDEX
	_popover_layer.visible = true
	_raise_popover_layer()
	for node_name in ["ModalMask", "BlurScrim", "ModalContainer"]:
		var old_node := _popover_layer.get_node_or_null(node_name) as CanvasItem
		if old_node != null:
			old_node.visible = false


func _raise_popover_layer() -> void:
	if _popover_layer == null or _content_root == null:
		return
	if _popover_layer.get_parent() == _content_root:
		_content_root.move_child(_popover_layer, _content_root.get_child_count() - 1)
	_popover_layer.z_as_relative = false
	_popover_layer.z_index = POPOVER_LAYER_Z_INDEX


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


func _build_dealer_cosmetic_panel() -> void:
	_dealer_cosmetic_panel = _popover_layer.get_node_or_null("DealerCosmeticPopover") as PanelContainer
	if _dealer_cosmetic_panel == null:
		_dealer_cosmetic_panel = PanelContainer.new()
		_dealer_cosmetic_panel.add_theme_stylebox_override("panel", _top_settings_panel_style())
		_popover_layer.add_child(_dealer_cosmetic_panel)
	_dealer_cosmetic_panel.name = "DealerCosmeticPopover"
	_prepare_popover_panel(_dealer_cosmetic_panel, Vector2(420, 430))
	_dealer_cosmetic_panel.visible = false
	_refresh_dealer_cosmetic_panel()


func _refresh_dealer_cosmetic_panel() -> void:
	if _dealer_cosmetic_panel == null:
		return
	_clear_children(_dealer_cosmetic_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_dealer_cosmetic_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)
	var title := Label.new()
	title.text = "Choose Dealer"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 1.0))
	title_row.add_child(title)
	var close_button := _top_control_button("X", Vector2(34, 30))
	close_button.pressed.connect(_close_overlay_panels)
	title_row.add_child(close_button)

	var current_id := _selected_dealer_id()
	var current_row := HBoxContainer.new()
	current_row.add_theme_constant_override("separation", 10)
	current_row.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(current_row)

	var current_preview := TextureRect.new()
	current_preview.name = "CurrentDealerPreview"
	current_preview.custom_minimum_size = Vector2(58, 58)
	current_preview.texture = _dealer_texture_for_id(current_id)
	current_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	current_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	current_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	current_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_row.add_child(current_preview)

	var current_label := Label.new()
	current_label.text = "Current Dealer: %s" % _dealer_display_name(current_id)
	current_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_label.add_theme_font_size_override("font_size", 12)
	current_label.add_theme_color_override("font_color", Color(0.78, 0.96, 0.92, 0.92))
	current_row.add_child(current_label)

	var scroll := ScrollContainer.new()
	scroll.name = "DealerImageCardScroll"
	scroll.custom_minimum_size = Vector2(0, 278)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "DealerImageCardGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for dealer_item in DealerLibraryScript.list_dealers():
		var dealer := Dictionary(dealer_item)
		var id_text := String(dealer.get("id", ""))
		var button := _dealer_image_card_button(dealer, id_text == current_id)
		button.pressed.connect(_select_dealer_cosmetic.bind(id_text))
		grid.add_child(button)


func _toggle_dealer_cosmetic_panel() -> void:
	if not _can_change_dealer_cosmetic():
		_append_session_log("Dealer can only be changed in solo/AI tables.")
		return
	if _dealer_cosmetic_panel == null:
		return
	if _settings_panel != null:
		_settings_panel.visible = false
	if _add_chips_panel != null:
		_add_chips_panel.visible = false
	var opening: bool = not _dealer_cosmetic_panel.visible
	_dealer_cosmetic_panel.visible = opening
	if not opening:
		return
	_refresh_dealer_cosmetic_panel()
	_position_popover_near_button(_dealer_cosmetic_panel, _dealer_cosmetic_button)
	_animate_popover(_dealer_cosmetic_panel, Vector2(0.95, 0.95), 0.18)


func _select_dealer_cosmetic(dealer_id: String) -> void:
	if _table_session == null:
		_configure_table_session_from_launch_context()
	if _table_session == null:
		return
	var before_chips := _local_table_chips()
	if not _table_session.select_dealer_cosmetic(dealer_id, _dealer_rule_seats()):
		_append_session_log("Dealer can only be changed in solo/AI tables.")
		return
	_update_launch_context_session()
	_apply_dealer_cosmetic()
	_refresh_dealer_cosmetic_panel()
	if _local_table_chips() != before_chips:
		_append_session_log("Dealer change ignored chip state mismatch.")
		return
	_append_session_log("Dealer changed.")


func _can_change_dealer_cosmetic() -> bool:
	if _table_session == null:
		_configure_table_session_from_launch_context()
	return _table_session != null and _table_session.can_change_dealer_cosmetic(_dealer_rule_seats())


func _dealer_rule_seats() -> Array:
	if _table_flow != null and not _table_flow.seats.is_empty():
		return _table_flow.seats
	return Array(snapshot.get("seats", []))


func _selected_dealer_id() -> String:
	if _table_session == null:
		return TableSessionScript.DEFAULT_DEALER_ID
	return _table_session.selected_dealer_id


func _apply_dealer_cosmetic() -> void:
	var dealer_id := _selected_dealer_id()
	if _croupier_display != null:
		_croupier_display.texture = _dealer_texture_for_id(dealer_id)
	if _dealer_cosmetic_name_label != null:
		_dealer_cosmetic_name_label.text = _dealer_display_name(dealer_id)


func _dealer_texture_for_id(dealer_id: String) -> Texture2D:
	return _load_texture(DealerLibraryScript.texture_path(dealer_id))


func _dealer_display_name(dealer_id: String) -> String:
	return DealerLibraryScript.display_name(dealer_id)


func _dealer_image_card_button(dealer: Dictionary, selected: bool) -> Button:
	var button := Button.new()
	button.name = "DealerCard_%s" % String(dealer.get("id", "dealer"))
	button.custom_minimum_size = Vector2(118, 130)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.tooltip_text = String(dealer.get("display_name", "Dealer"))
	button.add_theme_stylebox_override("normal", _dealer_option_style(selected, false))
	button.add_theme_stylebox_override("hover", _dealer_option_style(selected, true))
	button.add_theme_stylebox_override("pressed", _dealer_option_style(true, true))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	button.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var image := TextureRect.new()
	image.name = "DealerImage"
	image.custom_minimum_size = Vector2(88, 82)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.texture = _load_texture(String(dealer.get("texture_path", "")))
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(image)

	var name_label := Label.new()
	name_label.name = "DealerName"
	name_label.text = String(dealer.get("display_name", "Dealer"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.90, 1.0, 0.94))
	vbox.add_child(name_label)
	return button


func _dealer_option_style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var bg := Color(0.018, 0.022, 0.052, 0.68 if not hovered else 0.88)
	var border := Color(0.62, 0.36, 1.0, 0.52 if not selected else 0.94)
	if selected:
		bg = Color(0.050, 0.040, 0.092, 0.94)
		border = Color(1.0, 0.28, 0.78, 0.95)
	return HomeTheme.make_button_style(bg, border, 8)


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
	_prepare_popover_panel(_add_chips_panel, ADD_CHIPS_POPOVER_SIZE)
	_add_chips_panel.visible = false
	_refresh_add_chips_panel_content()


func _refresh_add_chips_panel_content() -> void:
	if _add_chips_panel == null:
		return

	_clear_children(_add_chips_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_add_chips_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Add Chips to Table"
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

	var explanation := Label.new()
	explanation.text = "Move chips from your wallet to this table.\nThis is not a purchase."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size = Vector2(260, 36)
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explanation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	explanation.add_theme_font_size_override("font_size", 11)
	explanation.add_theme_color_override("font_color", Color(0.78, 0.96, 0.92, 0.86))
	vbox.add_child(explanation)

	var wallet_chips: int = PlayerProfileScript.get_total_chips(ProfileServiceScript.new().get_current_profile())
	var wallet_label := Label.new()
	wallet_label.text = "Wallet Chips: %s" % _format_chips(wallet_chips)
	wallet_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_label.add_theme_font_size_override("font_size", 12)
	wallet_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.45, 0.94))
	vbox.add_child(wallet_label)
	var button_grid := GridContainer.new()
	button_grid.columns = 2
	button_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	button_grid.add_theme_constant_override("h_separation", 10)
	button_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(button_grid)
	for option_item in [1000, 5000, 10000]:
		var amount: int = int(option_item)
		var button := _add_chips_option_button("+%s" % _format_chips(amount))
		button.disabled = amount <= 0 or wallet_chips < amount
		button.tooltip_text = "Move wallet chips to this table."
		var captured_amount: int = amount
		button.pressed.connect(_add_chips_from_wallet.bind(captured_amount))
		button_grid.add_child(button)
	var max_button := _add_chips_option_button("MAX")
	max_button.disabled = wallet_chips <= 0
	max_button.tooltip_text = "Move all available wallet chips to this table."
	max_button.pressed.connect(_add_chips_from_wallet.bind(wallet_chips))
	button_grid.add_child(max_button)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(260, 28)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.72, 0.94, 0.88, 0.88))
	hint.text = "Not enough wallet chips. Visit Store from Home." if wallet_chips <= 0 else "Need more chips? Return Home and visit Store."
	vbox.add_child(hint)
	_prepare_popover_panel(_add_chips_panel, ADD_CHIPS_POPOVER_SIZE)


func _add_chips_option_button(text_value: String) -> Button:
	var button := _top_control_button(text_value, Vector2(126, 44))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _top_control_style(false, "+"))
	button.add_theme_stylebox_override("hover", _top_control_style(true, "+"))
	button.add_theme_stylebox_override("pressed", _top_control_style(true, "+"))
	button.add_theme_stylebox_override("disabled", _top_control_style(false, "+").duplicate())
	button.add_theme_color_override("font_disabled_color", Color(0.60, 0.76, 0.70, 0.62))
	return button


func _add_chips_from_wallet(amount: int) -> void:
	if server_authoritative:
		if _poker_ws_client == null or not _server_connected:
			_on_server_error("Cannot add chips: authoritative server is not connected.")
			return
		if amount <= 0:
			_on_server_error("invalid_amount")
			return
		_append_session_log("Requesting server add chips: %s" % _format_chips(amount))
		_send_server_message(_poker_ws_client.add_table_chips(amount), "add_table_chips %s" % _format_chips(amount))
		if _add_chips_panel != null:
			_add_chips_panel.visible = false
		return
	var result: Dictionary = ProfileServiceScript.new().transfer_chips_to_table(amount)
	if not bool(result.get("success", false)):
		_append_session_log("Not enough wallet chips. Visit Store from Home.")
		_refresh_add_chips_panel_content()
		return
	var added: int = int(result.get("amount", 0))
	var profile: Dictionary = Dictionary(result.get("profile", {}))
	TableLaunchContext.set_player_profile(profile)
	var local_seat_updated := false
	for i in range(_table_flow.seats.size()):
		var seat: Dictionary = Dictionary(_table_flow.seats[i]).duplicate(true)
		if not bool(seat.get("is_local", false)):
			continue
		seat["chips"] = int(seat.get("chips", 0)) + added
		_table_flow.seats[i] = seat
		local_seat_updated = true
		break
	if _table_session != null:
		_table_session.current_table_chips = _local_table_chips() if local_seat_updated else _table_session.current_table_chips + added
		_table_session.session_end_chips = _table_session.current_table_chips
		_table_session.session_profit = _table_session.session_end_chips - _table_session.session_start_chips
		_update_launch_context_session()
	_append_session_log("%s added %s chips from wallet." % [PlayerProfileScript.get_player_name(profile), _format_chips(added)])
	snapshot = _table_flow_to_ui_snapshot(_table_flow.to_snapshot())
	_apply_launch_context(snapshot)
	_refresh()
	call_deferred("_refresh_add_chips_panel_after_transfer")


func _refresh_add_chips_panel_after_transfer() -> void:
	_refresh_add_chips_panel_content()
	if _add_chips_panel != null and _add_chips_button != null:
		_add_chips_panel.visible = true
		_position_popover_near_button(_add_chips_panel, _add_chips_button)


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
	if _dealer_cosmetic_panel != null:
		_dealer_cosmetic_panel.visible = false
		_dealer_cosmetic_panel.scale = Vector2.ONE


func _prepare_popover_panel(panel: Control, panel_size: Vector2) -> void:
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = panel_size.x
	panel.offset_bottom = panel_size.y
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.pivot_offset = panel_size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_as_relative = false
	panel.z_index = POPOVER_LAYER_Z_INDEX + 1
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _position_popover_near_button(popover: Control, anchor_button: Control) -> void:
	if popover == null or anchor_button == null:
		return
	var button_rect: Rect2 = anchor_button.get_global_rect()
	var viewport_size: Vector2 = get_viewport_rect().size
	var popover_size: Vector2 = popover.custom_minimum_size
	if popover_size.x <= 0.0 or popover_size.y <= 0.0:
		popover_size = ADD_CHIPS_POPOVER_SIZE
	popover.size = popover_size
	popover.offset_right = popover.offset_left + popover_size.x
	popover.offset_bottom = popover.offset_top + popover_size.y
	var target: Vector2 = Vector2(
		button_rect.position.x + button_rect.size.x - popover_size.x,
		button_rect.position.y + button_rect.size.y + 10.0
	)
	target.x = clamp(target.x, 16.0, viewport_size.x - popover_size.x - 16.0)
	target.y = clamp(target.y, 16.0, viewport_size.y - popover_size.y - 16.0)
	var local_target := target
	var parent_control := popover.get_parent() as Control
	if parent_control != null:
		local_target = parent_control.get_global_transform().affine_inverse() * target
	popover.anchor_left = 0.0
	popover.anchor_top = 0.0
	popover.anchor_right = 0.0
	popover.anchor_bottom = 0.0
	popover.offset_left = local_target.x
	popover.offset_top = local_target.y
	popover.offset_right = local_target.x + popover_size.x
	popover.offset_bottom = local_target.y + popover_size.y
	popover.size = popover_size


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
	if _dealer_cosmetic_panel != null:
		_dealer_cosmetic_panel.visible = false
	_raise_popover_layer()
	_add_chips_panel.move_to_front()
	_add_chips_panel.visible = opening
	if opening:
		_refresh_add_chips_panel_content()
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
