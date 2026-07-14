extends Control
class_name HomeLobbyScreen

enum LobbyState {
	COLLAPSED,
	PLAY_EXPANDED,
	REPLAY,
	STORE,
	PROFILE,
	SETTINGS,
	ROOM_BROWSER,
	FRIENDS_ROOM,
	EVENTS
}

@export var background_motion_enabled := true

const BACKGROUND_TEXTURE_PATH := "res://assets/home_lobby/backgrounds/home_background_v1.png"
const NEON_SWEEP_SHADER_PATH := "res://shaders/neon_sweep.gdshader"
const NAV_WIDTH := 280.0
const MAIN_LEFT := 360.0
const MAIN_RIGHT := 70.0
const ROOM_BROWSER_COL_WIDTHS := [320, 200, 200, 260, 160]
const DEFAULT_ACTION_TIME_SECONDS := 60
const DEFAULT_QUICK_PUBLIC_TABLE_CONFIG := {
	"buy_in": 2000,
	"small_blind": 25,
	"big_blind": 50,
	"max_hands": 10,
	"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
	"max_players": 9,
}
const CHIP_BUY_IN_OPTIONS := [1000, 2000, 5000, 10000, 20000, 50000]
const CHIP_BLIND_OPTIONS := [[25, 50], [50, 100], [100, 200]]
const GEM_BUY_IN_OPTIONS := [20, 50, 100, 200]
const GEM_BLIND_OPTIONS := [[1, 2], [2, 5], [5, 10]]

var current_state: LobbyState = LobbyState.COLLAPSED
var _background_root: Control
var _background_texture: TextureRect
var _lobby_ui_root: Control
var _left_nav: LeftNavRail
var _top_bar: TopBar
var _center_brand: Control
var _logo_fallback: Control
var _prompt: Label
var _play_panel: PanelContainer
var _room_browser_panel: PanelContainer
var _friends_room_panel: PanelContainer
var _events_panel: PanelContainer
var _replay_panel: PanelContainer
var _replay_fullscreen_overlay: Control
var _replay_fullscreen_timeline_panel: PanelContainer
var _replay_fullscreen_timeline_visible := true
var _replay_timeline_toggle_button: Button
var _replay_content_hbox: HBoxContainer
var _replay_list_panel: PanelContainer
var _replay_equity_box: PanelContainer
var _replay_detail_vbox: VBoxContainer
var _replay_list_lock_labels: Dictionary = {}
var _replay_current_record: Dictionary = {}
var _replay_current_index_entry: Dictionary = {}
var _replay_economy_signature := \
var _pending_replay_unlock_record: Dictionary = {}
var _pending_replay_unlock_index_entry: Dictionary = {}
var _replay_playback_timer: Timer
var _replay_playback_record: Dictionary = {}
var _replay_playback_index_entry: Dictionary = {}
var _replay_playback_actions: Array = []
var _replay_playback_steps: Array = []
var _replay_playback_step := 0
var _replay_playback_speed := 1.0
var _replay_playback_is_playing := false
var _replay_playback_players_vbox: VBoxContainer
var _replay_playback_table_layer: Control
var _replay_playback_board_label: Label
var _replay_playback_pot_label: Label
var _replay_playback_action_label: Label
var _replay_playback_result_vbox: VBoxContainer
var _replay_playback_timeline_vbox: VBoxContainer
var _replay_playback_step_label: Label
var _replay_playback_play_button: Button
var _replay_playback_speed_button: Button
var _replay_poker_table_screen: Control
var _store_panel: PanelContainer
var _profile_panel: PanelContainer
var _settings_panel: PanelContainer
var _social_panel: PanelContainer
var _help_panel: PanelContainer
var _welcome_pack: PanelContainer
var _daily_bonus: Control
var _mode_cards: Array[ModeCard] = []
var _foreground_decor: TextureRect
var _expanded := false
var _bg_breath_tween: Tween
var _fade_overlay: ColorRect
var _launch_transition_label: Label
var _launch_transition_tween: Tween
var _is_launching_table := false

const MockDataProvider := preload("res://scripts/demo/mock_data_provider.gd")
const ScreenNavigator := preload("res://scripts/app/screen_navigator.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")
const ProfileServiceScript := preload(\
const MusicServiceScript := preload("res://scripts/services/music_service.gd")
const SfxManagerScript := preload("res://scripts/services/sfx_manager.gd")
const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const StoreMockServiceScript := preload("res://scripts/services/store_mock_service.gd")
const ReplayServiceScript := preload("res://scripts/services/replay_service.gd")
const ReplayRepositoryScript := preload("res://scripts/replay/replay_repository.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")
const DealerLibraryScript := preload("res://scripts/data/dealer_library.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")
const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")
const PokerWsClientScript := preload("res://scripts/network/poker_ws_client.gd")
const NetworkConfigScript := preload("res://scripts/network/network_config.gd")
const ReplayCardViewScene := preload("res://scenes/components/card_view.tscn")
const ReplayPokerTableScreenScene := preload("res://scenes/screens/replay_poker_table_screen.tscn")
const REPLAY_TABLE_BACKGROUND := preload("res://assets/poker_table/backgrounds/table_neon_v1.png")
const REPLAY_CHIP_STACK := preload("res://assets/ui/neon_poker_ui_clean/chip_stack.png")
const REPLAY_AVATAR_RING := preload("res://assets/ui/neon_poker_ui_clean/avatar_ring.png")
const REPLAY_ACTIVE_TURN_GLOW := preload("res://assets/ui/neon_poker_ui_clean/active_turn_glow.png")
const MODE_IMAGES := {
	"quick_play": "res://assets/home_lobby/mode_cards/mode_quick_play.png",
	"room_browser": "res://assets/home_lobby/mode_cards/mode_cash_tables.png",
	"private_table": "res://assets/home_lobby/mode_cards/mode_private_table.png",
	"training": "res://assets/home_lobby/mode_cards/mode_club_games.png",
	"events": "res://assets/home_lobby/mode_cards/mode_tournaments.png"
}

const LOGO_COLLAPSED_Y := 275.0
const LOGO_EXPANDED_Y := 20.0
const LOGO_COLLAPSED_SCALE := Vector2(1.0, 1.0)
const LOGO_EXPANDED_SCALE := Vector2(0.58, 0.58)
const REPLAY_TABLE_DESIGN_SIZE := Vector2(2560.0, 900.0)
const REPLAY_TABLE_VIEW_SIZE := Vector2(960.0, 470.0)
const REPLAY_SEAT_CARD_SIZE := Vector2(132.0, 74.0)
const REPLAY_BET_MARKER_SIZE := Vector2(78.0, 24.0)
const REPLAY_SEAT_PANEL_ORIGINS_BY_SEAT := {
	1: Vector2(1580.0, 190.0),
	2: Vector2(1880.0, 300.0),
	3: Vector2(2030.0, 520.0),
	4: Vector2(1760.0, 700.0),
	5: Vector2(1180.0, 710.0),
	6: Vector2(720.0, 700.0),
	7: Vector2(410.0, 520.0),
	8: Vector2(560.0, 300.0),
	9: Vector2(900.0, 190.0),
}
const REPLAY_BET_MARKER_ANCHORS_BY_SEAT := {
	1: Vector2(1540.0, 322.0),
	2: Vector2(1660.0, 392.0),
	3: Vector2(1650.0, 535.0),
	4: Vector2(1540.0, 610.0),
	5: Vector2(1210.0, 590.0),
	6: Vector2(890.0, 610.0),
	7: Vector2(850.0, 535.0),
	8: Vector2(900.0, 392.0),
	9: Vector2(1015.0, 322.0),
}

var _cta_button: Button
var _cta_float_time := 0.0
var _cta_hover_tween: Tween
var _toast_label: Label
var _toast_tween: Tween
var _player_profile: Dictionary = {}
var _local_backend: LocalMockBackend
var _settings_service: SettingsService
var _friends_room_context: Dictionary = {}
var _friends_room_id_label: Label
var _friends_room_seats_label: Label
var _friends_room_ready_label: Label
var _friends_room_code_input: LineEdit
var _room_browser_list_vbox: VBoxContainer
var _profile_avatar_rect: TextureRect
var _profile_name_label: Label
var _profile_level_label: Label
var _profile_avatar_name_label: Label
var _profile_stats_labels: Dictionary = {}
var _profile_avatar_grid: GridContainer
var _profile_avatar_buttons: Dictionary = {}
var _quick_play_setup_panel: PanelContainer
var _quick_play_setup_avatar: TextureRect
var _quick_play_setup_name_label: Label
var _quick_play_setup_chips_label: Label
var _quick_play_setup_hint_label: Label
var _quick_mode_buttons: Dictionary = {}
var _quick_chip_settings_container: VBoxContainer
var _quick_gem_placeholder_container: VBoxContainer
var _quick_start_button: Button
var _quick_buy_in_buttons: Dictionary = {}
var _quick_blinds_buttons: Dictionary = {}
var _quick_hand_count_buttons: Dictionary = {}
var _quick_gem_buy_in_buttons: Dictionary = {}
var _quick_gem_blinds_buttons: Dictionary = {}
var _quick_gem_hand_count_buttons: Dictionary = {}
var _quick_play_mode := "chip"
var _selected_quick_buy_in := 2000
var _selected_quick_small_blind := 25
var _selected_quick_big_blind := 50
var _selected_quick_max_hands := 10
var _public_table_setup_panel: PanelContainer
var _private_room_setup_panel: PanelContainer
var _public_table_setup_values := {
	"buy_in": 2000,
	"small_blind": 25,
	"big_blind": 50,
	"max_hands": 10,
	"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
	"max_players": 6,
}
var _private_room_setup_values := {
	"buy_in": 2000,
	"small_blind": 25,
	"big_blind": 50,
	"max_hands": 10,
	"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
	"max_players": 6,
}
var _public_table_setup_mode := "chip"
var _private_room_setup_mode := "chip"
var server_authoritative_profile := true
var _profile_ws_client: PokerWsClient
var _profile_server_connected := false
var _profile_server_wallet_synced := false
var _welcome_shown_for_player_id := ""
var _avatar_catalog: Array = []
var _avatar_catalog_by_id: Dictionary = {}
var _server_public_tables: Array = []

func _ready() -> void:
	# Force standalone windowed mode to bypass Godot editor stretch bugs
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_local_backend = LocalMockBackendScript.new()
	_settings_service = SettingsServiceScript.new()
	LocalizationManagerScript.load_saved_locale(_settings_service.load_settings())
	_build_background()
	_build_foreground()
	_build_layout()
	_build_play_panel()
	_build_room_browser_panel()
	_build_friends_room_panel()
	_build_events_panel()
	_build_replay_panel()
	_build_store_panel()
	_build_profile_panel()
	_build_settings_panel()
	_build_social_panel()
	_build_help_panel()
	_build_quick_play_setup_panel()
	_build_table_creation_setup_panels()
	
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "FadeOverlay"
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.visible = false
	add_child(_fade_overlay)

	_launch_transition_label = Label.new()
	_launch_transition_label.name = "EnteringTableLabel"
	_launch_transition_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_launch_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_launch_transition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_launch_transition_label.visible = false
	_launch_transition_label.add_theme_font_size_override("font_size", 24)
	_launch_transition_label.add_theme_color_override("font_color", Color(0.96, 0.92, 1.0, 0.96))
	_fade_overlay.add_child(_launch_transition_label)

	MusicServiceScript.play_home_bgm(self)
	_apply_settings(_settings_service.load_settings())
	call_deferred("_ensure_home_bgm_active")
	
	var lobby_vm := MockDataProvider.get_lobby_view_model()
	_player_profile = ProfileServiceScript.new().get_current_profile()
	if server_authoritative_profile:
		_connect_profile_server()
	lobby_vm["player"] = _player_profile
	_top_bar.configure(_player_profile)
	_refresh_daily_bonus_bar()
	set_state(LobbyState.COLLAPSED, false)
	call_deferred("_show_pending_launch_error")
	_handle_runtime_capture_args()

func set_state(new_state: LobbyState, animated: bool = true) -> void:
	current_state = new_state
	_ensure_home_bgm_active()
	if _quick_play_setup_panel != null and new_state != LobbyState.PLAY_EXPANDED:
		_quick_play_setup_panel.visible = false
	if new_state == LobbyState.PROFILE:
		_reload_player_profile()
	if new_state == LobbyState.ROOM_BROWSER:
		_request_server_table_list()
	
	var nav_id := "home"
	match current_state:
		LobbyState.COLLAPSED: nav_id = "home"
		LobbyState.PLAY_EXPANDED, LobbyState.ROOM_BROWSER, LobbyState.FRIENDS_ROOM, LobbyState.EVENTS: nav_id = "play"
		LobbyState.REPLAY: nav_id = "replay"
		LobbyState.STORE: nav_id = "store"
		LobbyState.PROFILE: nav_id = "profile"
		LobbyState.SETTINGS: nav_id = "settings"
	
	if _left_nav:
		_left_nav.set_active(nav_id)
		
	_set_expanded(current_state != LobbyState.COLLAPSED, not animated)

func _ensure_home_bgm_active() -> void:
	if _replay_fullscreen_overlay != null and _replay_fullscreen_overlay.visible:
		return
	MusicServiceScript.ensure_home_bgm(self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.alt_pressed and event.keycode == KEY_ENTER:
			_toggle_window_mode()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if current_state != LobbyState.COLLAPSED:
			set_state(LobbyState.COLLAPSED)
		else:
			get_tree().quit()
		get_viewport().set_input_as_handled()

func _build_background() -> void:
	_background_root = Control.new()
	_background_root.name = "BackgroundRoot"
	_background_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background_root)
	_background_texture = TextureRect.new()
	_background_texture.name = "BackgroundTexture"
	_background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_texture.texture = load(BACKGROUND_TEXTURE_PATH)
	_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_texture.modulate = Color(1.34, 1.30, 1.40, 1.0)
	_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_root.add_child(_background_texture)
	
	# Flowing Fog Shader Layer
	var flow_rect := ColorRect.new()
	flow_rect.name = "BackgroundShaderFlow"
	flow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flow_mat := ShaderMaterial.new()
	flow_mat.shader = load("res://shaders/flow_noise_bg.gdshader")
	flow_mat.set_shader_parameter("deep_color", Color(0, 0, 0, 0)) # transparent base
	flow_mat.set_shader_parameter("haze_color", Color(0.35, 0.15, 0.55, 0.50)) # purple smoke
	flow_mat.set_shader_parameter("neon_color", Color(0.82, 0.22, 0.68, 0.45)) # pink smoke
	flow_mat.set_shader_parameter("speed", 0.003) # extremely slow motion
	flow_mat.set_shader_parameter("intensity", 0.25)
	flow_mat.set_shader_parameter("layer_alpha", 0.18) # prominent neon smoke overlay
	flow_mat.set_shader_parameter("motion_enabled", true)
	flow_rect.material = flow_mat
	_background_root.add_child(flow_rect)
	
	var center_lift := ColorRect.new()
	center_lift.name = "BackgroundCenterLift"
	center_lift.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_lift.color = Color(0.06, 0.08, 0.18, 0.08)
	center_lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_root.add_child(center_lift)
	
	_build_particles()

func _build_layout() -> void:
	_lobby_ui_root = Control.new()
	_lobby_ui_root.name = "LobbyUIRoot"
	_lobby_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lobby_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lobby_ui_root)

	_left_nav = preload("res://scenes/components/left_nav_rail.tscn").instantiate() as LeftNavRail
	_left_nav.name = "LeftNavRail"
	_left_nav.anchor_left = 0.0
	_left_nav.anchor_right = 0.0
	_left_nav.anchor_top = 0.0
	_left_nav.anchor_bottom = 1.0
	_left_nav.offset_left = 0.0
	_left_nav.offset_right = NAV_WIDTH
	_left_nav.offset_top = 0.0
	_left_nav.offset_bottom = 0.0
	_left_nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_nav.nav_selected.connect(_on_nav_selected)
	_left_nav.play_submenu_selected.connect(_on_play_submenu_selected)
	_lobby_ui_root.add_child(_left_nav)

	_top_bar = preload("res://scenes/components/top_bar.tscn").instantiate() as TopBar
	_top_bar.name = "TopBar"
	_top_bar.anchor_left = 0.0
	_top_bar.anchor_right = 1.0
	_top_bar.offset_left = 320
	_top_bar.offset_right = -24
	_top_bar.offset_top = 18
	_top_bar.offset_bottom = 82
	_top_bar.social_requested.connect(_show_social_panel)
	_top_bar.help_requested.connect(_show_help_panel)
	_top_bar.exit_requested.connect(_quit_game)
	_lobby_ui_root.add_child(_top_bar)

	_build_center_brand()

	_prompt = Label.new()
	_prompt.name = "CollapsedPrompt"
	_prompt.text = _t("home.prompt")
	_prompt.anchor_left = 0.5
	_prompt.anchor_top = 1.0
	_prompt.anchor_right = 0.5
	_prompt.anchor_bottom = 1.0
	_prompt.offset_left = -220
	_prompt.offset_top = -72
	_prompt.offset_right = 220
	_prompt.offset_bottom = -40
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeTheme.make_font_settings(_prompt, 14, Color(0.86, 0.90, 1.0, 0.86))
	_lobby_ui_root.add_child(_prompt)
	_build_cta_button()
	_build_toast()

func _build_center_brand() -> void:
	_center_brand = Control.new()
	_center_brand.name = "CenterBrand"
	_center_brand.anchor_left = 0.5
	_center_brand.anchor_top = 0.5
	_center_brand.anchor_right = 0.5
	_center_brand.anchor_bottom = 0.5
	_center_brand.offset_left = -470
	_center_brand.offset_top = -265
	_center_brand.offset_right = 470
	_center_brand.offset_bottom = 185
	_center_brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_brand.pivot_offset = Vector2(470, 225)
	_lobby_ui_root.add_child(_center_brand)

	_logo_fallback = Control.new()
	_logo_fallback.name = "LogoTextFallback"
	_logo_fallback.anchor_left = 0.0
	_logo_fallback.anchor_top = 0.0
	_logo_fallback.anchor_right = 1.0
	_logo_fallback.anchor_bottom = 1.0
	_logo_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_fallback.visible = true
	_center_brand.add_child(_logo_fallback)
	var logo_main := _make_logo_label("LogoMain", "TEXAS\nHOLD'EM", 116, Color(0.886, 0.910, 0.941, 1.0), 4, Color(0.616, 0.306, 0.867, 1.0), Color(1.0, 0.0, 0.498, 0.333), Vector2(0, 4), 12, 0.08, 0.78)
	var sweep_mat := ShaderMaterial.new()
	sweep_mat.shader = load(NEON_SWEEP_SHADER_PATH)
	logo_main.material = sweep_mat
	_logo_fallback.add_child(logo_main)
	
	var logo_sub := _make_logo_label("LogoSub", "POKER CLUB", 22, Color(0.886, 0.910, 0.941, 1.0), 2, Color(0.616, 0.306, 0.867, 1.0), Color(1.0, 0.0, 0.498, 0.333), Vector2(0, 3), 6, 0.70, 0.86)
	_logo_fallback.add_child(logo_sub)

func _make_logo_label(label_name: String, text: String, font_size: int, color: Color, outline_size: int, outline_color: Color, shadow_color: Color, shadow_offset: Vector2, shadow_outline: int, anchor_top: float, anchor_bottom: float) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.anchor_left = 0.0
	label.anchor_top = anchor_top
	label.anchor_right = 1.0
	label.anchor_bottom = anchor_bottom
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline_size > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline_size)
	if shadow_color.a > 0.0:
		label.add_theme_color_override("font_shadow_color", shadow_color)
		label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
		label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
		label.add_theme_constant_override("shadow_outline_size", shadow_outline)
	return label

func _build_play_panel() -> void:
	_play_panel = PanelContainer.new()
	_play_panel.name = "PlayExpandedGroup"
	_play_panel.anchor_left = 0.0
	_play_panel.anchor_top = 0.32
	_play_panel.anchor_right = 1.0
	_play_panel.anchor_bottom = 0.91
	_play_panel.offset_left = MAIN_LEFT
	_play_panel.offset_right = -MAIN_RIGHT
	_play_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_panel.custom_minimum_size = Vector2(0, 580)
	_play_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.016, 0.0), Color(0.2, 0.28, 0.6, 0.0), 8, 0))
	_lobby_ui_root.add_child(_play_panel)
	
	var content := VBoxContainer.new()
	content.name = "ContentColumn"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.custom_minimum_size = Vector2(1320, 0)
	content.add_theme_constant_override("separation", 22)
	_play_panel.add_child(content)
	
	var title := Label.new()
	title.name = "ChooseRoomTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = _t("home.choose_room")
	HomeTheme.make_font_settings(title, 20, Color(0.9, 0.92, 1.0, 0.9))
	content.add_child(title)

	var card_row := HBoxContainer.new()
	card_row.name = "ModeCardRow"
	card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_row.custom_minimum_size = Vector2(1, 370)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 30)
	content.add_child(card_row)
	var lobby_vm := MockDataProvider.get_lobby_view_model()
	for mode_data in lobby_vm["modes"]:
		var card := preload("res://scenes/components/mode_card.tscn").instantiate() as ModeCard
		var data_with_img := Dictionary(mode_data).duplicate()
		data_with_img["image"] = MODE_IMAGES.get(data_with_img["id"], "")
		data_with_img["title"] = _t("mode.%s.title" % str(data_with_img["id"]))
		data_with_img["subtitle"] = _t("mode.%s.subtitle" % str(data_with_img["id"]))
		card.configure(data_with_img)
		card.mode_selected.connect(_on_mode_selected)
		_mode_cards.append(card)
		card_row.add_child(card)

	_daily_bonus = preload("res://scenes/components/daily_bonus_bar.tscn").instantiate()
	_daily_bonus.name = "DailyBonusBar"
	_daily_bonus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_daily_bonus)
	if _daily_bonus.has_signal("claim_pressed"):
		_daily_bonus.connect("claim_pressed", Callable(self, "_on_daily_bonus_claim_pressed"))


func _build_quick_play_setup_panel() -> void:
	_quick_play_setup_panel = PanelContainer.new()
	_quick_play_setup_panel.name = "QuickPlaySetupPanel"
	_quick_play_setup_panel.anchor_left = 0.5
	_quick_play_setup_panel.anchor_top = 0.5
	_quick_play_setup_panel.anchor_right = 0.5
	_quick_play_setup_panel.anchor_bottom = 0.5
	_quick_play_setup_panel.offset_left = -360
	_quick_play_setup_panel.offset_top = -292
	_quick_play_setup_panel.offset_right = 360
	_quick_play_setup_panel.offset_bottom = 292
	_quick_play_setup_panel.z_index = 60
	_quick_play_setup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_quick_play_setup_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.018, 0.92), Color(1.0, 0.0, 0.5, 0.40), 12, 1))
	_quick_play_setup_panel.visible = false
	_lobby_ui_root.add_child(_quick_play_setup_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_quick_play_setup_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = _t("mode.quick_play.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(title, 28, HomeTheme.TEXT)
	column.add_child(title)

	_build_quick_mode_switch(column)

	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 14)
	profile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(profile_row)

	var avatar_frame := PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(78, 78)
	avatar_frame.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.010, 0.024, 0.92), Color(0.82, 0.78, 1.0, 0.65), 39, 1))
	profile_row.add_child(avatar_frame)
	_quick_play_setup_avatar = TextureRect.new()
	_quick_play_setup_avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quick_play_setup_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_quick_play_setup_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_quick_play_setup_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_quick_play_setup_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_frame.add_child(_quick_play_setup_avatar)

	var profile_text := VBoxContainer.new()
	profile_text.add_theme_constant_override("separation", 5)
	profile_row.add_child(profile_text)
	_quick_play_setup_name_label = Label.new()
	HomeTheme.make_font_settings(_quick_play_setup_name_label, 19, HomeTheme.TEXT)
	profile_text.add_child(_quick_play_setup_name_label)
	_quick_play_setup_chips_label = Label.new()
	HomeTheme.make_font_settings(_quick_play_setup_chips_label, 15, HomeTheme.GOLD)
	profile_text.add_child(_quick_play_setup_chips_label)

	_quick_play_setup_hint_label = Label.new()
	_quick_play_setup_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quick_play_setup_hint_label.custom_minimum_size = Vector2(420, 0)
	_quick_play_setup_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(_quick_play_setup_hint_label, 13, HomeTheme.MUTED)
	column.add_child(_quick_play_setup_hint_label)

	_quick_chip_settings_container = VBoxContainer.new()
	_quick_chip_settings_container.add_theme_constant_override("separation", 12)
	column.add_child(_quick_chip_settings_container)
	var chip_mode_note := Label.new()
	chip_mode_note.text = _t("quick.copy_chip")
	chip_mode_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chip_mode_note.custom_minimum_size = Vector2(520, 0)
	HomeTheme.make_font_settings(chip_mode_note, 13, HomeTheme.MUTED)
	_quick_chip_settings_container.add_child(chip_mode_note)
	_build_quick_setup_section(_quick_chip_settings_container, "buy_in", _t("common.buy_in").to_upper(), _quick_buy_in_buttons, CHIP_BUY_IN_OPTIONS, _select_quick_buy_in)
	_build_quick_blinds_section(_quick_chip_settings_container, CHIP_BLIND_OPTIONS, _quick_blinds_buttons)
	_build_quick_setup_section(_quick_chip_settings_container, "hand_count", _t("common.hand_count").to_upper(), _quick_hand_count_buttons, [5, 10, 20, 999], _select_quick_hand_count)

	_build_quick_gem_settings(column)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	column.add_child(button_row)

	var start_button := Button.new()
	_quick_start_button = start_button
	start_button.text = _t("common.find_table").to_upper()
	start_button.custom_minimum_size = Vector2(180, 48)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_button.add_theme_font_size_override("font_size", 15)
	start_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.68), Color(1.0, 0.0, 0.5, 0.85), 22))
	start_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.86), Color(1.0, 0.0, 0.5, 1.0), 22))
	start_button.pressed.connect(_start_quick_play_from_setup)
	button_row.add_child(start_button)

	var cancel_button := Button.new()
	cancel_button.text = _t("common.cancel").to_upper()
	cancel_button.custom_minimum_size = Vector2(140, 48)
	cancel_button.focus_mode = Control.FOCUS_NONE
	cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel_button.add_theme_font_size_override("font_size", 14)
	cancel_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.58), Color(0.36, 0.42, 0.7, 0.28), 22))
	cancel_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.035, 0.04, 0.085, 0.82), Color(0.78, 0.58, 1.0, 0.55), 22))
	cancel_button.pressed.connect(_hide_quick_play_setup)
	button_row.add_child(cancel_button)


func _build_quick_mode_switch(parent: VBoxContainer) -> void:
	var switch_row := HBoxContainer.new()
	switch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	switch_row.add_theme_constant_override("separation", 8)
	parent.add_child(switch_row)

	_add_quick_mode_button(switch_row, "chip", _t("mode.chip_table").to_upper())
	_add_quick_mode_button(switch_row, "gem", _t("mode.gem_match").to_upper())


func _add_quick_mode_button(parent: HBoxContainer, mode: String, label: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(150, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(func() -> void: _select_quick_play_mode(mode))
	_quick_mode_buttons[mode] = button
	parent.add_child(button)


func _build_quick_gem_settings(parent: VBoxContainer) -> void:
	_quick_gem_placeholder_container = VBoxContainer.new()
	_quick_gem_placeholder_container.visible = false
	_quick_gem_placeholder_container.add_theme_constant_override("separation", 12)
	parent.add_child(_quick_gem_placeholder_container)

	var detail_label := Label.new()
	detail_label.text = _t("quick.copy_gem")
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(520, 0)
	HomeTheme.make_font_settings(detail_label, 13, HomeTheme.MUTED)
	_quick_gem_placeholder_container.add_child(detail_label)
	_build_quick_setup_section(_quick_gem_placeholder_container, "buy_in", _t("common.buy_in").to_upper(), _quick_gem_buy_in_buttons, GEM_BUY_IN_OPTIONS, _select_quick_buy_in)
	_build_quick_blinds_section(_quick_gem_placeholder_container, GEM_BLIND_OPTIONS, _quick_gem_blinds_buttons)
	_build_quick_setup_section(_quick_gem_placeholder_container, "hand_count", _t("common.hand_count").to_upper(), _quick_gem_hand_count_buttons, [5, 10, 20, 999], _select_quick_hand_count)


func _build_table_creation_setup_panels() -> void:
	_public_table_setup_panel = _create_table_setup_panel("PublicTableSetupPanel")
	_private_room_setup_panel = _create_table_setup_panel("PrivateRoomSetupPanel")


func _create_table_setup_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -360
	panel.offset_top = -292
	panel.offset_right = 360
	panel.offset_bottom = 292
	panel.z_index = 62
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.018, 0.94), Color(0.9, 0.26, 1.0, 0.45), 12, 1))
	_lobby_ui_root.add_child(panel)
	return panel


func _show_public_table_setup() -> void:
	_public_table_setup_mode = "chip"
	_render_table_creation_setup_panel(_public_table_setup_panel, true)
	_show_table_creation_setup_panel(_public_table_setup_panel)


func _show_private_room_setup() -> void:
	_private_room_setup_mode = "chip"
	_render_table_creation_setup_panel(_private_room_setup_panel, false)
	_show_table_creation_setup_panel(_private_room_setup_panel)


func _show_table_creation_setup_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	if _public_table_setup_panel != null and _public_table_setup_panel != panel:
		_public_table_setup_panel.visible = false
	if _private_room_setup_panel != null and _private_room_setup_panel != panel:
		_private_room_setup_panel.visible = false
	panel.visible = true
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hide_table_creation_setup_panels() -> void:
	if _public_table_setup_panel != null:
		_public_table_setup_panel.visible = false
	if _private_room_setup_panel != null:
		_private_room_setup_panel.visible = false


func _render_table_creation_setup_panel(panel: PanelContainer, public_table: bool) -> void:
	if panel == null:
		return
	_clear_node_children(panel)
	var values: Dictionary = _public_table_setup_values if public_table else _private_room_setup_values
	var selected_mode: String = _public_table_setup_mode if public_table else _private_room_setup_mode
	var gem_selected: bool = selected_mode == "gem"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = _t("setup.create_public_table") if public_table else _t("setup.create_private_room")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(title, 28, HomeTheme.TEXT)
	column.add_child(title)

	var selected_currency := "gems" if gem_selected else "chips"
	_add_table_setup_mode_switch(column, public_table, selected_mode)
	_add_table_setup_profile_row(column, selected_currency)

	var mode_note := Label.new()
	var buy_in := int(values.get("buy_in", 2000))
	var wallet_amount := _wallet_amount_for_currency(selected_currency)
	var can_afford_buy_in := (not (public_table and gem_selected)) and _can_afford_buy_in_for_currency(buy_in, selected_currency)
	if public_table:
		if gem_selected:
			mode_note.text = _t("setup.public_gem_quick_note")
		elif not can_afford_buy_in:
			mode_note.text = _tf("table.not_enough_buyin_chips_detail", {"required": _format_number(buy_in), "wallet": _format_number(wallet_amount)})
		else:
			mode_note.text = _t("setup.public_chip_note")
	else:
		if gem_selected:
			mode_note.text = _t("setup.private_gem_note")
		elif not can_afford_buy_in:
			mode_note.text = _tf("table.not_enough_buyin_chips_detail", {"required": _format_number(buy_in), "wallet": _format_number(wallet_amount)})
		else:
			mode_note.text = _t("setup.private_chip_note")
	mode_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_note.custom_minimum_size = Vector2(520, 0)
	HomeTheme.make_font_settings(mode_note, 13, HomeTheme.MUTED)
	column.add_child(mode_note)

	_add_table_setup_option_row(column, values, "buy_in", _t("common.buy_in").to_upper() if public_table else _t("setup.starting_stack_buy_in"), GEM_BUY_IN_OPTIONS if gem_selected else CHIP_BUY_IN_OPTIONS, public_table)
	_add_blinds_setup_option_row(column, values, public_table, GEM_BLIND_OPTIONS if gem_selected else CHIP_BLIND_OPTIONS)
	_add_table_setup_option_row(column, values, "max_hands", _t("common.hand_count").to_upper(), [5, 10, 20, 999], public_table)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)

	var confirm := Button.new()
	confirm.text = _t("common.coming_soon").to_upper() if public_table and gem_selected else (_t("common.create_table").to_upper() if public_table else _t("common.create_room").to_upper())
	confirm.custom_minimum_size = Vector2(180, 48)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.disabled = (public_table and gem_selected) or not can_afford_buy_in
	confirm.mouse_default_cursor_shape = Control.CURSOR_ARROW if confirm.disabled else Control.CURSOR_POINTING_HAND
	confirm.add_theme_font_size_override("font_size", 15)
	confirm.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.68), Color(1.0, 0.0, 0.5, 0.85), 22))
	confirm.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.86), Color(1.0, 0.0, 0.5, 1.0), 22))
	confirm.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(Color(0.08, 0.06, 0.10, 0.62), Color(0.76, 0.52, 0.9, 0.28), 22))
	confirm.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.86, 0.72))
	confirm.pressed.connect(Callable(self, "_confirm_public_table_setup") if public_table else Callable(self, "_confirm_private_room_setup"))
	buttons.add_child(confirm)

	var cancel := Button.new()
	cancel.text = _t("common.cancel").to_upper()
	cancel.custom_minimum_size = Vector2(128, 44)
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.add_theme_font_size_override("font_size", 13)
	cancel.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.58), Color(0.36, 0.42, 0.7, 0.28), 22))
	cancel.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.035, 0.04, 0.085, 0.82), Color(0.78, 0.58, 1.0, 0.55), 22))
	cancel.pressed.connect(_hide_table_creation_setup_panels)
	buttons.add_child(cancel)


func _add_table_setup_mode_switch(parent: VBoxContainer, public_table: bool, selected_mode: String) -> void:
	var switch_row := HBoxContainer.new()
	switch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	switch_row.add_theme_constant_override("separation", 8)
	parent.add_child(switch_row)
	var chip_button: Button = _table_setup_mode_button(_t("mode.chip_table").to_upper(), selected_mode == "chip", false)
	chip_button.pressed.connect(func() -> void:
		if public_table:
			_public_table_setup_mode = "chip"
			_apply_table_setup_mode_defaults(_public_table_setup_values, "chip")
		else:
			_private_room_setup_mode = "chip"
			_apply_table_setup_mode_defaults(_private_room_setup_values, "chip")
		_render_table_creation_setup_panel(_public_table_setup_panel if public_table else _private_room_setup_panel, public_table)
	)
	switch_row.add_child(chip_button)

	var gem_disabled := public_table
	var gem_button: Button = _table_setup_mode_button(_t("mode.gem_match").to_upper() if public_table else _t("mode.gem_room").to_upper(), selected_mode == "gem", gem_disabled)
	gem_button.tooltip_text = _t("setup.public_gem_quick_note") if public_table else _t("setup.private_gem_note")
	gem_button.pressed.connect(func() -> void:
		if public_table:
			_show_toast(_t("setup.public_gem_quick_note"))
			return
		_private_room_setup_mode = "gem"
		_apply_table_setup_mode_defaults(_private_room_setup_values, "gem")
		_render_table_creation_setup_panel(_private_room_setup_panel, false)
	)
	switch_row.add_child(gem_button)

func _apply_table_setup_mode_defaults(values: Dictionary, mode: String) -> void:
	var buy_options: Array = GEM_BUY_IN_OPTIONS if mode == "gem" else CHIP_BUY_IN_OPTIONS
	if not buy_options.has(int(values.get("buy_in", 0))):
		values["buy_in"] = 50 if mode == "gem" else 2000
	var blind_options: Array = GEM_BLIND_OPTIONS if mode == "gem" else CHIP_BLIND_OPTIONS
	var valid_blind := false
	for blind_item in blind_options:
		var pair: Array = Array(blind_item)
		if int(pair[0]) == int(values.get("small_blind", 0)) and int(pair[1]) == int(values.get("big_blind", 0)):
			valid_blind = true
	if not valid_blind:
		values["small_blind"] = 2 if mode == "gem" else 25
		values["big_blind"] = 5 if mode == "gem" else 50


func _add_table_setup_profile_row(parent: VBoxContainer, currency: String = "chips") -> void:
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 14)
	profile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(profile_row)

	var avatar_frame := PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(64, 64)
	avatar_frame.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.010, 0.024, 0.92), Color(0.82, 0.78, 1.0, 0.65), 32, 1))
	profile_row.add_child(avatar_frame)

	var avatar := TextureRect.new()
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = AvatarLibraryScript.get_avatar_by_id(PlayerProfileScript.get_avatar_id(_player_profile))
	if texture == null:
		var avatar_path := str(_player_profile.get("avatar", ""))
		if avatar_path != "" and ResourceLoader.exists(avatar_path):
			texture = load(avatar_path) as Texture2D
	avatar.texture = texture
	avatar.visible = texture != null
	avatar_frame.add_child(avatar)

	var profile_text := VBoxContainer.new()
	profile_text.add_theme_constant_override("separation", 4)
	profile_row.add_child(profile_text)

	var name_label := Label.new()
	name_label.text = PlayerProfileScript.get_player_name(_player_profile)
	HomeTheme.make_font_settings(name_label, 18, HomeTheme.TEXT)
	profile_text.add_child(name_label)

	var chips_label := Label.new()
	chips_label.text = "%s: %s" % [
		(_t("common.server_wallet_currency") if server_authoritative_profile and _profile_server_connected else _t("common.wallet_currency")) % _currency_label(currency),
		_format_number(_wallet_amount_for_currency(currency)),
	]
	HomeTheme.make_font_settings(chips_label, 14, HomeTheme.GOLD)
	profile_text.add_child(chips_label)


func _table_setup_mode_button(label_text: String, selected: bool, disabled: bool) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(150, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	button.disabled = disabled
	button.add_theme_font_size_override("font_size", 12)
	var bg := Color(0.20, 0.06, 0.17, 0.76) if selected else Color(0.018, 0.022, 0.052, 0.64)
	var border := Color(1.0, 0.0, 0.5, 0.95) if selected else Color(0.55, 0.42, 0.95, 0.38)
	if disabled:
		bg = Color(0.012, 0.014, 0.028, 0.46)
		border = Color(0.34, 0.32, 0.48, 0.28)
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(bg, border, 18))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.30, 0.10, 0.25, 0.86), Color(1.0, 0.0, 0.5, 1.0), 18))
	button.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(bg, border, 18))
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.98, 1.0) if selected else Color(0.70, 0.74, 0.92, 0.88))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.68, 0.72))
	return button


func _add_table_setup_option_row(parent: VBoxContainer, values: Dictionary, key: String, label_text: String, options: Array, public_table: bool) -> void:
	var selected_mode: String = _public_table_setup_mode if public_table else _private_room_setup_mode
	var currency := "gems" if selected_mode == "gem" else "chips"
	var label := Label.new()
	label.text = label_text
	HomeTheme.make_font_settings(label, 12, HomeTheme.MUTED)
	parent.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	for option_item in options:
		var option_value: int = int(option_item)
		var button: Button = _table_setup_option_button(_table_setup_option_label(key, option_value), int(values.get(key, 0)) == option_value)
		var disabled := key == "buy_in" and ((public_table and selected_mode == "gem") or not _can_afford_buy_in_for_currency(option_value, currency))
		button.disabled = disabled
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
		if disabled:
			button.tooltip_text = _tf("common.not_enough_currency", {"currency": _currency_label(currency).to_lower()})
			button.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(Color(0.012, 0.014, 0.028, 0.46), Color(0.34, 0.32, 0.48, 0.28), 18))
			button.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.68, 0.72))
		button.pressed.connect(func() -> void:
			if disabled:
				_show_toast(_t("table.not_enough_buyin_gems") if currency == "gems" else _t("table.not_enough_buyin_chips"))
				return
			values[key] = option_value
			_render_table_creation_setup_panel(_public_table_setup_panel if public_table else _private_room_setup_panel, public_table)
		)
		row.add_child(button)


func _add_blinds_setup_option_row(parent: VBoxContainer, values: Dictionary, public_table: bool, blind_pairs: Array = []) -> void:
	var label := Label.new()
	label.text = _t("common.blinds").to_upper()
	HomeTheme.make_font_settings(label, 12, HomeTheme.MUTED)
	parent.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var options := blind_pairs if not blind_pairs.is_empty() else CHIP_BLIND_OPTIONS
	for blind_pair in options:
		var small: int = int(blind_pair[0])
		var big: int = int(blind_pair[1])
		var selected: bool = int(values.get("small_blind", 0)) == small and int(values.get("big_blind", 0)) == big
		var button: Button = _table_setup_option_button("%d / %d" % [small, big], selected)
		button.pressed.connect(func() -> void:
			values["small_blind"] = small
			values["big_blind"] = big
			_render_table_creation_setup_panel(_public_table_setup_panel if public_table else _private_room_setup_panel, public_table)
		)
		row.add_child(button)


func _table_setup_option_button(label_text: String, selected: bool) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(132, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.20, 0.06, 0.17, 0.76) if selected else Color(0.018, 0.022, 0.052, 0.64), Color(1.0, 0.0, 0.5, 0.95) if selected else Color(0.55, 0.42, 0.95, 0.38), 18))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.86), Color(1.0, 0.0, 0.5, 1.0), 18))
	return button


func _table_setup_option_label(key: String, value: int) -> String:
	if key == "max_hands":
		return _t("common.unlimited") if value >= 999 else _tf("common.hands_count", {"count": value})
	if key == "max_players":
		return _tf("common.players_count", {"count": value})
	return _format_number(value)


func _clear_node_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _build_quick_setup_section(parent: VBoxContainer, option_key: String, title_text: String, buttons: Dictionary, values: Array, callback: Callable) -> void:
	var title := Label.new()
	title.text = title_text
	HomeTheme.make_font_settings(title, 12, HomeTheme.MUTED)
	parent.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	for value_item in values:
		var value: int = int(value_item)
		var button := Button.new()
		button.text = _quick_option_label(option_key, value)
		button.custom_minimum_size = Vector2(150, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 13)
		var captured_value: int = value
		button.pressed.connect(func() -> void: callback.call(captured_value))
		buttons[value] = button
		row.add_child(button)


func _build_quick_blinds_section(parent: VBoxContainer, blind_pairs: Array, buttons: Dictionary) -> void:
	var title := Label.new()
	title.text = _t("common.blinds").to_upper()
	HomeTheme.make_font_settings(title, 12, HomeTheme.MUTED)
	parent.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	for pair_item in blind_pairs:
		var pair: Array = Array(pair_item)
		var small_blind: int = int(pair[0])
		var big_blind: int = int(pair[1])
		var key := "%d/%d" % [small_blind, big_blind]
		var button := Button.new()
		button.text = "%d / %d" % [small_blind, big_blind]
		button.custom_minimum_size = Vector2(150, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(func() -> void: _select_quick_blinds(small_blind, big_blind))
		buttons[key] = button
		row.add_child(button)


func _build_foreground() -> void:
	_foreground_decor = TextureRect.new()
	_foreground_decor.name = "ForegroundDecor"
	_foreground_decor.anchor_left = 0.0
	_foreground_decor.anchor_top = 1.0
	_foreground_decor.anchor_right = 1.0
	_foreground_decor.anchor_bottom = 1.0
	_foreground_decor.offset_left = 180
	_foreground_decor.offset_top = -190
	_foreground_decor.offset_right = 0
	_foreground_decor.offset_bottom = 10
	_foreground_decor.texture = preload("res://assets/home_lobby/foreground/foreground_decor_strip.png")
	_foreground_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foreground_decor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_foreground_decor.modulate = Color(1, 1, 1, 0.0)
	_foreground_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_foreground_decor)

func _on_nav_selected(id: String) -> void:
	match id:
		"home": set_state(LobbyState.COLLAPSED)
		"play": set_state(LobbyState.PLAY_EXPANDED)
		"replay": set_state(LobbyState.REPLAY)
		"store": set_state(LobbyState.STORE)
		"profile": set_state(LobbyState.PROFILE)
		"settings": set_state(LobbyState.SETTINGS)
		_:
			set_state(LobbyState.COLLAPSED)

func _on_play_submenu_selected(id: String) -> void:
	print("Selected play submenu: %s" % id)
	if id == "room_browser":
		set_state(LobbyState.ROOM_BROWSER)

var _transition_tween: Tween

func _start_bg_breathing() -> void:
	if _bg_breath_tween:
		_bg_breath_tween.kill()
	if not _background_texture:
		return
	_bg_breath_tween = create_tween().set_loops()
	_bg_breath_tween.tween_property(_background_texture, "modulate", Color(1.18, 1.15, 1.25, 1.0), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bg_breath_tween.tween_property(_background_texture, "modulate", Color(1.34, 1.30, 1.40, 1.0), 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_bg_breathing() -> void:
	if _bg_breath_tween:
		_bg_breath_tween.kill()
		_bg_breath_tween = null

func _get_panel_for_state(state: LobbyState) -> PanelContainer:
	match state:
		LobbyState.PLAY_EXPANDED: return _play_panel
		LobbyState.REPLAY: return _replay_panel
		LobbyState.STORE: return _store_panel
		LobbyState.PROFILE: return _profile_panel
		LobbyState.SETTINGS: return _settings_panel
		LobbyState.ROOM_BROWSER: return _room_browser_panel
		LobbyState.FRIENDS_ROOM: return _friends_room_panel
		LobbyState.EVENTS: return _events_panel
		_: return null

func _set_expanded(value: bool, immediate: bool = false) -> void:
	_expanded = value
	
	var prompt_target := 0.0 if value else 1.0
	var bg_target := Color(0.48, 0.45, 0.52, 1.0) if value else Color(1.34, 1.30, 1.40, 1.0)
	
	var logo_pos_y := LOGO_EXPANDED_Y if value else LOGO_COLLAPSED_Y
	var logo_scale := LOGO_EXPANDED_SCALE if value else LOGO_COLLAPSED_SCALE
	
	var active_panel := _get_panel_for_state(current_state)
	var all_panels := [_play_panel, _replay_panel, _store_panel, _profile_panel, _settings_panel, _room_browser_panel, _friends_room_panel, _events_panel]
	
	if _transition_tween:
		_transition_tween.kill()
		
	if immediate:
		_center_brand.position.y = logo_pos_y
		_center_brand.scale = logo_scale
		_center_brand.modulate.a = 1.0
		_center_brand.visible = true
		_prompt.modulate.a = prompt_target
		_prompt.visible = not value
		for p in all_panels:
			if p:
				p.visible = (value and p == active_panel)
				p.modulate.a = 1.0 if (value and p == active_panel) else 0.0
		if _cta_button:
			_cta_button.visible = not value
			_cta_button.disabled = value
			_cta_button.modulate.a = 0.0 if value else 1.0
			_cta_button.scale = Vector2.ONE
		_stop_bg_breathing()
		if _background_texture:
			_background_texture.modulate = bg_target
		if not value:
			_start_bg_breathing()
		return
		
	_transition_tween = create_tween().set_parallel(true)
	
	if value:
		_stop_bg_breathing()
		for p in all_panels:
			if p:
				if p == active_panel:
					p.visible = true
					p.modulate.a = 0.0
					_transition_tween.tween_property(p, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				else:
					_transition_tween.tween_property(p, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Animate logo spatial transformation in 0.4s
		_transition_tween.tween_property(_center_brand, "position:y", logo_pos_y, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_center_brand, "scale", logo_scale, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_center_brand, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.tween_property(_prompt, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		if _cta_button:
			_cta_button.disabled = true
			_transition_tween.tween_property(_cta_button, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		if _background_texture:
			_transition_tween.tween_property(_background_texture, "modulate", bg_target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.chain().tween_callback(func() -> void:
			_prompt.visible = false
			if _cta_button:
				_cta_button.visible = false
			for p in all_panels:
				if p and p != active_panel:
					p.visible = false
		)
	else:
		_center_brand.visible = true
		_prompt.visible = true
		_prompt.modulate.a = 0.0
		
		if _cta_button:
			_cta_button.visible = true
			_cta_button.modulate.a = 0.0
			_cta_button.scale = Vector2.ONE
		
		# Animate logo spatial transformation in 0.4s
		_transition_tween.tween_property(_center_brand, "position:y", logo_pos_y, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_center_brand, "scale", logo_scale, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_center_brand, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.tween_property(_prompt, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if _cta_button:
			_transition_tween.tween_property(_cta_button, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		for p in all_panels:
			if p:
				_transition_tween.tween_property(p, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				
		if _background_texture:
			_transition_tween.tween_property(_background_texture, "modulate", bg_target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.chain().tween_callback(func() -> void:
			for p in all_panels:
				if p:
					p.visible = false
			if _cta_button:
				_cta_button.disabled = false
			_start_bg_breathing()
		)

func _on_mode_selected(id: String) -> void:
	print("Selected lobby mode: %s" % id)
	match id:
		"quick_play":
			_show_quick_play_setup()
		"training":
			_start_table_launch_transition("Preparing AI training table...", func() -> void:
				_open_backend_table(_local_backend.create_training_table(_player_profile))
			)
		"room_browser":
			set_state(LobbyState.ROOM_BROWSER)
		"private_table":
			set_state(LobbyState.FRIENDS_ROOM)
		"events":
			set_state(LobbyState.EVENTS)
		_:
			_show_coming_soon(id.to_upper())

func _show_quick_play_setup() -> void:
	if _quick_play_setup_panel == null:
		return
	_reload_player_profile()
	_update_quick_play_setup_profile()
	_quick_play_mode = "chip"
	_select_default_quick_buy_in()
	_selected_quick_small_blind = 25
	_selected_quick_big_blind = 50
	_selected_quick_max_hands = 10
	_refresh_quick_play_setup_options()
	_quick_play_setup_panel.visible = true
	_quick_play_setup_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_quick_play_setup_panel, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _hide_quick_play_setup() -> void:
	if _quick_play_setup_panel != null:
		_quick_play_setup_panel.visible = false


func _start_quick_play_from_setup() -> void:
	var currency := _quick_currency()
	if not _can_afford_buy_in_for_currency(_selected_quick_buy_in, currency):
		_refresh_quick_play_setup_options()
		_show_toast(_t("common.not_enough_gems_store") if currency == "gems" else _t("table.not_enough_buyin_chips"))
		return
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_hide_quick_play_setup()
		_start_table_launch_transition("Finding server table...", func() -> void:
			var quick_config: Dictionary = _quick_server_table_config()
			_log_quick_table_candidates(quick_config)
			_profile_ws_client.quick_join_table(quick_config)
		)
		return
	var table_type := "public_gem" if currency == "gems" else "public_chip"
	var setup_config := {
		"table_type": table_type,
		"currency": currency,
		"buy_in": _selected_quick_buy_in,
		"small_blind": _selected_quick_small_blind,
		"big_blind": _selected_quick_big_blind,
		"hand_count": _normalized_hand_count_for_context(_selected_quick_max_hands),
		"max_hands": _selected_quick_max_hands,
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": 6,
		"allow_quick_join": true,
		"buy_in_deducted_from_wallet": true,
	}
	_hide_quick_play_setup()
	_start_table_launch_transition("Finding a public %s table..." % ("gem" if currency == "gems" else "chip"), func() -> void:
		var context: Dictionary = _local_backend.quick_join_public_table(_player_profile, setup_config)
		if context.is_empty():
			_finish_table_launch_transition()
			_show_toast("No public table is available.")
			return
		if not bool(context.get("is_ai_warmup", false)):
			var service := ProfileServiceScript.new()
			var buy_in_profile: Dictionary = service.deduct_table_buy_in_currency(_selected_quick_buy_in, currency)
			if buy_in_profile.is_empty():
				_finish_table_launch_transition()
				_show_toast("Not enough wallet %s." % _currency_label(currency).to_lower())
				return
			_player_profile = buy_in_profile
			_play_currency_sfx(currency, "quick_buy_in:%s:%d" % [currency, Time.get_ticks_msec()])
			if _top_bar != null:
				_top_bar.configure(_player_profile)
			context["local_player_profile"] = _player_profile
			context["buy_in_deducted_from_wallet"] = true
			var table_session: Dictionary = Dictionary(context.get("table_session", {}))
			table_session["buy_in_deducted_from_wallet"] = true
			context["table_session"] = table_session
		_open_backend_table(context)
	)


func _quick_server_table_config() -> Dictionary:
	var hand_count: int = _selected_quick_max_hands
	if hand_count >= 999:
		hand_count = 0
	var currency := _quick_currency()
	var table_type := "public_gem" if currency == "gems" else "public_chip"
	return {
		"table_type": table_type,
		"currency": currency,
		"buy_in": _selected_quick_buy_in,
		"small_blind": _selected_quick_small_blind,
		"big_blind": _selected_quick_big_blind,
		"hand_count": hand_count,
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": 6,
		"allow_quick_join": true,
		"is_public": true,
	}


func _update_quick_play_setup_profile() -> void:
	var player_name := PlayerProfileScript.get_player_name(_player_profile)
	var currency := _quick_currency()
	var wallet_amount := _wallet_amount_for_currency(currency)
	_quick_play_setup_name_label.text = player_name
	_quick_play_setup_chips_label.text = "%s: %s" % [
		("Server Wallet %s" if server_authoritative_profile and _profile_server_connected else "Wallet %s") % _currency_label(currency),
		_format_number(wallet_amount),
	]
	var texture: Texture2D = AvatarLibraryScript.get_avatar_by_id(PlayerProfileScript.get_avatar_id(_player_profile))
	if texture == null:
		var avatar_path := str(_player_profile.get("avatar", ""))
		if avatar_path != "" and ResourceLoader.exists(avatar_path):
			texture = load(avatar_path) as Texture2D
	_quick_play_setup_avatar.texture = texture
	_quick_play_setup_avatar.visible = texture != null

func _reload_player_profile() -> void:
	_player_profile = ProfileServiceScript.new().get_current_profile()
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()

func _wallet_chips_for_public_chip_setup() -> int:
	if server_authoritative_profile and _profile_server_connected:
		if not _profile_server_wallet_synced:
			return 0
		return PlayerProfileScript.get_total_chips(ProfileServiceScript.new().get_current_profile())
	return PlayerProfileScript.get_total_chips(_player_profile)

func _wallet_label_for_public_chip_setup() -> String:
	return "Server Wallet Chips" if server_authoritative_profile and _profile_server_connected else "Wallet Chips"

func _can_afford_public_buy_in(buy_in: int) -> bool:
	if server_authoritative_profile and _profile_server_connected and not _profile_server_wallet_synced:
		return false
	return _wallet_chips_for_public_chip_setup() >= buy_in

func _quick_currency() -> String:
	return "gems" if _quick_play_mode == "gem" else "chips"

func _wallet_amount_for_currency(currency: String) -> int:
	if currency in ["gem", "gems"]:
		if server_authoritative_profile and _profile_server_connected and not _profile_server_wallet_synced:
			return 0
		return PlayerProfileScript.get_total_gems(ProfileServiceScript.new().get_current_profile() if server_authoritative_profile and _profile_server_connected else _player_profile)
	return _wallet_chips_for_public_chip_setup()

func _can_afford_buy_in_for_currency(buy_in: int, currency: String) -> bool:
	if server_authoritative_profile and _profile_server_connected and not _profile_server_wallet_synced:
		return false
	return _wallet_amount_for_currency(currency) >= buy_in

func _t(key: String) -> String:
	return LocalizationManagerScript.tr_key(key)

func _tf(key: String, params: Dictionary) -> String:
	return LocalizationManagerScript.trf(key, params)

func _currency_label(currency: String) -> String:
	return _t("store.gems") if currency in ["gem", "gems"] else _t("store.chips")

func _play_currency_sfx(currency: String, event_id: String) -> void:
	if currency in ["gem", "gems"]:
		SfxManagerScript.play_gem(self, event_id)
	else:
		SfxManagerScript.play_chip(self, event_id)

func _play_reward_sfx(reward: Dictionary, event_id: String) -> void:
	if int(reward.get("gems", 0)) > 0:
		SfxManagerScript.play_gem(self, "%s:gems" % event_id)
	elif int(reward.get("chips", 0)) > 0:
		SfxManagerScript.play_chip(self, "%s:chips" % event_id)

func _claim_daily_login_bonus() -> void:
	var service := ProfileServiceScript.new()
	_player_profile = service.claim_daily_login_bonus()
	if service.was_last_daily_bonus_claimed():
		var reward: Dictionary = service.get_last_daily_bonus_reward()
		_play_reward_sfx(reward, "daily_bonus:local:%s" % str(reward.get("day", Time.get_ticks_msec())))
		_show_toast(_daily_bonus_toast_text(_t("daily.claimed_title"), reward), [], 3.0)
		if _top_bar != null:
			_top_bar.configure(_player_profile)
		_refresh_daily_bonus_bar()
		_refresh_profile_panel()

func _on_daily_bonus_claim_pressed() -> void:
	if server_authoritative_profile:
		if _profile_ws_client == null or not _profile_server_connected:
			_show_toast(_t("daily.claim_failed"), [], 2.4)
			return
		_profile_ws_client.claim_daily_bonus()
		return
	_claim_daily_login_bonus()

func _connect_profile_server() -> void:
	if _profile_ws_client != null:
		return
	_profile_ws_client = PokerWsClientScript.new()
	_profile_ws_client.name = "ProfileWalletWsClient"
	add_child(_profile_ws_client)
	_profile_ws_client.connected.connect(_on_profile_server_connected)
	_profile_ws_client.disconnected.connect(_on_profile_server_disconnected)
	_profile_ws_client.profile_synced.connect(_on_profile_server_profile_synced)
	_profile_ws_client.wallet_synced.connect(_on_profile_server_wallet_synced)
	_profile_ws_client.daily_bonus_awarded.connect(_on_profile_server_daily_login_awarded)
	_profile_ws_client.daily_bonus_claim_failed.connect(_on_profile_server_daily_bonus_claim_failed)
	_profile_ws_client.avatar_catalog_received.connect(_on_avatar_catalog_received)
	_profile_ws_client.table_list_received.connect(_on_server_table_list_received)
	_profile_ws_client.table_created.connect(_on_server_table_created)
	_profile_ws_client.table_joined.connect(_on_server_table_joined)
	_profile_ws_client.mock_purchase_result_received.connect(_on_server_mock_purchase_result)
	_profile_ws_client.replay_unlocked_received.connect(_on_replay_server_unlocked)
	_profile_ws_client.server_error.connect(_on_profile_server_error)
	var err := _profile_ws_client.connect_to_server(NetworkConfigScript.server_url())
	if err != OK:
		_profile_server_connected = false
		push_warning("[HomeLobby] Could not connect profile server: %s" % error_string(err))

func _on_profile_server_connected() -> void:
	_profile_server_connected = true
	_profile_server_wallet_synced = false
	var player_id := str(_player_profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID))
	var player_name := PlayerProfileScript.get_player_name(_player_profile)
	_profile_ws_client.send_hello(player_name, player_id, _server_avatar_id_for_client(PlayerProfileScript.get_avatar_id(_player_profile)))
	_profile_ws_client.get_avatar_catalog()
	_profile_ws_client.get_profile()
	_profile_ws_client.list_tables()

func _on_profile_server_disconnected() -> void:
	_profile_server_connected = false
	_profile_server_wallet_synced = false
	if current_state == LobbyState.ROOM_BROWSER:
		_refresh_room_browser_rows()

func _on_profile_server_profile_synced(profile: Dictionary, wallet: Dictionary, unlocked_avatar_ids: Array) -> void:
	_player_profile = ProfileServiceScript.new().apply_server_profile(profile, wallet, unlocked_avatar_ids)
	_profile_server_wallet_synced = true
	_refresh_profile_views_from_server()
	_maybe_show_new_player_welcome(profile)

func _on_profile_server_wallet_synced(wallet: Dictionary) -> void:
	_player_profile = ProfileServiceScript.new().apply_wallet_snapshot(wallet)
	_profile_server_wallet_synced = true
	_refresh_profile_views_from_server()

func _on_profile_server_daily_login_awarded(chips: int, xp: int = PlayerProfileScript.DAILY_LOGIN_XP, gems: int = 0) -> void:
	_player_profile = ProfileServiceScript.new().get_current_profile()
	_refresh_profile_views_from_server()
	_play_reward_sfx({"chips": chips, "xp": xp, "gems": gems}, "daily_bonus:server:%d:%d:%d" % [chips, xp, gems])
	print("[DailyBonusClient] topbar updated chips=%s gems=%s" % [
		str(PlayerProfileScript.get_total_chips(_player_profile)),
		str(PlayerProfileScript.get_total_gems(_player_profile)),
	])
	_show_toast(_daily_bonus_toast_text(_t("daily.claimed_title"), {"chips": chips, "xp": xp, "gems": gems}), [], 3.0)

func _on_profile_server_daily_bonus_claim_failed(reason: String) -> void:
	if reason == "already_claimed_today":
		var state: Dictionary = PlayerProfileScript.daily_bonus_display_state(_player_profile)
		var next_day: int = int(state.get("next_reward_day", state.get("current_day", 1)))
		_show_toast(_tf("daily.already_claimed", {"day": next_day}), [], 2.8)
	else:
		_show_toast(_t("daily.claim_failed"), [], 2.4)
	_refresh_profile_views_from_server()

func _maybe_show_new_player_welcome(server_profile: Dictionary) -> void:
	if not bool(server_profile.get("is_new_player", false)):
		return
	var player_id := String(server_profile.get("player_id", _player_profile.get("player_id", "")))
	if player_id == "" or _welcome_shown_for_player_id == player_id:
		return
	_welcome_shown_for_player_id = player_id
	var display_name := String(_player_profile.get("player_name", _player_profile.get("name", server_profile.get("display_name", "Player"))))
	var chips := PlayerProfileScript.get_total_chips(_player_profile)
	var level := int(_player_profile.get("level", 1))
	var title := PlayerProfileScript.title_for_level(level)
	_show_toast("Welcome, %s\nStarting Chips: %s\nLevel %d - %s" % [display_name, _format_number(chips), level, title], [], 4.0)

func _on_avatar_catalog_received(catalog: Array) -> void:
	_avatar_catalog = catalog.duplicate(true)
	_avatar_catalog_by_id.clear()
	for item_value in _avatar_catalog:
		var item := Dictionary(item_value)
		var avatar_id := str(item.get("avatar_id", ""))
		if avatar_id != "":
			_avatar_catalog_by_id[avatar_id] = item
	_refresh_avatar_gallery()

func _on_profile_server_error(message: String) -> void:
	if message != "":
		_show_toast("Server\n%s", [_server_lobby_error_text(message)], 2.8)
	if not _pending_replay_unlock_record.is_empty() and message in ["insufficient_gems", "replay_access_denied", "replay_not_found", "replay_key_missing", "replay_unlock_failed"]:
		_pending_replay_unlock_record = {}
		_pending_replay_unlock_index_entry = {}
	if _is_launching_table:
		_finish_table_launch_transition()

func _server_lobby_error_text(message: String) -> String:
	match message:
		"room_not_found":
			return _t("server_error.room_not_found")
		"table_full":
			return _t("server_error.table_full")
		"room_not_available":
			return _t("server_error.room_not_available")
		"insufficient_chips":
			return _t("common.not_enough_chips")
		"insufficient_gems":
			return _t("replay.not_enough_gems")
		"replay_access_denied":
			return "Replay access denied."
		"replay_not_found":
			return "Replay not found."
		"replay_key_missing":
			return _t("replay.unlock_failed")
		"replay_unlock_failed":
			return _t("replay.unlock_failed")
		_:
			return message

func _refresh_profile_views_from_server() -> void:
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_daily_bonus_bar()
	_refresh_profile_panel()
	if _quick_play_setup_panel != null and _quick_play_setup_panel.visible:
		_update_quick_play_setup_profile()
		_refresh_quick_play_setup_options()
	if _public_table_setup_panel != null and _public_table_setup_panel.visible:
		_render_table_creation_setup_panel(_public_table_setup_panel, true)
	if _private_room_setup_panel != null and _private_room_setup_panel.visible:
		_render_table_creation_setup_panel(_private_room_setup_panel, false)
	_refresh_replay_panel_for_economy_config()

func _refresh_replay_panel_for_economy_config() -> void:
	var next_signature := JSON.stringify(Dictionary(_player_profile.get("replay_economy", {})))
	if next_signature == _replay_economy_signature or _replay_panel == null or _lobby_ui_root == null:
		return
	var was_visible := current_state == LobbyState.REPLAY and _replay_panel.visible
	_lobby_ui_root.remove_child(_replay_panel)
	_replay_panel.queue_free()
	_build_replay_panel()
	if was_visible:
		_replay_panel.visible = true
		_replay_panel.modulate.a = 1.0

func _show_pending_launch_error() -> void:
	var message := TableLaunchContext.consume_pending_launch_error()
	if message != "":
		_finish_table_launch_transition()
		_show_toast(message, [], 3.2)

func _request_server_table_list() -> void:
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_profile_ws_client.list_tables()
	else:
		_refresh_room_browser_rows()

func _on_server_table_list_received(tables: Array) -> void:
	_server_public_tables = tables.duplicate(true)
	print("[ClientTableList] received count=%d" % _server_public_tables.size())
	_refresh_room_browser_rows()

func _on_server_table_created(room_id: String, table_info: Dictionary) -> void:
	_open_server_table(room_id, table_info, 5)

func _on_server_table_joined(room_id: String, table_info: Dictionary) -> void:
	_open_server_table(room_id, table_info, -1)

func _open_server_table(room_id: String, table_info: Dictionary, requested_seat_index: int = 0) -> void:
	if room_id == "":
		_finish_table_launch_transition()
		_show_toast("Server Table\nMissing room_id", [], 2.2)
		return
	_open_backend_table(_server_table_context(room_id, table_info, requested_seat_index))

func _server_table_context(room_id: String, table_info: Dictionary, requested_seat_index: int = 0) -> Dictionary:
	var buy_in := int(table_info.get("buy_in", 5000))
	var small_blind := int(table_info.get("small_blind", 25))
	var big_blind := int(table_info.get("big_blind", 50))
	var max_hands := int(table_info.get("hand_count", table_info.get("max_hands", 10)))
	var action_time_seconds := int(table_info.get("action_time_seconds", DEFAULT_ACTION_TIME_SECONDS))
	var server_table_type := str(table_info.get("table_type", "public_chip"))
	var currency := str(table_info.get("currency", "gems" if server_table_type in ["public_gem", "private_gem"] else "chips"))
	var is_private_room := server_table_type in ["private_chip", "private_gem", "private_room", "private_casual"]
	var launch_mode := "friends_room" if is_private_room else "quick_play"
	var launch_table_type := server_table_type
	var room_code := str(table_info.get("room_code", ""))
	if max_hands <= 0:
		max_hands = 999
	return {
		"mode": launch_mode,
		"backend_type": "server_authoritative",
		"local_player_profile": _player_profile.duplicate(true),
		"table_id": room_id,
		"room_id": room_id,
		"room_code": room_code,
		"seats": [],
		"buy_in": buy_in,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"action_time_seconds": action_time_seconds,
		"is_training": false,
		"table_type": launch_table_type,
		"currency": currency,
		"uses_practice_chips": false,
		"affects_account_balance": true,
		"buy_in_deducted_from_wallet": false,
		"allow_debug_tools": true,
		"requested_seat_index": requested_seat_index,
		"ai_player_count": 0,
		"max_hands": max_hands,
		"waiting_for_real_players": (not is_private_room) and int(table_info.get("current_players", table_info.get("seated_count", 0))) < 2,
		"is_ai_warmup": false,
		"warmup_ai_player_ids": [],
		"table_session": {
			"mode": launch_mode,
			"table_type": launch_table_type,
			"currency": currency,
			"uses_practice_chips": false,
			"affects_account_balance": true,
			"buy_in_deducted_from_wallet": false,
			"buy_in": buy_in,
			"starting_chips": buy_in,
			"current_table_chips": buy_in,
			"small_blind": small_blind,
			"big_blind": big_blind,
			"max_hands": max_hands,
			"action_time_seconds": action_time_seconds,
			"waiting_for_real_players": (not is_private_room) and int(table_info.get("current_players", table_info.get("seated_count", 0))) < 2,
			"is_ai_warmup": false,
			"warmup_ai_player_ids": [],
		},
	}


func _select_default_quick_buy_in() -> void:
	var total_chips := _wallet_chips_for_public_chip_setup()
	_selected_quick_buy_in = 1000 if total_chips < 5000 else 2000


func _select_quick_buy_in(value: int) -> void:
	if not _can_afford_buy_in_for_currency(value, _quick_currency()):
		return
	_selected_quick_buy_in = value
	_refresh_quick_play_setup_options()


func _select_quick_blinds(small_blind: int, big_blind: int) -> void:
	_selected_quick_small_blind = small_blind
	_selected_quick_big_blind = big_blind
	_refresh_quick_play_setup_options()


func _select_quick_hand_count(value: int) -> void:
	_selected_quick_max_hands = value
	_refresh_quick_play_setup_options()


func _select_quick_play_mode(mode: String) -> void:
	if mode != "chip" and mode != "gem":
		return
	_quick_play_mode = mode
	_apply_quick_mode_defaults()
	_refresh_quick_play_setup_options()

func _apply_quick_mode_defaults() -> void:
	if _quick_play_mode == "gem":
		if not GEM_BUY_IN_OPTIONS.has(_selected_quick_buy_in):
			_selected_quick_buy_in = 50
		var valid_blind := false
		for pair_item in GEM_BLIND_OPTIONS:
			var pair: Array = Array(pair_item)
			if int(pair[0]) == _selected_quick_small_blind and int(pair[1]) == _selected_quick_big_blind:
				valid_blind = true
		if not valid_blind:
			_selected_quick_small_blind = 2
			_selected_quick_big_blind = 5
		return
	if not CHIP_BUY_IN_OPTIONS.has(_selected_quick_buy_in):
		_select_default_quick_buy_in()
	var chip_blind_valid := false
	for pair_item in CHIP_BLIND_OPTIONS:
		var pair: Array = Array(pair_item)
		if int(pair[0]) == _selected_quick_small_blind and int(pair[1]) == _selected_quick_big_blind:
			chip_blind_valid = true
	if not chip_blind_valid:
		_selected_quick_small_blind = 25
		_selected_quick_big_blind = 50


func _refresh_quick_play_setup_options() -> void:
	var is_chip_mode := _quick_play_mode == "chip"
	var wallet_amount := _wallet_amount_for_currency(_quick_currency())
	if _quick_chip_settings_container != null:
		_quick_chip_settings_container.visible = is_chip_mode
	if _quick_gem_placeholder_container != null:
		_quick_gem_placeholder_container.visible = not is_chip_mode
	if _quick_start_button != null:
		_quick_start_button.disabled = _selected_quick_buy_in > wallet_amount
		_quick_start_button.text = _t("common.find_table").to_upper()
		_quick_start_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if _quick_start_button.disabled else Control.CURSOR_POINTING_HAND
		_quick_start_button.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(Color(0.08, 0.06, 0.10, 0.62), Color(0.76, 0.52, 0.9, 0.28), 22))
		_quick_start_button.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.86, 0.72))
	if _quick_play_setup_hint_label != null:
		if _selected_quick_buy_in > wallet_amount:
			_quick_play_setup_hint_label.text = _t("common.not_enough_gems_store") if not is_chip_mode else _t("table.not_enough_server_wallet_chips")
		else:
			_quick_play_setup_hint_label.text = _t("quick.copy_chip") if is_chip_mode else _t("quick.copy_gem")
	for key_item in _quick_mode_buttons.keys():
		var mode := str(key_item)
		var button: Button = _quick_mode_buttons[key_item] as Button
		_apply_quick_mode_style(button, mode == _quick_play_mode)
	for key_item in _quick_buy_in_buttons.keys():
		var value: int = int(key_item)
		var button: Button = _quick_buy_in_buttons[key_item] as Button
		if button == null:
			continue
		var disabled: bool = is_chip_mode and value > wallet_amount
		_apply_quick_option_style(button, value == _selected_quick_buy_in, disabled)
	for key_item in _quick_gem_buy_in_buttons.keys():
		var value: int = int(key_item)
		var button: Button = _quick_gem_buy_in_buttons[key_item] as Button
		if button == null:
			continue
		var disabled: bool = (not is_chip_mode) and value > wallet_amount
		_apply_quick_option_style(button, value == _selected_quick_buy_in, disabled)
	for key_item in _quick_blinds_buttons.keys():
		var key: String = str(key_item)
		var button: Button = _quick_blinds_buttons[key_item] as Button
		if button == null:
			continue
		_apply_quick_option_style(button, key == "%d/%d" % [_selected_quick_small_blind, _selected_quick_big_blind], false)
	for key_item in _quick_gem_blinds_buttons.keys():
		var key: String = str(key_item)
		var button: Button = _quick_gem_blinds_buttons[key_item] as Button
		if button == null:
			continue
		_apply_quick_option_style(button, key == "%d/%d" % [_selected_quick_small_blind, _selected_quick_big_blind], false)
	for key_item in _quick_hand_count_buttons.keys():
		var value: int = int(key_item)
		var button: Button = _quick_hand_count_buttons[key_item] as Button
		if button == null:
			continue
		_apply_quick_option_style(button, value == _selected_quick_max_hands, false)
	for key_item in _quick_gem_hand_count_buttons.keys():
		var value: int = int(key_item)
		var button: Button = _quick_gem_hand_count_buttons[key_item] as Button
		if button == null:
			continue
		_apply_quick_option_style(button, value == _selected_quick_max_hands, false)


func _apply_quick_mode_style(button: Button, selected: bool) -> void:
	if button == null:
		return
	var bg := Color(0.20, 0.06, 0.17, 0.76) if selected else Color(0.018, 0.022, 0.052, 0.64)
	var border := Color(1.0, 0.0, 0.5, 0.95) if selected else Color(0.55, 0.42, 0.95, 0.38)
	var font := Color(1.0, 0.92, 0.98, 1.0) if selected else Color(0.70, 0.74, 0.92, 0.88)
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(bg, border, 18))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.30, 0.10, 0.25, 0.86), Color(1.0, 0.0, 0.5, 1.0), 18))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 1.0, 1.0))


func _apply_quick_option_style(button: Button, selected: bool, disabled: bool) -> void:
	button.disabled = disabled
	var bg := Color(0.018, 0.022, 0.052, 0.72)
	var border := Color(0.36, 0.42, 0.7, 0.28)
	var font := HomeTheme.TEXT
	if selected:
		bg = Color(0.22, 0.08, 0.18, 0.84)
		border = Color(1.0, 0.0, 0.5, 0.86)
		font = Color(1.0, 0.92, 0.98, 1.0)
	elif disabled:
		bg = Color(0.01, 0.012, 0.024, 0.38)
		border = Color(0.20, 0.22, 0.32, 0.18)
		font = Color(0.40, 0.42, 0.52, 0.85)
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(bg, border, 16))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(bg.lightened(0.08), border.lightened(0.18), 16))
	button.add_theme_stylebox_override("pressed", HomeTheme.make_button_style(bg.darkened(0.08), border, 16))
	button.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(bg, border, 16))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_disabled_color", font)


func _quick_option_label(option_key: String, value: int) -> String:
	if option_key == "hand_count" and value >= 999:
		return _t("common.unlimited")
	if option_key == "hand_count":
		return _tf("common.hands_count", {"count": value})
	return _format_number(value)


func _format_number(value: int) -> String:
	var text := str(value)
	var output := ""
	while text.length() > 3:
		output = "," + text.substr(text.length() - 3, 3) + output
		text = text.substr(0, text.length() - 3)
	return text + output

func _open_poker_table_with_profile(mode: String, table_id: String) -> void:
	_start_table_launch_transition("Preparing table...", func() -> void:
		TableLaunchContext.configure(mode, table_id, _player_profile)
		ScreenNavigator.open_poker_table(get_tree(), mode, table_id, _player_profile)
	)

func _open_backend_table(table_context: Dictionary) -> void:
	if table_context.is_empty():
		_finish_table_launch_transition()
		_show_coming_soon("TABLE")
		return
	ScreenNavigator.open_poker_table_with_context(get_tree(), table_context)

func _start_table_launch_transition(label_text: String, launch_callable: Callable) -> void:
	if _is_launching_table:
		return
	_is_launching_table = true
	if _launch_transition_tween != null:
		_launch_transition_tween.kill()
	if _fade_overlay == null:
		launch_callable.call()
		return
	_fade_overlay.visible = true
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _launch_transition_label != null:
		_launch_transition_label.text = "ENTERING TABLE\n%s" % label_text
		_launch_transition_label.visible = true
	_stop_bg_breathing()
	_launch_transition_tween = create_tween()
	_launch_transition_tween.tween_property(_fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.88), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_launch_transition_tween.tween_interval(0.25)
	_launch_transition_tween.tween_callback(func() -> void:
		launch_callable.call()
	)

func _finish_table_launch_transition() -> void:
	_is_launching_table = false
	if _launch_transition_tween != null:
		_launch_transition_tween.kill()
		_launch_transition_tween = null
	if _fade_overlay != null:
		_fade_overlay.visible = false
		_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_overlay.color = Color(0, 0, 0, 0)
	if _launch_transition_label != null:
		_launch_transition_label.visible = false
	_start_bg_breathing()

func _open_friends_room_lobby() -> void:
	_update_friends_room_panel()
	set_state(LobbyState.FRIENDS_ROOM)


func _join_private_room_by_code() -> void:
	var room_code := ""
	if _friends_room_code_input != null:
		room_code = _friends_room_code_input.text.strip_edges().to_upper()
	if room_code == "":
		_show_toast(_t("friends.enter_room_code"))
		return
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_start_table_launch_transition(_t("friends.joining_private_room"), func() -> void:
			_profile_ws_client.join_private_table(room_code)
		)
		return
	_start_table_launch_transition(_t("friends.joining_private_room"), func() -> void:
		var context: Dictionary = _local_backend.join_room(room_code, _player_profile)
		if context.is_empty():
			_finish_table_launch_transition()
			_show_toast(_t("server_error.room_not_found"))
			return
		_open_backend_table(context)
	)


func _confirm_public_table_setup() -> void:
	if _public_table_setup_mode == "gem":
		_show_toast(_t("setup.public_gem_quick_note"))
		return
	var buy_in: int = int(_public_table_setup_values.get("buy_in", 2000))
	if not _can_afford_public_buy_in(buy_in):
		_show_toast(_t("table.not_enough_buyin_chips"))
		_render_table_creation_setup_panel(_public_table_setup_panel, true)
		return
	_hide_table_creation_setup_panels()
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_start_table_launch_transition(_t("browser.creating_public_table"), func() -> void:
			_profile_ws_client.create_table("%s's Table" % PlayerProfileScript.get_player_name(_player_profile), {
				"table_type": "public_chip",
				"currency": "chip",
				"buy_in": buy_in,
				"small_blind": int(_public_table_setup_values.get("small_blind", 50)),
				"big_blind": int(_public_table_setup_values.get("big_blind", 100)),
				"hand_count": _normalized_hand_count_for_context(int(_public_table_setup_values.get("max_hands", 10))),
				"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
				"max_players": int(_public_table_setup_values.get("max_players", 6)),
				"allow_quick_join": true,
				"is_public": true,
			})
		)
		return
	_reload_player_profile()
	if PlayerProfileScript.get_total_chips(_player_profile) < buy_in:
		_show_toast(_t("table.not_enough_wallet_chips"))
		return
	_start_table_launch_transition(_t("browser.creating_public_table"), func() -> void:
		var table: Dictionary = _local_backend.create_public_table(_public_table_config_from_values(_public_table_setup_values))
		_join_public_chip_table_after_wallet_check(str(table.get("table_id", "")))
	)


func _confirm_private_room_setup() -> void:
	var buy_in: int = int(_private_room_setup_values.get("buy_in", 20000))
	var currency := "gems" if _private_room_setup_mode == "gem" else "chips"
	if not _can_afford_buy_in_for_currency(buy_in, currency):
		_show_toast(_t("common.not_enough_gems_store") if currency == "gems" else _t("table.not_enough_buyin_chips"))
		_render_table_creation_setup_panel(_private_room_setup_panel, false)
		return
	_hide_table_creation_setup_panels()
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_start_table_launch_transition(_t("friends.creating_private_room"), func() -> void:
			_profile_ws_client.create_private_table(_private_room_server_config_from_values())
		)
		return
	_start_table_launch_transition(_t("friends.creating_private_room"), func() -> void:
		var service := ProfileServiceScript.new()
		var buy_in_profile: Dictionary = service.deduct_table_buy_in_currency(buy_in, currency)
		if buy_in_profile.is_empty():
			_finish_table_launch_transition()
			_show_toast(_tf("common.not_enough_wallet_currency", {"currency": _currency_label(currency).to_lower()}))
			return
		_player_profile = buy_in_profile
		_play_currency_sfx(currency, "private_buy_in:%s:%d" % [currency, Time.get_ticks_msec()])
		if _top_bar != null:
			_top_bar.configure(_player_profile)
		_friends_room_context = _local_backend.create_friends_room(_player_profile, _private_room_config_from_values())
		_friends_room_context["buy_in_deducted_from_wallet"] = true
		var table_session: Dictionary = Dictionary(_friends_room_context.get("table_session", {}))
		table_session["buy_in_deducted_from_wallet"] = true
		_friends_room_context["table_session"] = table_session
		_open_backend_table(_friends_room_context)
	)


func _public_table_config_from_values(values: Dictionary) -> Dictionary:
	var small_blind: int = int(values.get("small_blind", 50))
	var big_blind: int = int(values.get("big_blind", 100))
	return {
		"table_type": "public_chip",
		"currency": "chip",
		"table_name": "Public Chip %d/%d" % [small_blind, big_blind],
		"small_blind": small_blind,
		"big_blind": big_blind,
		"buy_in": int(values.get("buy_in", 2000)),
		"hand_count": int(values.get("max_hands", 10)),
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": int(values.get("max_players", 6)),
		"created_by": str(_player_profile.get("player_id", "local_player")),
		"allow_quick_join": true,
	}


func _private_room_config_from_values() -> Dictionary:
	var currency := "gems" if _private_room_setup_mode == "gem" else "chips"
	return {
		"table_type": "private_gem" if currency == "gems" else "private_room",
		"currency": currency,
		"buy_in": int(_private_room_setup_values.get("buy_in", 20000)),
		"small_blind": int(_private_room_setup_values.get("small_blind", 50)),
		"big_blind": int(_private_room_setup_values.get("big_blind", 100)),
		"max_hands": int(_private_room_setup_values.get("max_hands", 10)),
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": int(_private_room_setup_values.get("max_players", 6)),
	}

func _private_room_server_config_from_values() -> Dictionary:
	var config := _private_room_config_from_values()
	config["table_type"] = "private_gem" if str(config.get("currency", "chips")) == "gems" else "private_chip"
	config["hand_count"] = _normalized_hand_count_for_context(int(_private_room_setup_values.get("max_hands", 10)))
	config["is_public"] = false
	config["allow_quick_join"] = false
	config["table_name"] = "%s's Private Room" % PlayerProfileScript.get_player_name(_player_profile)
	return config


func _normalized_hand_count_for_context(value: int) -> int:
	return 0 if value >= 999 else value

func set_background_motion_enabled(value: bool) -> void:
	background_motion_enabled = value

func _quit_game() -> void:
	get_tree().quit()

func _toggle_window_mode() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _handle_runtime_capture_args() -> void:
	var args := OS.get_cmdline_user_args()
	print("CMD user args: ", args)
	if not args.has("--capture-lobby-state"):
		args = OS.get_cmdline_args()
	print("CMD args: ", args)
	if not args.has("--capture-lobby-state"):
		print("No capture lobby state argument found")
		return
	var state := _arg_value(args, "--capture-lobby-state", "collapsed")
	var output := _arg_value(args, "--capture-lobby-output", "")
	if state == "expanded" or state == "play":
		set_state(LobbyState.PLAY_EXPANDED, false)
	elif state == "replay":
		set_state(LobbyState.REPLAY, false)
	elif state == "store":
		set_state(LobbyState.STORE, false)
	elif state == "profile":
		set_state(LobbyState.PROFILE, false)
	elif state == "settings":
		set_state(LobbyState.SETTINGS, false)
	elif state == "room_browser":
		set_state(LobbyState.ROOM_BROWSER, false)
	else:
		set_state(LobbyState.COLLAPSED, false)
	var hover_index := _arg_value(args, "--capture-lobby-hover-index", "")
	if hover_index.is_valid_int():
		var index := hover_index.to_int()
		if index >= 0 and index < _mode_cards.size():
			_mode_cards[index].set_hover_preview(true)
	await get_tree().create_timer(1.5).timeout
	if output != "":
		var image := get_viewport().get_texture().get_image()
		var path := ProjectSettings.globalize_path(output) if output.begins_with("res://") else output
		print("Saving screenshot to path: ", path)
		var err := image.save_png(path)
		print("Save PNG error code: ", err)
		if err != OK:
			push_error("Failed to save Home Lobby runtime screenshot: %s, err: %d" % [output, err])
	get_tree().quit()

func _arg_value(args: PackedStringArray, key: String, fallback: String) -> String:
	var index := args.find(key)
	if index == -1 or index + 1 >= args.size():
		return fallback
	return args[index + 1]

func _build_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.name = "LobbyParticles"
	particles.amount = 45
	particles.lifetime = 6.0
	particles.preprocess = 3.0
	particles.randomness = 0.5
	particles.position = Vector2(1000, 1090)
	
	var p_mat := ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(700, 10, 1)
	p_mat.direction = Vector3(0, -1, 0)
	p_mat.spread = 18.0
	p_mat.gravity = Vector3(0, -12, 0)
	p_mat.initial_velocity_min = 6.0
	p_mat.initial_velocity_max = 16.0
	p_mat.color = Color(1.0, 1.0, 1.0, 1.0)
	p_mat.scale_min = 2.0
	p_mat.scale_max = 5.0
	
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.50, 0.60, 0.85, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.28, 0.78, 0.0),   # Neon Pink Fade In
		Color(1.0, 0.28, 0.78, 0.75),  # Neon Pink Full Glow
		Color(1.0, 0.28, 0.78, 0.65),  # Neon Pink Glow
		Color(0.25, 0.78, 1.0, 0.75),  # Neon Blue/Cyan Glow
		Color(0.25, 0.78, 1.0, 0.60),  # Neon Blue/Cyan
		Color(0.25, 0.78, 1.0, 0.0)    # Neon Blue Fade Out
	])
	var grad_txt := GradientTexture1D.new()
	grad_txt.gradient = gradient
	p_mat.color_ramp = grad_txt
	
	particles.process_material = p_mat
	particles.visibility_rect = Rect2(-1000, -1200, 2000, 1300)
	_background_root.add_child(particles)

# Integration Placeholders
func update_player_ui(_data: Dictionary) -> void:
	pass

func update_mode_cards(_data: Array) -> void:
	pass

func update_daily_bonus(_data: Dictionary) -> void:
	_refresh_daily_bonus_bar()

func _refresh_daily_bonus_bar() -> void:
	if _daily_bonus == null:
		return
	if _daily_bonus.has_method("configure"):
		_daily_bonus.call("configure", PlayerProfileScript.daily_bonus_display_state(_player_profile))

func _daily_bonus_toast_text(title: String, reward: Dictionary) -> String:
	var parts: Array[String] = [title]
	var day: int = int(reward.get("day", 0))
	if day > 0:
		parts.append(_tf("daily.day", {"day": day}))
	var chips: int = int(reward.get("chips", 0))
	var xp: int = int(reward.get("xp", 0))
	var gems: int = int(reward.get("gems", 0))
	if chips > 0:
		parts.append(_tf("daily.chips_gain", {"amount": _format_number(chips)}))
	if xp > 0:
		parts.append("+%d XP" % xp)
	if gems > 0:
		parts.append(_tf("daily.gems_gain", {"amount": gems}))
	return "\n".join(parts)

func _build_cta_button() -> void:
	_cta_button = Button.new()
	_cta_button.name = "LobbyCTAButton"
	_cta_button.text = _t("home.cta_play")
	
	# Layout / Anchors
	_cta_button.anchor_left = 0.5
	_cta_button.anchor_top = 0.5
	_cta_button.anchor_right = 0.5
	_cta_button.anchor_bottom = 0.5
	
	# Size and Position
	_cta_button.custom_minimum_size = Vector2(320, 56)
	_cta_button.offset_left = -160
	_cta_button.offset_top = 220
	_cta_button.offset_right = 160
	_cta_button.offset_bottom = 276
	_cta_button.pivot_offset = Vector2(160, 28)
	
	# Font override
	_cta_button.add_theme_font_size_override("font_size", 16)
	_cta_button.add_theme_color_override("font_color", Color(1.0, 0.65, 0.90, 0.85))
	_cta_button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.98, 1.0))
	_cta_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 1.0, 1.0))
	
	# Styleboxes
	var style_normal := HomeTheme.make_button_style(Color(0.008, 0.010, 0.024, 0.35), Color(1.0, 0.0, 0.5, 0.8), 28)
	style_normal.set_border_width_all(2)
	style_normal.shadow_color = Color(1.0, 0.0, 0.5, 0.25)
	style_normal.shadow_size = 8
	
	var style_hover := HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.65), Color(1.0, 0.0, 0.5, 1.0), 28)
	style_hover.set_border_width_all(2)
	style_hover.shadow_color = Color(1.0, 0.0, 0.5, 0.50)
	style_hover.shadow_size = 18
	
	var style_pressed := HomeTheme.make_button_style(Color(0.12, 0.02, 0.08, 0.60), Color(1.0, 0.0, 0.5, 1.0), 28)
	style_pressed.set_border_width_all(2)
	
	_cta_button.add_theme_stylebox_override("normal", style_normal)
	_cta_button.add_theme_stylebox_override("hover", style_hover)
	_cta_button.add_theme_stylebox_override("pressed", style_pressed)
	_cta_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Hover Tweening
	_cta_button.mouse_entered.connect(func() -> void:
		if _cta_hover_tween:
			_cta_hover_tween.kill()
		_cta_hover_tween = create_tween()
		_cta_hover_tween.tween_property(_cta_button, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	_cta_button.mouse_exited.connect(func() -> void:
		if _cta_hover_tween:
			_cta_hover_tween.kill()
		_cta_hover_tween = create_tween()
		_cta_hover_tween.tween_property(_cta_button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	
	_cta_button.pressed.connect(func() -> void:
		set_state(LobbyState.PLAY_EXPANDED)
	)
	
	_lobby_ui_root.add_child(_cta_button)

func _process(delta: float) -> void:
	if not _expanded and _cta_button and _cta_button.visible:
		_cta_float_time += delta
		var float_offset := sin(_cta_float_time * 2.2) * 6.0
		_cta_button.offset_top = 220.0 + float_offset
		_cta_button.offset_bottom = 276.0 + float_offset
		
		if not _cta_button.is_hovered():
			var alpha := 0.75 + sin(_cta_float_time * 1.8) * 0.25
			_cta_button.modulate.a = alpha
		else:
			_cta_button.modulate.a = 1.0

func _on_join_pressed(room_id: String) -> void:
	print("Loading Poker Table: %s..." % room_id)
	var table_info := _find_public_table_info(room_id)
	if table_info.is_empty() or not _is_joinable_room_browser_table(table_info):
		_show_toast(_t("server_error.room_not_available"))
		_refresh_room_browser_rows()
		return
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		var buy_in: int = int(table_info.get("buy_in", 2000))
		if not _can_afford_public_buy_in(buy_in):
			_show_toast(_t("table.not_enough_buyin_chips"))
			return
		_start_table_launch_transition(_t("browser.joining_server_table"), func() -> void:
			_profile_ws_client.join_table(room_id)
		)
		return
	_start_table_launch_transition(_t("browser.joining_public_table"), func() -> void:
		print("Transition complete. Poker table %s loaded." % room_id)
		_join_public_chip_table_after_wallet_check(room_id)
	)

func _create_public_chip_table_from_browser() -> void:
	_show_public_table_setup()


func _join_public_chip_table_after_wallet_check(room_id: String) -> void:
	if room_id == "":
		_finish_table_launch_transition()
		_show_coming_soon("TABLE")
		return
	var table_info := _find_public_table_info(room_id)
	if table_info.is_empty() or not _is_joinable_room_browser_table(table_info):
		_finish_table_launch_transition()
		_show_toast("This table is no longer available.")
		_refresh_room_browser_rows()
		return
	var buy_in: int = int(table_info.get("buy_in", 2000))
	_reload_player_profile()
	if PlayerProfileScript.get_total_chips(_player_profile) < buy_in:
		_finish_table_launch_transition()
		_show_toast("Not enough wallet chips.")
		return
	var context := _local_backend.join_public_table(room_id, _player_profile)
	if context.is_empty():
		_finish_table_launch_transition()
		_show_toast("This table is no longer available.")
		_refresh_room_browser_rows()
		return
	var service := ProfileServiceScript.new()
	var buy_in_profile: Dictionary = service.deduct_table_buy_in(buy_in)
	if buy_in_profile.is_empty():
		_finish_table_launch_transition()
		_show_toast("Not enough wallet chips.")
		return
	_player_profile = buy_in_profile
	SfxManagerScript.play_chip(self, "browser_public_buy_in:%d:%d" % [buy_in, Time.get_ticks_msec()])
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	context["buy_in_deducted_from_wallet"] = true
	var table_session: Dictionary = Dictionary(context.get("table_session", {}))
	table_session["buy_in_deducted_from_wallet"] = true
	context["table_session"] = table_session
	_open_backend_table(context)


func _find_public_table_info(room_id: String) -> Dictionary:
	var rooms := _server_public_tables if _profile_server_connected else _local_backend.list_public_tables()
	for room_value in rooms:
		var room := _normalized_room_browser_table(Dictionary(room_value))
		if str(room.get("room_id", "")) == room_id:
			return room
	return {}

func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.name = "ComingSoonToast"
	_toast_label.anchor_left = 0.5
	_toast_label.anchor_right = 0.5
	_toast_label.anchor_top = 1.0
	_toast_label.anchor_bottom = 1.0
	_toast_label.offset_left = -180
	_toast_label.offset_right = 180
	_toast_label.offset_top = -128
	_toast_label.offset_bottom = -88
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.modulate.a = 0.0
	_toast_label.visible = false
	HomeTheme.make_font_settings(_toast_label, 15, Color(0.96, 0.92, 1.0, 0.96))
	_lobby_ui_root.add_child(_toast_label)

func _show_toast(format_text: String, args: Array = [], hold_seconds: float = 1.75) -> void:
	if _toast_label == null:
		return
	_toast_label.text = format_text % args if not args.is_empty() else format_text
	_toast_label.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(hold_seconds)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.18)
	_toast_tween.tween_callback(func() -> void:
		_toast_label.visible = false
	)

func _show_coming_soon(label: String) -> void:
	_show_toast("%s - Coming Soon", [label])

func _build_social_panel() -> void:
	_social_panel = _create_home_modal("SocialPanel", Vector2(520, 260))
	var column := _modal_column(_social_panel)
	var title := Label.new()
	title.text = _t("social.title")
	HomeTheme.make_font_settings(title, 24, Color(1, 1, 1, 0.96))
	column.add_child(title)
	var copy := Label.new()
	copy.text = _t("social.copy")
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(copy, 15, Color(0.82, 0.86, 1.0, 0.92))
	column.add_child(copy)
	column.add_child(_modal_spacer())
	var close_button := _modal_button(_t("common.close"))
	close_button.pressed.connect(func() -> void:
		_social_panel.visible = false
	)
	column.add_child(close_button)

func _build_help_panel() -> void:
	_help_panel = _create_home_modal("HelpRulesPanel", Vector2(760, 620))
	var column := _modal_column(_help_panel)
	var title := Label.new()
	title.text = _t("help.title")
	HomeTheme.make_font_settings(title, 24, Color(1, 1, 1, 0.96))
	column.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	_add_help_section(content, _t("help.poker_basics"), [
		_t("help.basics.private_cards"),
		_t("help.basics.community_cards"),
		_t("help.basics.betting_rounds"),
	])
	_add_help_section(content, _t("help.hand_rankings"), [
		_t("help.rank.royal_flush"),
		_t("help.rank.straight_flush"),
		_t("help.rank.four_kind"),
		_t("help.rank.full_house"),
		_t("help.rank.flush"),
		_t("help.rank.straight"),
		_t("help.rank.three_kind"),
		_t("help.rank.two_pair"),
		_t("help.rank.one_pair"),
		_t("help.rank.high_card"),
	])
	_add_help_section(content, _t("help.game_modes"), [
		_t("help.modes.quick"),
		_t("help.modes.browser"),
		_t("help.modes.friends"),
		_t("help.modes.training"),
		_t("help.modes.gem"),
	])
	_add_help_section(content, _t("help.chips_gems"), [
		_t("help.currency.chips"),
		_t("help.currency.gems"),
		_t("help.currency.add_chips"),
	])
	_add_help_section(content, _t("help.table_rules"), [
		_t("help.rules.leave_folds"),
		_t("help.rules.committed_chips"),
		_t("help.rules.timeout"),
		_t("help.rules.repeated_timeout"),
	])

	var close_button := _modal_button(_t("common.close"))
	close_button.pressed.connect(func() -> void:
		_help_panel.visible = false
	)
	column.add_child(close_button)

func _show_social_panel() -> void:
	if _social_panel != null:
		_help_panel.visible = false
		_social_panel.visible = true

func _show_help_panel() -> void:
	if _help_panel != null:
		_social_panel.visible = false
		_help_panel.visible = true

func _create_home_modal(panel_name: String, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -size.x * 0.5
	panel.offset_top = -size.y * 0.5
	panel.offset_right = size.x * 0.5
	panel.offset_bottom = size.y * 0.5
	panel.z_index = 70
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.018, 0.94), Color(0.62, 0.36, 1.0, 0.52), 10, 1))
	_lobby_ui_root.add_child(panel)
	return panel

func _modal_column(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	return column

func _add_help_section(parent: VBoxContainer, section_title: String, lines: Array[String]) -> void:
	var title := Label.new()
	title.text = section_title
	HomeTheme.make_font_settings(title, 16, Color(1.0, 0.58, 0.92, 0.98))
	parent.add_child(title)
	for line in lines:
		var label := Label.new()
		label.text = "- %s" % line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		HomeTheme.make_font_settings(label, 13, Color(0.82, 0.86, 1.0, 0.92))
		parent.add_child(label)

func _modal_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer

func _modal_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(132, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.72), Color(0.62, 0.36, 1.0, 0.55), 8))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.040, 0.046, 0.094, 0.92), Color(1.0, 0.28, 0.78, 0.90), 8))
	return button

func _build_events_panel() -> void:
	_events_panel = PanelContainer.new()
	_events_panel.name = "EventsComingSoonPanel"
	_events_panel.anchor_left = 0.0
	_events_panel.anchor_top = 0.22
	_events_panel.anchor_right = 1.0
	_events_panel.anchor_bottom = 0.88
	_events_panel.offset_left = MAIN_LEFT
	_events_panel.offset_right = -MAIN_RIGHT
	_events_panel.visible = false
	_events_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_events_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(0.62, 0.36, 1.0, 0.28), 8, 1))
	_lobby_ui_root.add_child(_events_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_events_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var title := Label.new()
	title.text = _t("events.title")
	HomeTheme.make_font_settings(title, 28, Color(1.0, 1.0, 1.0, 0.96))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _t("events.subtitle")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(subtitle, 14, HomeTheme.MUTED)
	column.add_child(subtitle)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 18)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(cards)
	_add_event_card(cards, _t("events.all_in_survival.title"), _t("events.all_in_survival.desc"))
	_add_event_card(cards, _t("events.lucky_spin.title"), _t("events.lucky_spin.desc"))
	_add_event_card(cards, _t("events.weekend_gem_cup.title"), _t("events.weekend_gem_cup.desc"))

	var note := Label.new()
	note.text = _t("events.note")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(note, 13, Color(0.72, 0.78, 0.94, 0.92))
	column.add_child(note)

	var back_button := _modal_button(_t("events.back_to_play"))
	back_button.pressed.connect(func() -> void:
		set_state(LobbyState.PLAY_EXPANDED)
	)
	column.add_child(back_button)

func _add_event_card(parent: HBoxContainer, title_text: String, body_text: String) -> void:
	var card := PanelContainer.new()
	card.name = "%sEventCard" % title_text.replace(" ", "")
	card.custom_minimum_size = Vector2(330, 260)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.008, 0.010, 0.024, 0.72), Color(1.0, 0.0, 0.5, 0.26), 10, 1))
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title := Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(title, 20, HomeTheme.PINK)
	column.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	HomeTheme.make_font_settings(body, 14, Color(0.84, 0.88, 1.0, 0.92))
	column.add_child(body)

	var status := Label.new()
	status.text = _t("common.coming_soon").to_upper()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(status, 13, HomeTheme.CYAN)
	column.add_child(status)

	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
				_show_toast(_t("events.card_toast"), [], 2.4)
	)

func _build_room_browser_panel() -> void:
	_room_browser_panel = PanelContainer.new()
	_room_browser_panel.name = "RoomBrowserPanel"
	_room_browser_panel.anchor_left = 0.0
	_room_browser_panel.anchor_top = 0.32
	_room_browser_panel.anchor_right = 1.0
	_room_browser_panel.anchor_bottom = 0.91
	_room_browser_panel.offset_left = MAIN_LEFT
	_room_browser_panel.offset_right = -MAIN_RIGHT
	_room_browser_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_room_browser_panel.custom_minimum_size = Vector2(0, 580)
	_room_browser_panel.visible = false
	_room_browser_panel.modulate.a = 0.0
	_room_browser_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(0.62, 0.36, 1.0, 0.28), 8, 1))
	_lobby_ui_root.add_child(_room_browser_panel)
	
	var content := VBoxContainer.new()
	content.name = "RoomBrowserContent"
	content.add_theme_constant_override("separation", 20)
	_room_browser_panel.add_child(content)
	
	var title_box := VBoxContainer.new()
	content.add_child(title_box)
	var title := Label.new()
	title.text = _t("browser.title")
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = _t("browser.subtitle")
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	var browser_note := Label.new()
	browser_note.text = _t("browser.note")
	HomeTheme.make_font_settings(browser_note, 12, Color(0.72, 0.78, 0.94, 0.92))
	title_box.add_child(browser_note)

	var create_button := Button.new()
	create_button.text = _t("browser.create_public_table")
	create_button.custom_minimum_size = Vector2(240, 38)
	create_button.focus_mode = Control.FOCUS_NONE
	create_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	create_button.add_theme_font_size_override("font_size", 13)
	create_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 18))
	create_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.80), Color(1.0, 0.0, 0.5, 1.0), 18))
	create_button.pressed.connect(_show_public_table_setup)
	title_box.add_child(create_button)
	
	var list_container := PanelContainer.new()
	list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_container.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	content.add_child(list_container)
	
	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_container.add_child(list_vbox)
	_room_browser_list_vbox = list_vbox
	
	var header_hbox := HBoxContainer.new()
	header_hbox.custom_minimum_size = Vector2(0, 40)
	header_hbox.add_theme_constant_override("separation", 10)
	
	var header_pad := MarginContainer.new()
	header_pad.add_theme_constant_override("margin_left", 20)
	header_pad.add_theme_constant_override("margin_right", 20)
	header_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_pad.add_child(header_hbox)
	list_vbox.add_child(header_pad)
	
	var col_widths := ROOM_BROWSER_COL_WIDTHS
	var headers := [_t("browser.headers.room_name"), _t("browser.headers.blinds"), _t("browser.headers.players"), _t("browser.headers.buy_in_limits"), ""]
	
	for i in range(headers.size()):
		var lbl := Label.new()
		lbl.text = headers[i]
		lbl.custom_minimum_size = Vector2(col_widths[i], 0)
		HomeTheme.make_font_settings(lbl, 13, HomeTheme.PURPLE)
		header_hbox.add_child(lbl)
		
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.62, 0.36, 1.0, 0.18)
	list_vbox.add_child(sep)
	_refresh_room_browser_rows()

func _refresh_room_browser_rows() -> void:
	if _room_browser_list_vbox == null:
		return
	while _room_browser_list_vbox.get_child_count() > 2:
		var child := _room_browser_list_vbox.get_child(2)
		_room_browser_list_vbox.remove_child(child)
		child.queue_free()
	var rooms := _server_public_tables if _profile_server_connected else _local_backend.list_public_tables()
	var raw_count: int = rooms.size()
	if rooms.is_empty():
		var empty_label := Label.new()
		empty_label.text = _t("browser.empty_server") if _profile_server_connected else _t("browser.empty_local")
		empty_label.custom_minimum_size = Vector2(0, 54)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		HomeTheme.make_font_settings(empty_label, 13, HomeTheme.MUTED)
		_room_browser_list_vbox.add_child(empty_label)
		return
	var visible_count := 0
	var normalized_count := 0
	for room_value in rooms:
		var normalized_room: Dictionary = _normalized_room_browser_table(Dictionary(room_value))
		normalized_count += 1
		var decision: Dictionary = _room_browser_filter_decision(normalized_room)
		_log_client_table_list_room(normalized_room, decision)
		if not bool(decision.get("include", false)):
			continue
		_add_room_browser_row(normalized_room)
		visible_count += 1
	print("[ClientTableList] raw server list count=%d after normalize count=%d after browser filter count=%d" % [raw_count, normalized_count, visible_count])
	if visible_count == 0:
		var filtered_empty_label := Label.new()
		filtered_empty_label.text = _t("browser.empty_filtered")
		filtered_empty_label.custom_minimum_size = Vector2(0, 54)
		filtered_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		HomeTheme.make_font_settings(filtered_empty_label, 13, HomeTheme.MUTED)
		_room_browser_list_vbox.add_child(filtered_empty_label)

func _normalized_room_browser_table(room: Dictionary) -> Dictionary:
	var room_id := str(room.get("room_id", room.get("table_id", "")))
	var seated_count := _connected_room_player_count(room)
	var max_players := int(room.get("max_players", 6))
	var status := str(room.get("status", room.get("hand_state", "waiting")))
	var hand_state := str(room.get("hand_state", room.get("phase", status)))
	return {
		"room_id": room_id,
		"table_name": str(room.get("table_name", room_id if room_id != "" else _t("replay.public_table"))),
		"table_type": str(room.get("table_type", "public_chip")),
		"visibility": str(room.get("visibility", "public" if bool(room.get("is_public", true)) else "private")),
		"currency": str(room.get("currency", "chip")),
		"small_blind": int(room.get("small_blind", 10)),
		"big_blind": int(room.get("big_blind", 20)),
		"buy_in": int(room.get("buy_in", 1000)),
		"seated_count": seated_count,
		"max_players": max_players,
		"hand_state": hand_state,
		"status": "full" if seated_count >= max_players else status,
		"session_complete": bool(room.get("session_complete", false)),
		"is_ai_warmup": bool(room.get("is_ai_warmup", false)),
		"host_in_local_warmup": bool(room.get("host_in_local_warmup", false)),
		"official_session_started": bool(room.get("official_session_started", room.get("official_hand_started", false))),
		"official_hand_started": bool(room.get("official_hand_started", room.get("official_session_started", false))),
		"waiting_for_real_players": bool(room.get("waiting_for_real_players", false)),
		"pending_real_joiners": Array(room.get("pending_real_joiners", [])).duplicate(true),
		"warmup_ai_player_ids": Array(room.get("warmup_ai_player_ids", [])).duplicate(),
		"real_player_ids": Array(room.get("real_player_ids", [])).duplicate(),
		"current_turn_seat": int(room.get("current_turn_seat", room.get("turn_seat_index", -1))),
		"allow_quick_join": bool(room.get("allow_quick_join", true)),
		"players": Array(room.get("players", [])).duplicate(true),
		"seats": Array(room.get("seats", [])).duplicate(true),
		"pot": int(room.get("pot", 0)),
	}

func _is_joinable_room_browser_table(room: Dictionary) -> bool:
	return bool(_room_browser_filter_decision(room).get("include", false))

func _room_browser_filter_decision(room: Dictionary) -> Dictionary:
	if str(room.get("table_type", "public_chip")) != "public_chip":
		return {"include": false, "reason": "not_public_chip"}
	var visibility: String = str(room.get("visibility", "public"))
	if visibility != "public":
		return {"include": false, "reason": "private_room"}
	var currency: String = str(room.get("currency", "chip"))
	if currency not in ["chip", "chips"]:
		return {"include": false, "reason": "wrong_currency"}
	var status := str(room.get("status", ""))
	var hand_state := str(room.get("hand_state", status))
	var host_warming := bool(room.get("host_in_local_warmup", false))
	var official_started := bool(room.get("official_session_started", room.get("official_hand_started", false)))
	if bool(room.get("is_ai_warmup", false)) and not host_warming:
		return {"include": false, "reason": "local_warmup_shadow"}
	if status in ["full", "closed", "dirty", "paused", "hand_over", "showdown_reveal", "showdown", "finished"]:
		return {"include": false, "reason": status}
	if hand_state in ["closed", "dirty", "paused", "hand_over", "showdown_reveal", "finished"]:
		return {"include": false, "reason": hand_state}
	if bool(room.get("session_complete", false)):
		return {"include": false, "reason": "session_complete"}
	if int(room.get("seated_count", 0)) >= int(room.get("max_players", 6)):
		return {"include": false, "reason": "full"}
	if int(room.get("seated_count", 0)) <= 0 and (not Array(room.get("players", [])).is_empty() or not Array(room.get("seats", [])).is_empty()) and _connected_room_player_count(room) > 0:
		return {"include": false, "reason": "disconnected_only"}
	if host_warming and not official_started:
		return {"include": true, "reason": "host_warmup_joinable"}
	if status in ["waiting", "waiting_for_players", "waiting_ready", "ready_to_start", "open"]:
		return {"include": true, "reason": "waiting_public_room"}
	return {"include": false, "reason": "playing_not_quick_joinable" if status == "playing" or hand_state in ["preflop", "flop", "turn", "river"] else "not_waiting_public_room"}

func _quick_table_filter_decision(room: Dictionary, config: Dictionary) -> Dictionary:
	var expected_type: String = str(config.get("table_type", "public_chip"))
	var expected_currency: String = str(config.get("currency", "chips"))
	if str(room.get("table_type", "public_chip")) != expected_type:
		return {"include": false, "reason": "table_type_mismatch"}
	if str(room.get("currency", "chips")) != expected_currency:
		return {"include": false, "reason": "currency_mismatch"}
	if str(room.get("visibility", "public")) != "public":
		return {"include": false, "reason": "private_room"}
	var status := str(room.get("status", ""))
	var hand_state := str(room.get("hand_state", status))
	if bool(room.get("session_complete", false)):
		return {"include": false, "reason": "session_complete"}
	if int(room.get("seated_count", 0)) >= int(room.get("max_players", 6)):
		return {"include": false, "reason": "full"}
	if status not in ["waiting", "waiting_for_players", "waiting_ready", "ready_to_start", "open"] and not bool(room.get("host_in_local_warmup", false)):
		return {"include": false, "reason": "not_waiting_public_room"}
	if hand_state in ["preflop", "flop", "turn", "river", "showdown", "hand_over", "closed", "finished"]:
		return {"include": false, "reason": "playing_not_quick_joinable"}
	if int(room.get("buy_in", 0)) != int(config.get("buy_in", 0)):
		return {"include": false, "reason": "buy_in_mismatch"}
	if int(room.get("small_blind", 0)) != int(config.get("small_blind", 0)) or int(room.get("big_blind", 0)) != int(config.get("big_blind", 0)):
		return {"include": false, "reason": "blinds_mismatch"}
	var room_hands: int = _normalized_hand_count_for_context(int(room.get("hand_count", room.get("max_hands", 10))))
	var selected_hands: int = _normalized_hand_count_for_context(int(config.get("hand_count", config.get("max_hands", 10))))
	if room_hands != selected_hands:
		return {"include": false, "reason": "hand_count_mismatch"}
	if not bool(room.get("allow_quick_join", true)):
		return {"include": false, "reason": "quick_join_disabled"}
	return {"include": true, "reason": "candidate"}

func _log_client_table_list_room(room: Dictionary, browser_decision: Dictionary) -> void:
	var quick_decision: Dictionary = _quick_table_filter_decision(room, _quick_server_table_config())
	print("[ClientTableList] room %s: state=%s status=%s host_in_local_warmup=%s current_players=%d buy_in=%d blinds=%d/%d hand_count=%d browser_include=%s quick_candidate=%s reason=%s" % [
		str(room.get("room_id", room.get("table_id", ""))),
		str(room.get("hand_state", "")),
		str(room.get("status", "")),
		str(bool(room.get("host_in_local_warmup", false))),
		int(room.get("seated_count", room.get("current_players", 0))),
		int(room.get("buy_in", 0)),
		int(room.get("small_blind", 0)),
		int(room.get("big_blind", 0)),
		int(room.get("hand_count", room.get("max_hands", 0))),
		str(bool(browser_decision.get("include", false))),
		str(bool(quick_decision.get("include", false))),
		str(browser_decision.get("reason", "unknown")),
	])

func _log_quick_table_candidates(config: Dictionary) -> void:
	print("[ClientQuick] selected buy_in=%d blinds=%d/%d hand_count=%d" % [
		int(config.get("buy_in", 0)),
		int(config.get("small_blind", 0)),
		int(config.get("big_blind", 0)),
		int(config.get("hand_count", config.get("max_hands", 0))),
	])
	var candidate_count := 0
	var chosen_room_id := ""
	for room_value in _server_public_tables:
		var room: Dictionary = _normalized_room_browser_table(Dictionary(room_value))
		var decision: Dictionary = _quick_table_filter_decision(room, config)
		var include: bool = bool(decision.get("include", false))
		if include:
			candidate_count += 1
			if chosen_room_id == "":
				chosen_room_id = str(room.get("room_id", ""))
		print("[ClientQuick] room %s quick_candidate=%s reason=%s browser_visible=%s" % [
			str(room.get("room_id", "")),
			str(include),
			str(decision.get("reason", "unknown")),
			str(bool(_room_browser_filter_decision(room).get("include", false))),
		])
	print("[ClientQuick] candidate rooms count=%d chosen room_id=%s create_new_room=%s" % [
		candidate_count,
		chosen_room_id,
		str(chosen_room_id == ""),
	])

func _connected_room_player_count(room: Dictionary) -> int:
	var real_player_ids: Array = Array(room.get("real_player_ids", []))
	if not real_player_ids.is_empty():
		return min(real_player_ids.size(), int(room.get("max_players", 6)))
	var counted := {}
	var count := 0
	for player_item in Array(room.get("players", [])):
		var player := Dictionary(player_item)
		if not _is_connected_room_player(player):
			continue
		var player_id := str(player.get("player_id", player.get("id", "player_%d" % count)))
		if counted.has(player_id):
			continue
		counted[player_id] = true
		count += 1
	for seat_item in Array(room.get("seats", [])):
		var seat := Dictionary(seat_item)
		if not _is_connected_room_player(seat):
			continue
		var seat_player_id := str(seat.get("player_id", seat.get("id", "seat_%s" % str(seat.get("seat_id", count)))))
		if counted.has(seat_player_id):
			continue
		counted[seat_player_id] = true
		count += 1
	if count == 0 and Array(room.get("players", [])).is_empty() and Array(room.get("seats", [])).is_empty():
		count = max(int(room.get("seated_count", room.get("current_players", 0))), 0)
	return min(count, int(room.get("max_players", 6)))

func _is_connected_room_player(data: Dictionary) -> bool:
	var status := str(data.get("status", ""))
	if data.has("status") and status in ["empty", "left", "out", "disconnected"]:
		return false
	if bool(data.get("disconnected", false)):
		return false
	if data.has("connected") and not bool(data.get("connected", true)):
		return false
	if data.has("occupied") and not bool(data.get("occupied", true)):
		return false
	if bool(data.get("warmup_ai", false)):
		return false
	return str(data.get("player_id", data.get("id", "player"))) != ""

func _add_room_browser_row(room: Dictionary) -> void:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 64)
	row_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.008, 0.010, 0.024, 0.30), Color(0.62, 0.36, 1.0, 0.12), 6, 1))
	_room_browser_list_vbox.add_child(row_panel)
	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 20)
	row_margin.add_theme_constant_override("margin_right", 20)
	row_panel.add_child(row_margin)
	var row_hbox := HBoxContainer.new()
	row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	row_hbox.add_theme_constant_override("separation", 10)
	row_margin.add_child(row_hbox)
	var name_box := VBoxContainer.new()
	name_box.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[0], 0)
	name_box.add_theme_constant_override("separation", 2)
	row_hbox.add_child(name_box)
	var name_lbl := Label.new()
	name_lbl.text = str(room.get("table_name", _t("replay.public_table")))
	HomeTheme.make_font_settings(name_lbl, 15, Color(1, 1, 1, 0.95))
	name_box.add_child(name_lbl)
	var public_badge := Label.new()
	public_badge.text = _t("browser.public_badge_host_warmup") if bool(room.get("host_in_local_warmup", false)) else (_t("browser.public_badge_server") if _profile_server_connected else _t("browser.public_badge_local"))
	HomeTheme.make_font_settings(public_badge, 11, HomeTheme.CYAN)
	name_box.add_child(public_badge)
	var blinds_lbl := Label.new()
	blinds_lbl.text = "%d / %d" % [int(room.get("small_blind", 10)), int(room.get("big_blind", 20))]
	blinds_lbl.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[1], 0)
	HomeTheme.make_font_settings(blinds_lbl, 14, Color(0.85, 0.90, 1.0))
	row_hbox.add_child(blinds_lbl)
	var players_lbl := Label.new()
	players_lbl.text = "%d / %d" % [int(room.get("seated_count", 0)), int(room.get("max_players", 6))]
	players_lbl.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[2], 0)
	HomeTheme.make_font_settings(players_lbl, 14, Color(0.85, 0.90, 1.0))
	row_hbox.add_child(players_lbl)
	var buyin_lbl := Label.new()
	buyin_lbl.text = _tf("common.chips_amount", {"amount": _format_number(int(room.get("buy_in", 1000)))})
	buyin_lbl.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[3], 0)
	HomeTheme.make_font_settings(buyin_lbl, 14, Color(0.85, 0.90, 1.0))
	row_hbox.add_child(buyin_lbl)
	var btn_container := CenterContainer.new()
	btn_container.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[4], 0)
	row_hbox.add_child(btn_container)
	var join_btn := Button.new()
	join_btn.text = _t("browser.join").to_upper()
	join_btn.custom_minimum_size = Vector2(100, 36)
	join_btn.focus_mode = Control.FOCUS_NONE
	join_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style_normal := HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 18)
	style_normal.shadow_color = Color(1.0, 0.0, 0.5, 0.25)
	style_normal.shadow_size = 6
	var style_hover := HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.80), Color(1.0, 0.0, 0.5, 1.0), 18)
	style_hover.shadow_color = Color(1.0, 0.0, 0.5, 0.60)
	style_hover.shadow_size = 14
	join_btn.add_theme_stylebox_override("normal", style_normal)
	join_btn.add_theme_stylebox_override("hover", style_hover)
	join_btn.add_theme_stylebox_override("pressed", style_hover)
	join_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	join_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	join_btn.add_theme_font_size_override("font_size", 13)
	join_btn.disabled = str(room.get("status", "")) == "full"
	var r_id := str(room.get("room_id", ""))
	join_btn.pressed.connect(func() -> void: _on_join_pressed(r_id))
	btn_container.add_child(join_btn)

func _build_friends_room_panel() -> void:
	_friends_room_panel = PanelContainer.new()
	_friends_room_panel.name = "LocalMockRoomLobby"
	_friends_room_panel.anchor_left = 0.0
	_friends_room_panel.anchor_top = 0.32
	_friends_room_panel.anchor_right = 1.0
	_friends_room_panel.anchor_bottom = 0.91
	_friends_room_panel.offset_left = MAIN_LEFT
	_friends_room_panel.offset_right = -MAIN_RIGHT
	_friends_room_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_friends_room_panel.custom_minimum_size = Vector2(0, 580)
	_friends_room_panel.visible = false
	_friends_room_panel.modulate.a = 0.0
	_friends_room_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(0.62, 0.36, 1.0, 0.28), 8, 1))
	_lobby_ui_root.add_child(_friends_room_panel)

	var content := VBoxContainer.new()
	content.name = "FriendsRoomContent"
	content.add_theme_constant_override("separation", 18)
	_friends_room_panel.add_child(content)

	var title := Label.new()
	title.text = _t("friends.title")
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	content.add_child(title)

	var sub := Label.new()
	sub.text = _t("friends.subtitle")
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	content.add_child(sub)
	var room_note := Label.new()
	room_note.text = _t("friends.note")
	HomeTheme.make_font_settings(room_note, 12, Color(0.72, 0.78, 0.94, 0.92))
	content.add_child(room_note)

	var room_card := PanelContainer.new()
	room_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	content.add_child(room_card)

	var room_box := VBoxContainer.new()
	room_box.add_theme_constant_override("separation", 12)
	room_card.add_child(room_box)

	_friends_room_id_label = _room_lobby_label(_tf("friends.room_code_value", {"code": "-"}), 17, Color(1.0, 0.92, 0.72, 0.96))
	_friends_room_seats_label = _room_lobby_label(_tf("friends.seats_value", {"count": "-", "max": "9"}), 15, Color(0.88, 0.92, 1.0, 0.92))
	_friends_room_ready_label = _room_lobby_label(_tf("friends.ready_value", {"status": "-"}), 15, HomeTheme.PURPLE)
	room_box.add_child(_room_lobby_label(_t("friends.private_casual_room"), 13, HomeTheme.CYAN))
	room_box.add_child(_friends_room_id_label)
	room_box.add_child(_friends_room_seats_label)
	room_box.add_child(_friends_room_ready_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	room_box.add_child(button_row)

	var start_button := Button.new()
	start_button.text = _t("friends.create_private_room")
	start_button.custom_minimum_size = Vector2(190, 42)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_button.add_theme_font_size_override("font_size", 13)
	start_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	start_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 21))
	start_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.82), Color(1.0, 0.0, 0.5, 1.0), 21))
	start_button.pressed.connect(_show_private_room_setup)
	button_row.add_child(start_button)

	var join_section := VBoxContainer.new()
	join_section.add_theme_constant_override("separation", 8)
	room_box.add_child(join_section)

	var join_title := _room_lobby_label(_t("friends.join_private_room"), 14, HomeTheme.TEXT)
	join_section.add_child(join_title)
	var join_hint := _room_lobby_label(_t("friends.join_hint"), 12, HomeTheme.MUTED)
	join_section.add_child(join_hint)
	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 10)
	join_section.add_child(join_row)

	_friends_room_code_input = LineEdit.new()
	_friends_room_code_input.name = "PrivateRoomCodeInput"
	_friends_room_code_input.placeholder_text = _t("friends.enter_room_code")
	_friends_room_code_input.custom_minimum_size = Vector2(220, 42)
	_friends_room_code_input.max_length = 12
	_friends_room_code_input.text_submitted.connect(func(_text: String) -> void: _join_private_room_by_code())
	join_row.add_child(_friends_room_code_input)

	var join_button := Button.new()
	join_button.text = _t("friends.join_room")
	join_button.custom_minimum_size = Vector2(150, 42)
	join_button.focus_mode = Control.FOCUS_NONE
	join_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	join_button.add_theme_font_size_override("font_size", 13)
	join_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	join_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 21))
	join_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.82), Color(1.0, 0.0, 0.5, 1.0), 21))
	join_button.pressed.connect(_join_private_room_by_code)
	join_row.add_child(join_button)

	var back_button := Button.new()
	back_button.text = _t("common.back").to_upper()
	back_button.custom_minimum_size = Vector2(110, 42)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.add_theme_font_size_override("font_size", 13)
	back_button.add_theme_color_override("font_color", Color(0.86, 0.88, 1.0, 0.92))
	back_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.58), Color(0.36, 0.42, 0.7, 0.18), 21))
	back_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.035, 0.04, 0.085, 0.82), Color(0.78, 0.58, 1.0, 0.55), 21))
	back_button.pressed.connect(func() -> void: set_state(LobbyState.PLAY_EXPANDED))
	button_row.add_child(back_button)

func _room_lobby_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	HomeTheme.make_font_settings(label, font_size, color)
	return label

func _update_friends_room_panel() -> void:
	if _friends_room_id_label == null:
		return
	var seats: Array = Array(_friends_room_context.get("seats", []))
	var occupied := 0
	for seat in seats:
		if str(Dictionary(seat).get("status", "")) != "empty":
			occupied += 1
	var room_code := str(_friends_room_context.get("room_code", _friends_room_context.get("room_id", "-")))
	if room_code == "":
		room_code = "-"
	_friends_room_id_label.text = _tf("friends.room_code_value", {"code": room_code})
	_friends_room_seats_label.text = _tf("friends.seats_value", {"count": occupied, "max": 9})
	_friends_room_ready_label.text = _tf("friends.ready_value", {"status": _t("friends.ready_hint_table") if occupied > 0 else _t("friends.ready_hint_lobby")})

func _build_replay_panel() -> void:
	_replay_economy_signature = JSON.stringify(Dictionary(_player_profile.get(\
	_replay_panel = PanelContainer.new()
	_replay_panel.name = "ReplayPanel"
	_replay_panel.anchor_left = 0.0
	_replay_panel.anchor_top = 0.32
	_replay_panel.anchor_right = 1.0
	_replay_panel.anchor_bottom = 0.91
	_replay_panel.offset_left = MAIN_LEFT
	_replay_panel.offset_right = -MAIN_RIGHT
	_replay_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_replay_panel.custom_minimum_size = Vector2(0, 580)
	_replay_panel.visible = false
	_replay_panel.modulate.a = 0.0
	_replay_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(1.0, 0.28, 0.78, 0.28), 8, 1))
	_lobby_ui_root.add_child(_replay_panel)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 15)
	_replay_panel.add_child(main_vbox)
	
	# Header
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(header)
	
	var title_box := VBoxContainer.new()
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title_box)
	
	var title := Label.new()
	title.text = _t("replay.room_title")
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	
	var sub := Label.new()
	sub.text = _t("replay.room_subtitle")
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	
	_replay_content_hbox = HBoxContainer.new()
	_replay_content_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_replay_content_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(_replay_content_hbox)
	
	# Left: Hand list
	_replay_list_panel = PanelContainer.new()
	_replay_list_panel.custom_minimum_size = Vector2(400, 0)
	_replay_list_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_replay_list_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	_replay_content_hbox.add_child(_replay_list_panel)
	
	var list_scroll := ScrollContainer.new()
	list_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_replay_list_panel.add_child(list_scroll)
	
	var list_vbox := VBoxContainer.new()
	list_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	list_scroll.add_child(list_vbox)
	
	var replay_view: Dictionary = ReplayServiceScript.new().get_replay_view_model(Dictionary(_player_profile.get("replay_economy", {})))
	var replay_records: Array = Array(replay_view.get("records", []))
	_replay_list_lock_labels.clear()
	
	if replay_records.is_empty():
		var empty_label := Label.new()
		empty_label.text = _t("replay.no_hands")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.custom_minimum_size = Vector2(0, 160)
		HomeTheme.make_font_settings(empty_label, 14, HomeTheme.MUTED)
		list_vbox.add_child(empty_label)

	for hand_item in replay_records:
		var hand: Dictionary = Dictionary(hand_item)
		var preview_record: Dictionary = _load_replay_record_preview(hand)
		var replay_id: String = _replay_id_for_record(preview_record, hand)
		var unlocked: bool = _is_replay_unlocked(preview_record, hand)
		var item := PanelContainer.new()
		item.custom_minimum_size = Vector2(0, 112)
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.tooltip_text = _t("replay.open_static_review")
		item.gui_input.connect(_on_replay_item_gui_input.bind(hand))
		item.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.016, 0.035, 0.65), Color(0.3, 0.35, 0.55, 0.15), 6, 1))
		var item_hbox := HBoxContainer.new()
		item_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		item_hbox.add_theme_constant_override("separation", 10)
		item.add_child(item_hbox)
		
		item_hbox.add_child(_make_replay_dealer_thumbnail(hand, preview_record))
		
		var desc_vbox := VBoxContainer.new()
		desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_hbox.add_child(desc_vbox)
		
		var item_title := Label.new()
		item_title.text = _replay_list_title(hand, preview_record)
		HomeTheme.make_font_settings(item_title, 13, Color(0.9, 0.92, 0.98))
		desc_vbox.add_child(item_title)
		
		var item_time := Label.new()
		item_time.text = _replay_list_stakes_line(hand, preview_record)
		HomeTheme.make_font_settings(item_time, 11, HomeTheme.MUTED)
		desc_vbox.add_child(item_time)

		var item_summary := Label.new()
		item_summary.text = _replay_list_result_line(hand, preview_record)
		item_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		HomeTheme.make_font_settings(item_summary, 11, Color(0.70, 0.74, 0.92, 0.88))
		desc_vbox.add_child(item_summary)

		var item_played_at := Label.new()
		item_played_at.text = _replay_list_time_label(hand)
		item_played_at.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		HomeTheme.make_font_settings(item_played_at, 10, HomeTheme.MUTED)
		desc_vbox.add_child(item_played_at)

		var lock_label := Label.new()
		lock_label.text = _t("replay.unlocked").to_upper() if unlocked else _t("replay.locked").to_upper()
		HomeTheme.make_font_settings(lock_label, 10, HomeTheme.CYAN if unlocked else HomeTheme.GOLD)
		desc_vbox.add_child(lock_label)
		var economy_label := Label.new()
		var replay_type := str(hand.get("replay_type", ReplayRepositoryScript.replay_type_for_record(preview_record)))
		var price_gems := int(hand.get("price_gems", _replay_price_gems(preview_record, hand)))
		economy_label.text = "%s | %s" % [_replay_type_label(replay_type), "%d Gems" % price_gems if price_gems >= 0 else "Price unavailable"]
		HomeTheme.make_font_settings(economy_label, 10, HomeTheme.MUTED)
		desc_vbox.add_child(economy_label)
		if replay_id != "":
			_replay_list_lock_labels[replay_id] = lock_label
		
		var item_res := Label.new()
		var net_chips: int = _replay_profit_value(hand)
		item_res.text = _replay_profit_label(hand, preview_record)
		HomeTheme.make_font_settings(item_res, 13, Color(0.2, 0.8, 0.3) if net_chips >= 0 else HomeTheme.PINK)
		item_hbox.add_child(item_res)
		
		list_vbox.add_child(item)
		
	# Right: Hand Preview & Premium Lock Module
	var right_vbox := VBoxContainer.new()
	right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 16)
	_replay_content_hbox.add_child(right_vbox)
	
	# Preview Box
	var prev_box := PanelContainer.new()
	prev_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_box.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	var detail_scroll := ScrollContainer.new()
	detail_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_box.add_child(detail_scroll)
	_replay_detail_vbox = VBoxContainer.new()
	_replay_detail_vbox.add_theme_constant_override("separation", 12)
	_replay_detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_replay_detail_vbox)
	right_vbox.add_child(prev_box)
	_render_replay_detail_empty(not replay_records.is_empty())
	
	_replay_equity_box = null


func _on_replay_item_gui_input(event: InputEvent, hand: Dictionary) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_open_replay_detail(hand)


func _open_replay_detail(hand: Dictionary) -> void:
	_stop_replay_playback()
	var file_path: String = str(hand.get("file_path", ""))
	if file_path == "" or not FileAccess.file_exists(file_path):
		_render_replay_detail_error(_t("replay.file_missing"))
		return
	var record: Dictionary = ReplayServiceScript.new().load_replay_record(file_path)
	if record.is_empty():
		_render_replay_detail_error(_t("replay.file_missing"))
		return
	_replay_current_record = record.duplicate(true)
	_replay_current_index_entry = hand.duplicate(true)
	_render_replay_detail(record, hand)


func _render_replay_detail_empty(has_records: bool) -> void:
	_stop_replay_playback()
	_hide_replay_fullscreen_overlay()
	_set_replay_playback_layout(false)
	_replay_current_record = {}
	_replay_current_index_entry = {}
	_clear_replay_detail()
	var title := Label.new()
	title.text = _t("replay.hand_records")
	HomeTheme.make_font_settings(title, 16, HomeTheme.CYAN)
	_replay_detail_vbox.add_child(title)
	var body := Label.new()
	body.text = _t("replay.select_hand") if has_records else _t("replay.no_hands")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(body, 13, Color(0.72, 0.76, 0.92))
	_replay_detail_vbox.add_child(body)


func _render_replay_detail_error(message: String) -> void:
	_stop_replay_playback()
	_hide_replay_fullscreen_overlay()
	_set_replay_playback_layout(false)
	_clear_replay_detail()
	var title := Label.new()
	title.text = _tf("replay.hand_review", {"hand_id": ""}).strip_edges()
	HomeTheme.make_font_settings(title, 16, HomeTheme.CYAN)
	_replay_detail_vbox.add_child(title)
	var error_label := Label.new()
	error_label.text = message
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(error_label, 14, HomeTheme.PINK)
	_replay_detail_vbox.add_child(error_label)


func _render_replay_detail(record: Dictionary, index_entry: Dictionary) -> void:
	_hide_replay_fullscreen_overlay()
	_set_replay_playback_layout(false)
	_clear_replay_detail()
	var hand_id: String = str(record.get("hand_id", index_entry.get("replay_id", "Unknown")))
	var replay_id: String = _replay_id_for_record(record, index_entry)
	var replay_unlocked: bool = _is_replay_unlocked(record, index_entry)
	var replay_price_gems := _replay_price_gems(record, index_entry)
	var results: Dictionary = Dictionary(record.get("results", {}))
	var players: Array = Array(record.get("players", []))
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	_replay_detail_vbox.add_child(header)
	var title := Label.new()
	title.text = _tf("replay.hand_review", {"hand_id": hand_id})
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HomeTheme.make_font_settings(title, 16, HomeTheme.CYAN)
	header.add_child(title)

	if replay_unlocked:
		var play_button := _make_replay_primary_button(_t("replay.play_replay"), HomeTheme.CYAN)
		play_button.pressed.connect(_open_replay_playback.bind(record, index_entry))
		header.add_child(play_button)
	else:
		var unlock_button := _make_replay_primary_button(_tf("replay.unlock_button", {"cost": replay_price_gems}) if replay_price_gems >= 0 else _t("replay.unlock_replay"), HomeTheme.GOLD)
		unlock_button.disabled = replay_price_gems < 0
		unlock_button.pressed.connect(_unlock_replay_from_detail.bind(record, index_entry))
		header.add_child(unlock_button)

	var unlock_hint := Label.new()
	unlock_hint.text = _t("replay.unlock_hint_unlocked") if replay_unlocked else (_tf("replay.unlock_hint_locked", {"cost": replay_price_gems}) if replay_price_gems >= 0 else _t("replay.unlock_failed"))
	unlock_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(unlock_hint, 12, HomeTheme.MUTED)
	_replay_detail_vbox.add_child(unlock_hint)

	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 16)
	_replay_detail_vbox.add_child(body_hbox)

	var players_box := _make_replay_section(_t("replay.players").to_upper(), Vector2(260, 0))
	body_hbox.add_child(players_box)
	var players_vbox: VBoxContainer = players_box.get_node("Content") as VBoxContainer
	_add_replay_players(players_vbox, players)

	var board_box := _make_replay_section(_t("replay.board_result").to_upper(), Vector2(230, 0))
	body_hbox.add_child(board_box)
	var board_vbox: VBoxContainer = board_box.get_node("Content") as VBoxContainer
	_add_replay_board_and_results(board_vbox, record)

	var actions_box := _make_replay_section(_t("replay.action_timeline").to_upper(), Vector2(360, 0))
	actions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_hbox.add_child(actions_box)
	var actions_vbox: VBoxContainer = actions_box.get_node("Content") as VBoxContainer
	_add_replay_actions(actions_vbox, Array(record.get("actions", [])), players)


func _clear_replay_detail() -> void:
	if _replay_detail_vbox == null:
		return
	for child in _replay_detail_vbox.get_children():
		_replay_detail_vbox.remove_child(child)
		child.queue_free()


func _make_replay_primary_button(text: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(210, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.032, 0.056, 0.74), accent.darkened(0.20), 18))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.035, 0.045, 0.088, 0.88), accent, 18))
	button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
	return button

func _replay_id_for_record(record: Dictionary, index_entry: Dictionary = {}) -> String:
	var explicit_replay_id := str(record.get("replay_id", index_entry.get("replay_id", ""))).strip_edges()
	if explicit_replay_id != "":
		return explicit_replay_id
	var hand_id := str(record.get("hand_id", index_entry.get("hand_id", index_entry.get("replay_id", "")))).strip_edges()
	var room_id := str(record.get("room_id", index_entry.get("room_id", ""))).strip_edges()
	if hand_id != "" and room_id != "":
		return "%s:%s" % [hand_id, room_id]
	if hand_id != "":
		return hand_id
	return str(index_entry.get("file_path", "")).strip_edges()

func _is_official_encrypted_replay(record: Dictionary, index_entry: Dictionary = {}) -> bool:
	return ReplayRepositoryScript.is_official_encrypted_record(record) or ReplayRepositoryScript.is_official_encrypted_entry(index_entry)

func _is_replay_unlocked(record: Dictionary, index_entry: Dictionary = {}) -> bool:
	var cache_source := record if not record.is_empty() else index_entry
	if ReplayRepositoryScript.has_unlock_cache(cache_source):
		return true
	var identity := IdentityServiceScript.new().get_identity(_player_profile)
	if not OS.is_debug_build() or str(identity.get("provider", "")) != "local_dev":
		return false
	var replay_id := _replay_id_for_record(record, index_entry)
	return ProfileServiceScript.new().is_replay_unlocked(replay_id)

func _replay_type(record: Dictionary, index_entry: Dictionary = {}) -> String:
	var explicit_type := str(record.get("replay_type", index_entry.get("replay_type", "")))
	if explicit_type != "":
		return explicit_type
	return ReplayRepositoryScript.replay_type_for_record(record if not record.is_empty() else index_entry)

func _replay_price_gems(record: Dictionary, index_entry: Dictionary = {}) -> int:
	return PlayerProfileScript.replay_price_gems(_player_profile, _replay_type(record, index_entry))

func _replay_type_label(replay_type: String) -> String:
	match replay_type:
		"official_human":
			return "Official Human"
		"room_replay":
			return "Room Replay"
		"ai":
			return "AI Replay"
		"training":
			return "Training Replay"
	return "Replay"

func _unlock_replay_from_detail(record: Dictionary, index_entry: Dictionary) -> void:
	var replay_id := _replay_id_for_record(record, index_entry)
	var replay_type := _replay_type(record, index_entry)
	var replay_price_gems := _replay_price_gems(record, index_entry)
	if replay_id == "" or replay_price_gems < 0:
		_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	if _profile_ws_client != null and _profile_server_connected:
		_pending_replay_unlock_record = record.duplicate(true)
		_pending_replay_unlock_index_entry = index_entry.duplicate(true)
		var err := _profile_ws_client.unlock_replay(replay_id, replay_type)
		if err != OK:
			_pending_replay_unlock_record = {}
			_pending_replay_unlock_index_entry = {}
			_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	var identity := IdentityServiceScript.new().get_identity(_player_profile)
	if not OS.is_debug_build() or str(identity.get("provider", "")) != "local_dev" or replay_type not in ["ai", "training"]:
		_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	var result: Dictionary = ProfileServiceScript.new().unlock_replay(replay_id, replay_price_gems)
	if not bool(result.get("success", false)):
		if str(result.get("reason", "")) == "not_enough_gems":
			_show_toast(_t("replay.not_enough_gems"), [], 3.0)
		else:
			_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	_player_profile = Dictionary(result.get("profile", ProfileServiceScript.new().get_current_profile()))
	ReplayRepositoryScript.save_local_unlock_cache(record, replay_type, replay_price_gems, "local_mock")
	SfxManagerScript.play_gem(self, "replay_unlock:%s" % replay_id)
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()
	_update_replay_list_lock_label(replay_id, true)
	_show_toast(_tf("replay.unlock_success", {"cost": _format_number(replay_price_gems)}), [], 2.6)
	_render_replay_detail(record, index_entry)

func _on_replay_server_unlocked(replay_id: String, replay_type: String, price_gems: int, replay_key: String, key_version: int, checksum: String, already_unlocked: bool, wallet: Dictionary, profile_snapshot: Dictionary) -> void:
	if replay_id == "":
		_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	var record: Dictionary = _pending_replay_unlock_record.duplicate(true)
	var index_entry: Dictionary = _pending_replay_unlock_index_entry.duplicate(true)
	if record.is_empty() or _replay_id_for_record(record, index_entry) != replay_id:
		record = _replay_current_record.duplicate(true)
		index_entry = _replay_current_index_entry.duplicate(true)
	if record.is_empty() or _replay_id_for_record(record, index_entry) != replay_id:
		_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	if checksum != "":
		record["checksum"] = checksum
		index_entry["checksum"] = checksum
	if key_version > 0:
		record["key_version"] = key_version
		index_entry["key_version"] = key_version
	var full_record: Dictionary = record.duplicate(true)
	if _is_official_encrypted_replay(record, index_entry):
		full_record = ReplayRepositoryScript.load_unlocked_encrypted_record(record, replay_key)
		if full_record.has("error"):
			_show_toast(_replay_unlock_error_text(str(full_record.get("error", ""))), [], 3.0)
			return
		if full_record.is_empty() or not ReplayRepositoryScript.save_unlock_cache(record, replay_key, key_version, checksum):
			_show_toast(_t("replay.unlock_failed"), [], 2.4)
			return
	elif not ReplayRepositoryScript.save_local_unlock_cache(record, replay_type, price_gems):
		_show_toast(_t("replay.unlock_failed"), [], 2.4)
		return
	if not profile_snapshot.is_empty():
		_player_profile = ProfileServiceScript.new().apply_server_profile_snapshot(profile_snapshot, wallet)
		_refresh_profile_views_from_server()
	elif not wallet.is_empty():
		_player_profile = ProfileServiceScript.new().apply_wallet_snapshot(wallet)
		_refresh_profile_views_from_server()
	if not already_unlocked:
		SfxManagerScript.play_gem(self, "replay_unlock:%s" % replay_id)
	_update_replay_list_lock_label(replay_id, true)
	_pending_replay_unlock_record = {}
	_pending_replay_unlock_index_entry = {}
	_replay_current_record = full_record.duplicate(true)
	_replay_current_index_entry = index_entry.duplicate(true)
	_show_toast(_t("replay.unlock_hint_unlocked"), [], 2.4)
	_open_replay_playback(full_record, index_entry)

func _replay_unlock_error_text(reason: String) -> String:
	match reason:
		"missing_private_blob":
			return "Replay file missing."
		"replay_checksum_mismatch":
			return "Replay checksum mismatch."
		"replay_decrypt_failed":
			return _t("replay.unlock_failed")
		_:
			return _server_lobby_error_text(reason)

func _update_replay_list_lock_label(replay_id: String, unlocked: bool) -> void:
	if replay_id == "" or not _replay_list_lock_labels.has(replay_id):
		return
	var label: Label = _replay_list_lock_labels.get(replay_id, null) as Label
	if label == null:
		return
	label.text = _t("replay.unlocked").to_upper() if unlocked else _t("replay.locked").to_upper()
	HomeTheme.make_font_settings(label, 10, HomeTheme.CYAN if unlocked else HomeTheme.GOLD)


func _open_replay_playback(record: Dictionary, index_entry: Dictionary) -> void:
	if not _is_replay_unlocked(record, index_entry):
		_show_toast(_t("replay.unlock_first"), [], 2.4)
		return
	var playback_record: Dictionary = record.duplicate(true)
	if _is_official_encrypted_replay(record, index_entry):
		playback_record = ReplayRepositoryScript.load_unlocked_encrypted_record(record)
		if playback_record.has("error"):
			_show_toast(_replay_unlock_error_text(str(playback_record.get("error", ""))), [], 3.0)
			return
		if playback_record.is_empty():
			_show_toast(_t("replay.unlock_failed"), [], 2.4)
			return
	_stop_replay_playback()
	_replay_playback_record = playback_record.duplicate(true)
	_replay_playback_index_entry = index_entry.duplicate(true)
	_replay_playback_actions = _sorted_replay_actions(Array(playback_record.get("actions", [])))
	_replay_playback_steps = _build_replay_playback_steps(playback_record)
	_replay_playback_step = 0
	_replay_playback_speed = 1.0
	_render_replay_playback()
	SfxManagerScript.play_shuffle(self, "replay:%s:shuffle" % _replay_id_for_record(playback_record, index_entry))


func _render_replay_playback() -> void:
	_set_replay_playback_layout(true)
	_show_replay_fullscreen_overlay()
	_replace_replay_children(_replay_fullscreen_overlay)
	_replay_poker_table_screen = ReplayPokerTableScreenScene.instantiate() as Control
	_replay_poker_table_screen.name = "ReplayPokerTableScreen"
	_replay_poker_table_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replay_poker_table_screen.connect("back_to_detail_requested", Callable(self, "_return_to_replay_detail"))
	_replay_poker_table_screen.connect("back_to_replays_requested", Callable(self, "_return_to_replay_list_from_playback"))
	_replay_poker_table_screen.connect("previous_step_requested", Callable(self, "_replay_playback_prev"))
	_replay_poker_table_screen.connect("next_step_requested", Callable(self, "_replay_playback_next"))
	_replay_poker_table_screen.connect("playback_toggle_requested", Callable(self, "_toggle_replay_playback"))
	_replay_poker_table_screen.connect("speed_toggle_requested", Callable(self, "_toggle_replay_playback_speed"))
	_replay_poker_table_screen.connect("timeline_toggle_requested", Callable(self, "_toggle_replay_fullscreen_timeline"))
	_replay_fullscreen_overlay.add_child(_replay_poker_table_screen)
	if _replay_poker_table_screen.has_method("set_replay_context"):
		_replay_poker_table_screen.call("set_replay_context", _replay_playback_record, _replay_playback_index_entry, _steps_with_timeline_text(_replay_playback_steps))
	_refresh_replay_playback_view()


func _set_replay_playback_layout(enabled: bool) -> void:
	if _replay_list_panel != null:
		_replay_list_panel.visible = not enabled
	if _replay_equity_box != null:
		_replay_equity_box.visible = not enabled
	if _replay_content_hbox != null:
		_replay_content_hbox.add_theme_constant_override("separation", 0 if enabled else 24)


func _ensure_replay_fullscreen_overlay() -> void:
	if _replay_fullscreen_overlay != null:
		return
	_replay_fullscreen_overlay = Control.new()
	_replay_fullscreen_overlay.name = "ReplayFullscreenOverlay"
	_replay_fullscreen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replay_fullscreen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_replay_fullscreen_overlay.visible = false
	_replay_fullscreen_overlay.z_index = 500
	add_child(_replay_fullscreen_overlay)


func _show_replay_fullscreen_overlay() -> void:
	_ensure_replay_fullscreen_overlay()
	MusicServiceScript.play_table_bgm(self)
	_replay_fullscreen_overlay.visible = true
	_replay_fullscreen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replay_fullscreen_overlay.move_to_front()
	if _replay_panel != null:
		_replay_panel.visible = false
	if _center_brand != null:
		_center_brand.visible = false
	if _prompt != null:
		_prompt.visible = false
	if _cta_button != null:
		_cta_button.visible = false


func _hide_replay_fullscreen_overlay() -> void:
	if _replay_fullscreen_overlay != null:
		_replay_fullscreen_overlay.visible = false
		_replace_replay_children(_replay_fullscreen_overlay)
	_replay_poker_table_screen = null
	MusicServiceScript.play_home_bgm(self)
	if current_state == LobbyState.REPLAY and _replay_panel != null:
		_replay_panel.visible = true
	if _center_brand != null and current_state != LobbyState.COLLAPSED:
		_center_brand.visible = true


func _toggle_replay_fullscreen_timeline() -> void:
	_replay_fullscreen_timeline_visible = not _replay_fullscreen_timeline_visible
	if _replay_poker_table_screen != null and _replay_poker_table_screen.has_method("set_timeline_visible"):
		_replay_poker_table_screen.call("set_timeline_visible", _replay_fullscreen_timeline_visible)
	_apply_replay_fullscreen_layout()
	_refresh_replay_playback_view()


func _apply_replay_fullscreen_layout() -> void:
	var timeline_width := 350.0 if _replay_fullscreen_timeline_visible else 0.0
	if _replay_fullscreen_timeline_panel != null:
		_replay_fullscreen_timeline_panel.visible = _replay_fullscreen_timeline_visible
	if _replay_timeline_toggle_button != null:
		_replay_timeline_toggle_button.text = "HIDE TIMELINE" if _replay_fullscreen_timeline_visible else "SHOW TIMELINE"
	if _replay_playback_table_layer != null:
		_replay_playback_table_layer.anchor_left = 0.0
		_replay_playback_table_layer.anchor_top = 0.12
		_replay_playback_table_layer.anchor_right = 1.0
		_replay_playback_table_layer.anchor_bottom = 0.88
		_replay_playback_table_layer.offset_left = 0
		_replay_playback_table_layer.offset_top = 0
		_replay_playback_table_layer.offset_right = -timeline_width
		_replay_playback_table_layer.offset_bottom = 0


func _make_replay_value_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(label, 12, color)
	return label


func _make_replay_control_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(126, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.66), Color(0.52, 0.78, 1.0, 0.34), 18))
	button.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 0.94))
	return button


func _return_to_replay_detail() -> void:
	_stop_replay_playback()
	_hide_replay_fullscreen_overlay()
	if _replay_current_record.is_empty():
		_render_replay_detail_empty(true)
		return
	_render_replay_detail(_replay_current_record, _replay_current_index_entry)


func _return_to_replay_list_from_playback() -> void:
	_stop_replay_playback()
	_hide_replay_fullscreen_overlay()
	_render_replay_detail_empty(true)


func _replay_playback_prev() -> void:
	_stop_replay_playback()
	_replay_playback_step = max(0, _replay_playback_step - 1)
	_refresh_replay_playback_view()


func _replay_playback_next() -> void:
	if _replay_playback_step >= _replay_playback_steps.size():
		_stop_replay_playback()
		return
	_replay_playback_step += 1
	_refresh_replay_playback_view()
	if _replay_playback_step >= _replay_playback_steps.size():
		_stop_replay_playback()


func _toggle_replay_playback() -> void:
	if _replay_playback_is_playing:
		_stop_replay_playback()
		return
	if _replay_playback_step >= _replay_playback_steps.size():
		_replay_playback_step = 0
		_refresh_replay_playback_view()
	_ensure_replay_playback_timer()
	_replay_playback_is_playing = true
	if _replay_playback_play_button != null:
		_replay_playback_play_button.text = _t("replay.pause").to_upper()
	_replay_playback_timer.wait_time = 0.8 / _replay_playback_speed
	_replay_playback_timer.start()
	if _replay_poker_table_screen != null:
		_refresh_replay_playback_view()


func _toggle_replay_playback_speed() -> void:
	_replay_playback_speed = 2.0 if _replay_playback_speed == 1.0 else 1.0
	if _replay_playback_speed_button != null:
		_replay_playback_speed_button.text = _tf("replay.speed", {"speed": int(_replay_playback_speed)})
	if _replay_playback_is_playing and _replay_playback_timer != null:
		_replay_playback_timer.wait_time = 0.8 / _replay_playback_speed
		_replay_playback_timer.start()
	if _replay_poker_table_screen != null:
		_refresh_replay_playback_view()


func _ensure_replay_playback_timer() -> void:
	if _replay_playback_timer != null:
		return
	_replay_playback_timer = Timer.new()
	_replay_playback_timer.one_shot = false
	_replay_playback_timer.timeout.connect(_on_replay_playback_timer_timeout)
	add_child(_replay_playback_timer)


func _on_replay_playback_timer_timeout() -> void:
	_replay_playback_next()


func _stop_replay_playback() -> void:
	_replay_playback_is_playing = false
	if _replay_playback_timer != null:
		_replay_playback_timer.stop()
	if _replay_playback_play_button != null:
		_replay_playback_play_button.text = _t("replay.play").to_upper()
	if _replay_poker_table_screen != null:
		_refresh_replay_playback_view()


func _refresh_replay_playback_view() -> void:
	var playback_state: Dictionary = _replay_playback_state_for_step(_replay_playback_record, _replay_playback_step)
	var players: Array = Array(playback_state.get("players", []))
	_play_replay_step_sfx(playback_state)
	if _replay_poker_table_screen != null and _replay_poker_table_screen.has_method("render_replay_state"):
		_replay_poker_table_screen.call(
			"render_replay_state",
			playback_state,
			_replay_playback_step,
			_replay_playback_steps.size(),
			_replay_playback_is_playing,
			_replay_playback_speed
		)
		return
	if _replay_playback_step_label != null:
		_replay_playback_step_label.text = "%s\nStep %d / %d\n%s" % [
			_replay_playback_header_line(_replay_playback_record),
			_replay_playback_step,
			_replay_playback_steps.size(),
			str(playback_state.get("action_text", "Initial state")),
		]
	if _replay_playback_board_label != null:
		_replay_playback_board_label.text = "BOARD\n%s" % str(playback_state.get("board_text", "-"))
	if _replay_playback_pot_label != null:
		_replay_playback_pot_label.text = "POT\n%s" % _format_number(int(playback_state.get("pot", 0)))
	if _replay_playback_action_label != null:
		_replay_playback_action_label.text = "CURRENT STEP\n%s" % str(playback_state.get("action_text", "Initial state"))

	_render_replay_table_view(playback_state, players)
	_render_replay_playback_timeline()

func _play_replay_step_sfx(_playback_state: Dictionary) -> void:
	if _replay_playback_step <= 0:
		return
	var step_index := _replay_playback_step - 1
	if step_index < 0 or step_index >= _replay_playback_steps.size():
		return
	var step: Dictionary = Dictionary(_replay_playback_steps[step_index])
	var replay_id := _replay_id_for_record(_replay_playback_record, _replay_playback_index_entry)
	var event_key := "replay:%s:step:%d" % [replay_id, step_index]
	if str(step.get("kind", "")) == "action":
		var action: Dictionary = Dictionary(step.get("action", {}))
		var action_name := str(action.get("action", ""))
		if action_name in ["small_blind", "big_blind", "call", "bet", "raise", "all_in"]:
			SfxManagerScript.play_chip(self, event_key)
		return
	var street := str(step.get("street", ""))
	var label := str(step.get("label", "")).to_lower()
	if street in ["flop", "turn", "river"] or label.find("dealt") != -1:
		SfxManagerScript.play_draw_card(self, event_key)
	elif street in ["hand_over", "showdown"] or label.find("wins") != -1 or label.find("settled") != -1:
		SfxManagerScript.play_win(self, event_key)


func _render_replay_table_view(playback_state: Dictionary, players: Array) -> void:
	if _replay_playback_table_layer == null:
		return
	_replace_replay_children(_replay_playback_table_layer)
	var table_size: Vector2 = _replay_table_view_size()
	var bg := TextureRect.new()
	bg.name = "ReplayTableBackground"
	bg.texture = REPLAY_TABLE_BACKGROUND
	bg.position = Vector2.ZERO
	bg.size = table_size
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_playback_table_layer.add_child(bg)

	var felt_overlay := PanelContainer.new()
	felt_overlay.name = "ReplayTableVisualOverlay"
	felt_overlay.position = Vector2.ZERO
	felt_overlay.custom_minimum_size = table_size
	felt_overlay.size = table_size
	felt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	felt_overlay.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.004, 0.012, 0.22), Color(0.72, 0.30, 1.0, 0.30), 22, 1))
	_replay_playback_table_layer.add_child(felt_overlay)

	var center_panel := PanelContainer.new()
	center_panel.name = "ReplayTableCenter"
	center_panel.custom_minimum_size = Vector2(234, 124)
	center_panel.size = Vector2(234, 124)
	center_panel.position = _replay_design_to_view(Vector2(1280.0, 405.0)) - center_panel.size * 0.5
	center_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.008, 0.010, 0.026, 0.82), Color(0.22, 0.86, 1.0, 0.30), 10, 1))
	_replay_playback_table_layer.add_child(center_panel)
	var center_vbox := VBoxContainer.new()
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 8)
	center_panel.add_child(center_vbox)

	var board_row := HBoxContainer.new()
	board_row.name = "ReplayTableBoardCards"
	board_row.alignment = BoxContainer.ALIGNMENT_CENTER
	board_row.add_theme_constant_override("separation", 6)
	board_row.custom_minimum_size = Vector2(0, 62)
	center_vbox.add_child(board_row)
	_add_replay_board_cards(board_row, Array(playback_state.get("board_cards", [])))

	var pot_label := Label.new()
	pot_label.name = "ReplayTablePot"
	pot_label.text = "TOTAL POT  %s" % _format_number(int(playback_state.get("pot", 0)))
	pot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(pot_label, 16, HomeTheme.GOLD)
	center_vbox.add_child(pot_label)

	var action_label := Label.new()
	action_label.name = "ReplayTableCurrentAction"
	action_label.text = str(playback_state.get("action_text", "Initial state"))
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.custom_minimum_size = Vector2(0, 42)
	HomeTheme.make_font_settings(action_label, 12, HomeTheme.CYAN)
	center_vbox.add_child(action_label)

	if players.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No players recorded."
		empty_label.position = Vector2(250, 275)
		HomeTheme.make_font_settings(empty_label, 13, HomeTheme.MUTED)
		_replay_playback_table_layer.add_child(empty_label)
		return

	var current_actor_seat: int = int(playback_state.get("current_actor_seat", -1))
	var winner_seats: Dictionary = _replay_winner_seats(_replay_playback_record)
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		_add_replay_table_seat_card(_replay_playback_table_layer, player, current_actor_seat, winner_seats)
		_add_replay_table_bet_marker(_replay_playback_table_layer, player)


func _add_replay_board_cards(parent: HBoxContainer, cards: Array) -> void:
	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No board cards recorded."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		HomeTheme.make_font_settings(empty_label, 12, HomeTheme.MUTED)
		parent.add_child(empty_label)
		return
	_add_replay_card_views(parent, cards, Vector2(42, 58), 5)


func _add_replay_card_views(parent: HBoxContainer, cards: Array, card_size: Vector2, max_cards: int) -> void:
	var count: int = mini(cards.size(), max_cards)
	if count <= 0:
		var unknown := Label.new()
		unknown.text = "Unknown"
		HomeTheme.make_font_settings(unknown, 10, HomeTheme.MUTED)
		parent.add_child(unknown)
		return
	for i in range(count):
		var card_data: Dictionary = _replay_card_data(cards[i])
		var card_view: Control = ReplayCardViewScene.instantiate() as Control
		card_view.custom_minimum_size = card_size
		card_view.size = card_size
		card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(card_view)
		card_view.call("set_card", card_data)


func _replay_cards_from_text_or_record(player: Dictionary) -> Array:
	var cards: Array = Array(player.get("hole_cards", []))
	if not cards.is_empty():
		return cards
	var cards_text: String = str(player.get("cards_text", "")).strip_edges()
	if cards_text == "" or cards_text == "Unknown":
		return []
	return cards_text.split(" ", false)


func _replay_card_data(card_value: Variant) -> Dictionary:
	if card_value is Dictionary:
		var card: Dictionary = Dictionary(card_value).duplicate(true)
		if card.has("rank") and card.has("suit"):
			card["face_up"] = true
			return card
		return _replay_card_data(str(card.get("code", "")))
	var code: String = str(card_value).strip_edges()
	code = code.replace("♠", "S").replace("♥", "H").replace("♦", "D").replace("♣", "C")
	code = code.replace("spades", "S").replace("hearts", "H").replace("diamonds", "D").replace("clubs", "C")
	code = code.to_upper()
	if code.length() < 2:
		return {"rank": "", "suit": "", "face_up": false}
	var suit_char: String = code.substr(code.length() - 1, 1)
	var rank_text: String = code.substr(0, code.length() - 1)
	if rank_text == "1":
		rank_text = "A"
	match suit_char:
		"S":
			return {"rank": rank_text, "suit": "spades", "face_up": true}
		"H":
			return {"rank": rank_text, "suit": "hearts", "face_up": true}
		"D":
			return {"rank": rank_text, "suit": "diamonds", "face_up": true}
		"C":
			return {"rank": rank_text, "suit": "clubs", "face_up": true}
	return {"rank": rank_text, "suit": "", "face_up": true}


func _add_replay_table_seat_card(parent: Control, player: Dictionary, current_actor_seat: int, winner_seats: Dictionary) -> void:
	var seat_index: int = int(player.get("seat_index", -1))
	var seat_card := PanelContainer.new()
	seat_card.name = "ReplaySeat%d" % seat_index
	seat_card.position = _replay_table_seat_position(seat_index)
	seat_card.custom_minimum_size = REPLAY_SEAT_CARD_SIZE
	seat_card.size = REPLAY_SEAT_CARD_SIZE
	var status_text: String = str(player.get("status", "active"))
	var is_folded: bool = status_text.to_lower().find("fold") != -1
	var is_active: bool = seat_index == current_actor_seat
	var is_winner: bool = winner_seats.has(seat_index) and _replay_playback_step >= _replay_playback_steps.size()
	var bg_color := Color(0.016, 0.018, 0.046, 0.82)
	var border_color := Color(0.34, 0.52, 0.90, 0.32)
	if is_folded:
		bg_color = Color(0.010, 0.010, 0.018, 0.54)
		border_color = Color(0.42, 0.42, 0.52, 0.24)
	elif is_winner:
		bg_color = Color(0.045, 0.034, 0.010, 0.88)
		border_color = HomeTheme.GOLD
	elif is_active:
		bg_color = Color(0.034, 0.036, 0.082, 0.90)
		border_color = HomeTheme.CYAN
	seat_card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(bg_color, border_color, 8, 2 if is_active or is_winner else 1))
	seat_card.modulate = Color(1, 1, 1, 0.55) if is_folded else Color.WHITE
	parent.add_child(seat_card)

	if is_active:
		var glow := TextureRect.new()
		glow.name = "ReplayActiveTurnGlow"
		glow.texture = REPLAY_ACTIVE_TURN_GLOW
		glow.position = Vector2(18, 60)
		glow.size = Vector2(96, 20)
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seat_card.add_child(glow)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)
	seat_card.add_child(hbox)
	var avatar_box := Control.new()
	avatar_box.custom_minimum_size = Vector2(34, 54)
	hbox.add_child(avatar_box)
	var avatar_ring := TextureRect.new()
	avatar_ring.texture = REPLAY_AVATAR_RING
	avatar_ring.position = Vector2(0, 6)
	avatar_ring.size = Vector2(34, 34)
	avatar_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_box.add_child(avatar_ring)
	var avatar_dot := ColorRect.new()
	avatar_dot.position = Vector2(9, 15)
	avatar_dot.size = Vector2(16, 16)
	avatar_dot.color = Color(0.18, 0.12, 0.30, 0.94)
	avatar_box.add_child(avatar_dot)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	var name_text: String = str(player.get("player_name", player.get("player_id", "Unknown")))
	_add_replay_text(vbox, "Seat %d - %s" % [seat_index, name_text], Color(0.94, 0.96, 1.0, 0.96))
	var cards_row := HBoxContainer.new()
	cards_row.name = "ReplaySeatHoleCards"
	cards_row.add_theme_constant_override("separation", -8)
	vbox.add_child(cards_row)
	_add_replay_card_views(cards_row, _replay_cards_from_text_or_record(player), Vector2(28, 38), 2)
	var stack_row := HBoxContainer.new()
	stack_row.add_theme_constant_override("separation", 3)
	vbox.add_child(stack_row)
	var chip := TextureRect.new()
	chip.texture = REPLAY_CHIP_STACK
	chip.custom_minimum_size = Vector2(18, 16)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack_row.add_child(chip)
	var stack_label := Label.new()
	stack_label.text = _replay_stack_text(player.get("stack", null))
	HomeTheme.make_font_settings(stack_label, 10, HomeTheme.GOLD)
	stack_row.add_child(stack_label)
	var state_label: String = "WINNER" if is_winner else status_text
	_add_replay_text(vbox, "Status: %s" % _title_case_replay_status(state_label), HomeTheme.PINK if is_active else Color(0.78, 0.82, 0.95, 0.92))


func _replay_table_seat_position(seat_index: int) -> Vector2:
	var design_pos: Vector2 = REPLAY_SEAT_PANEL_ORIGINS_BY_SEAT.get(seat_index, REPLAY_SEAT_PANEL_ORIGINS_BY_SEAT[5])
	return _replay_design_to_view(design_pos)


func _add_replay_table_bet_marker(parent: Control, player: Dictionary) -> void:
	var current_bet: int = int(player.get("current_bet", 0))
	if current_bet <= 0:
		return
	var seat_index: int = int(player.get("seat_index", -1))
	var marker := PanelContainer.new()
	marker.name = "ReplayBetMarker%d" % seat_index
	marker.position = _replay_bet_marker_position(seat_index)
	marker.custom_minimum_size = REPLAY_BET_MARKER_SIZE
	marker.size = REPLAY_BET_MARKER_SIZE
	marker.add_theme_stylebox_override("panel", _replay_bet_marker_style())
	parent.add_child(marker)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	marker.add_child(row)
	var chip := TextureRect.new()
	chip.texture = REPLAY_CHIP_STACK
	chip.custom_minimum_size = Vector2(20, 18)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(chip)
	var label := Label.new()
	label.text = _format_number(current_bet)
	HomeTheme.make_font_settings(label, 10, HomeTheme.GOLD)
	row.add_child(label)


func _replay_bet_marker_position(seat_index: int) -> Vector2:
	var design_pos: Vector2 = REPLAY_BET_MARKER_ANCHORS_BY_SEAT.get(seat_index, REPLAY_BET_MARKER_ANCHORS_BY_SEAT[5])
	return _replay_design_to_view(design_pos)


func _replay_design_to_view(design_pos: Vector2) -> Vector2:
	var table_size: Vector2 = _replay_table_view_size()
	var scale := Vector2(table_size.x / REPLAY_TABLE_DESIGN_SIZE.x, table_size.y / REPLAY_TABLE_DESIGN_SIZE.y)
	return Vector2(design_pos.x * scale.x, design_pos.y * scale.y)


func _replay_table_view_size() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var timeline_width := 350.0 if _replay_fullscreen_timeline_visible else 0.0
	if _replay_fullscreen_overlay != null and _replay_fullscreen_overlay.visible:
		return Vector2(maxf(720.0, viewport_size.x - timeline_width), maxf(420.0, viewport_size.y * 0.76))
	return REPLAY_TABLE_VIEW_SIZE


func _replay_bet_marker_style() -> StyleBoxFlat:
	var marker_style := StyleBoxFlat.new()
	marker_style.anti_aliasing = true
	marker_style.bg_color = Color(0.020, 0.012, 0.034, 0.72)
	marker_style.border_color = Color(1.0, 0.76, 0.30, 0.36)
	marker_style.set_border_width_all(1)
	marker_style.set_corner_radius_all(9)
	marker_style.shadow_color = Color(1.0, 0.54, 0.10, 0.13)
	marker_style.shadow_size = 4
	return marker_style


func _replay_winner_seats(record: Dictionary) -> Dictionary:
	var winner_map: Dictionary = {}
	var results: Dictionary = Dictionary(record.get("results", {}))
	for winner_item in Array(results.get("winners", [])):
		var winner: Dictionary = Dictionary(winner_item)
		var seat_index: int = _winner_seat(winner)
		if seat_index >= 0:
			winner_map[seat_index] = true
	return winner_map


func _replay_playback_header_line(record: Dictionary) -> String:
	var hand_id: String = str(record.get("hand_id", _replay_playback_index_entry.get("replay_id", "Unknown")))
	return "Hand #%s - %s - NLH %s" % [
		_compact_hand_number(hand_id),
		_mode_label_for_replay(str(record.get("mode", ""))),
		_replay_blinds_label(record),
	]


func _add_replay_playback_player(parent: VBoxContainer, player: Dictionary) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.018, 0.020, 0.050, 0.72), Color(0.34, 0.52, 0.90, 0.26), 6, 1))
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var seat_index: int = int(player.get("seat_index", -1))
	var name_text: String = str(player.get("player_name", player.get("player_id", "Unknown")))
	_add_replay_text(box, "Seat %d - %s" % [seat_index, name_text], Color(0.92, 0.95, 1.0, 0.96))
	_add_replay_text(box, "Cards: %s" % str(player.get("cards_text", "Unknown")), Color(0.82, 0.86, 1.0, 0.92))
	_add_replay_text(box, "Stack: %s / Start %s" % [
		_replay_stack_text(player.get("stack", null)),
		_replay_stack_text(player.get("starting_stack", null)),
	], Color(0.82, 0.86, 1.0, 0.92))
	_add_replay_text(box, "Bet: %s" % _format_number(int(player.get("current_bet", 0))), HomeTheme.GOLD)
	_add_replay_text(box, "Status: %s" % str(player.get("status", "unknown")), Color(0.78, 0.82, 0.95, 0.92))


func _render_replay_playback_timeline() -> void:
	_replace_replay_children(_replay_playback_timeline_vbox)
	if _replay_playback_steps.is_empty():
		_add_replay_text(_replay_playback_timeline_vbox, "No actions recorded.", HomeTheme.MUTED)
		return
	var players: Array = Array(_replay_playback_record.get("players", []))
	_add_replay_text(_replay_playback_timeline_vbox, "PLAYER ACTIONS", HomeTheme.PINK)
	var action_count := 0
	for i in range(_replay_playback_steps.size()):
		var step: Dictionary = Dictionary(_replay_playback_steps[i])
		var kind: String = str(step.get("kind", "event"))
		if kind != "action":
			continue
		action_count += 1
		var prefix: String = "> " if i == _replay_playback_step - 1 else "  "
		var color: Color = HomeTheme.GOLD if i == _replay_playback_step - 1 else Color(0.82, 0.86, 1.0, 0.86)
		var line: String = "%s%d. %s - %s" % [
			prefix,
			action_count,
			_street_label(str(step.get("street", ""))),
			_replay_playback_step_label_text(step, players),
		]
		_add_replay_text(_replay_playback_timeline_vbox, line, color)
	if action_count == 0:
		_add_replay_text(_replay_playback_timeline_vbox, "No player actions recorded.", HomeTheme.MUTED)
	_add_replay_text(_replay_playback_timeline_vbox, "HAND EVENTS", HomeTheme.CYAN)
	var event_count := 0
	for i in range(_replay_playback_steps.size()):
		var step: Dictionary = Dictionary(_replay_playback_steps[i])
		var kind: String = str(step.get("kind", "event"))
		if kind == "action":
			continue
		event_count += 1
		var prefix: String = "> " if i == _replay_playback_step - 1 else "  "
		var color: Color = HomeTheme.GOLD if i == _replay_playback_step - 1 else Color(0.72, 0.82, 1.0, 0.80)
		var line: String = "%s- %s - %s" % [
			prefix,
			_street_label(str(step.get("street", ""))),
			_replay_playback_step_label_text(step, players),
		]
		_add_replay_text(_replay_playback_timeline_vbox, line, color)
	if event_count == 0:
		_add_replay_text(_replay_playback_timeline_vbox, "No hand events recorded.", HomeTheme.MUTED)


func _replace_replay_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _sorted_replay_actions(actions: Array) -> Array:
	var sorted_actions: Array = actions.duplicate(true)
	sorted_actions.sort_custom(func(a, b): return int(Dictionary(a).get("seq", 0)) < int(Dictionary(b).get("seq", 0)))
	var filtered_actions: Array = []
	for action_item in sorted_actions:
		var action: Dictionary = Dictionary(action_item)
		if _is_replay_debug_action(action):
			continue
		filtered_actions.append(action)
	return filtered_actions


func _build_replay_playback_steps(record: Dictionary) -> Array:
	var steps: Array = []
	var actions: Array = _sorted_replay_actions(Array(record.get("actions", [])))
	var seen_streets: Dictionary = {"preflop": true}
	var hand_label: String = str(record.get("hand_id", ""))
	if hand_label != "" and not actions.is_empty():
		steps.append({
			"kind": "event",
			"street": "preflop",
			"label": "Hand %s started" % hand_label,
		})
	for action_item in actions:
		var action: Dictionary = Dictionary(action_item)
		var street: String = str(action.get("street", ""))
		if street != "" and not seen_streets.has(street):
			seen_streets[street] = true
			var street_label: String = _replay_street_event_label(street, Dictionary(record.get("community_cards", {})))
			if street_label != "":
				steps.append({
					"kind": "event",
					"street": street,
					"label": street_label,
				})
		if _is_replay_player_action(action):
			steps.append({
				"kind": "action",
				"street": street,
				"action": action,
			})
		else:
			var event_label: String = _replay_system_event_line(action)
			if event_label != "":
				steps.append({
					"kind": "event",
					"street": street,
					"label": event_label,
				})
	var results: Dictionary = Dictionary(record.get("results", {}))
	if not results.is_empty():
		steps.append({
			"kind": "event",
			"street": "hand_over",
			"label": "Hand settled - %s wins %s" % [
				_winner_summary(results, Array(record.get("players", []))),
				_replay_final_pot_label(results),
			],
		})
	return steps


func _steps_with_timeline_text(source_steps: Array) -> Array:
	var result: Array = []
	var players: Array = Array(_replay_playback_record.get("players", []))
	for step_item in source_steps:
		var step: Dictionary = Dictionary(step_item).duplicate(true)
		step["timeline_text"] = _replay_playback_step_label_text(step, players)
		result.append(step)
	return result


func _is_replay_player_action(action: Dictionary) -> bool:
	var action_name: String = str(action.get("action", ""))
	return action_name in [
		"small_blind",
		"big_blind",
		"fold",
		"check",
		"call",
		"bet",
		"raise",
		"all_in",
		"timeout_auto_check",
		"timeout_auto_fold",
	]


func _replay_street_event_label(street: String, community: Dictionary) -> String:
	match street:
		"flop":
			return "Flop dealt: %s" % _card_list_text(Array(community.get("flop", [])))
		"turn":
			return "Turn dealt: %s" % _card_list_text(Array(community.get("turn", [])))
		"river":
			return "River dealt: %s" % _card_list_text(Array(community.get("river", [])))
		"showdown":
			return "Showdown"
		"hand_over":
			return "Hand over"
	return ""


func _replay_system_event_line(action: Dictionary) -> String:
	var message: String = str(action.get("message", "")).strip_edges()
	if message != "" and not _looks_like_replay_debug_text(message):
		return message
	var action_name: String = str(action.get("action", "")).replace("_", " ").strip_edges()
	return action_name.capitalize() if action_name != "" else ""


func _replay_playback_step_label_text(step: Dictionary, players: Array) -> String:
	if str(step.get("kind", "")) == "action":
		return _action_line(Dictionary(step.get("action", {})), players)
	return str(step.get("label", "-"))


func _replay_playback_state_for_step(record: Dictionary, target_step: int) -> Dictionary:
	var player_states: Array = _initial_replay_player_states(Array(record.get("players", [])))
	var pot: int = 0
	var current_street: String = "preflop"
	var action_text: String = "Initial state"
	var current_actor_seat: int = -1
	var steps_to_apply: int = clampi(target_step, 0, _replay_playback_steps.size())
	for i in range(steps_to_apply):
		var step: Dictionary = Dictionary(_replay_playback_steps[i])
		var street: String = str(step.get("street", ""))
		if street != "":
			current_street = street
		if str(step.get("kind", "")) == "action":
			var action: Dictionary = Dictionary(step.get("action", {}))
			pot = _apply_replay_action_to_state(player_states, pot, action)
			current_actor_seat = int(action.get("actor_seat", action.get("seat_id", -1)))
		else:
			current_actor_seat = -1
		action_text = "%s - %s" % [_street_label(current_street), _replay_playback_step_label_text(step, Array(record.get("players", [])))]
	if steps_to_apply >= _replay_playback_steps.size():
		_apply_replay_final_player_state(player_states, record)
		current_actor_seat = -1
	var board_cards: Array = _replay_board_for_street(Dictionary(record.get("community_cards", {})), current_street, steps_to_apply >= _replay_playback_steps.size())
	return {
		"players": player_states,
		"pot": pot,
		"board_text": _card_list_text(board_cards) if not board_cards.is_empty() else "-",
		"board_cards": board_cards,
		"action_text": action_text,
		"current_actor_seat": current_actor_seat,
	}


func _apply_replay_final_player_state(player_states: Array, record: Dictionary) -> void:
	var winner_seats: Dictionary = _replay_winner_seats(record)
	for i in range(player_states.size()):
		var player_state: Dictionary = Dictionary(player_states[i])
		var seat_index: int = int(player_state.get("seat_index", -1))
		if player_state.has("ending_stack"):
			player_state["stack"] = int(player_state.get("ending_stack", 0))
		var final_status: String = str(player_state.get("final_status", ""))
		if winner_seats.has(seat_index):
			player_state["status"] = "winner"
		elif final_status != "":
			player_state["status"] = final_status
		player_state["current_bet"] = 0
		player_states[i] = player_state


func _initial_replay_player_states(players: Array) -> Array:
	var player_states: Array = []
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var has_start_stack: bool = player.has("starting_stack")
		var start_stack: int = int(player.get("starting_stack", 0))
		var player_state: Dictionary = player.duplicate(true)
		player_state["starting_stack"] = start_stack if has_start_stack else null
		player_state["stack"] = start_stack if has_start_stack else null
		player_state["current_bet"] = 0
		player_state["status"] = "active"
		player_state["cards_text"] = _card_list_text(Array(player.get("hole_cards", [])))
		player_states.append(player_state)
	player_states.sort_custom(func(a, b): return int(Dictionary(a).get("seat_index", 99)) < int(Dictionary(b).get("seat_index", 99)))
	return player_states


func _apply_replay_action_to_state(player_states: Array, pot: int, action: Dictionary) -> int:
	var actor_index: int = _replay_actor_state_index(player_states, action)
	var actor_state: Dictionary = {}
	if actor_index >= 0:
		actor_state = Dictionary(player_states[actor_index])
	var action_name: String = str(action.get("action", ""))
	var amount: int = int(action.get("amount", 0))
	var bet_to: int = int(action.get("bet_to", -1))
	var pot_after: int = int(action.get("pot_after", -1))
	var stack_after: int = int(action.get("player_stack_after", -1))
	if not actor_state.is_empty():
		match action_name:
			"small_blind":
				actor_state["current_bet"] = int(actor_state.get("current_bet", 0)) + amount
				actor_state["status"] = "small blind"
			"big_blind":
				actor_state["current_bet"] = int(actor_state.get("current_bet", 0)) + amount
				actor_state["status"] = "big blind"
			"check":
				actor_state["status"] = "checked"
			"call":
				actor_state["current_bet"] = bet_to if bet_to >= 0 else int(actor_state.get("current_bet", 0)) + amount
				actor_state["status"] = "called"
			"bet":
				actor_state["current_bet"] = bet_to if bet_to >= 0 else amount
				actor_state["status"] = "bet"
			"raise":
				actor_state["current_bet"] = bet_to if bet_to >= 0 else amount
				actor_state["status"] = "raised"
			"all_in":
				actor_state["current_bet"] = bet_to if bet_to >= 0 else int(actor_state.get("current_bet", 0)) + amount
				actor_state["status"] = "all-in"
			"fold":
				actor_state["status"] = "folded"
			"timeout_auto_check":
				actor_state["status"] = "timeout check"
			"timeout_auto_fold":
				actor_state["status"] = "folded"
		if stack_after >= 0:
			actor_state["stack"] = stack_after
		elif amount > 0 and action_name in ["small_blind", "big_blind", "call", "bet", "raise", "all_in"]:
			var current_stack_value: Variant = actor_state.get("stack", null)
			if current_stack_value != null:
				actor_state["stack"] = max(0, int(current_stack_value) - amount)
		player_states[actor_index] = actor_state
	if pot_after >= 0:
		return pot_after
	if amount > 0 and action_name in ["small_blind", "big_blind", "call", "bet", "raise", "all_in"]:
		return pot + amount
	return pot


func _replay_actor_state_index(player_states: Array, action: Dictionary) -> int:
	var actor_seat: int = int(action.get("actor_seat", action.get("seat_id", -1)))
	var actor_player_id: String = str(action.get("actor_player_id", ""))
	for i in range(player_states.size()):
		var player: Dictionary = Dictionary(player_states[i])
		if actor_seat >= 0 and int(player.get("seat_index", -1)) == actor_seat:
			return i
		if actor_player_id != "" and str(player.get("player_id", "")) == actor_player_id:
			return i
	return -1


func _replay_board_for_street(community: Dictionary, street: String, force_full_board: bool) -> Array:
	var board: Array = []
	var street_key: String = street.to_lower()
	if street_key in ["flop", "turn", "river", "showdown", "hand_over"] or force_full_board:
		board.append_array(Array(community.get("flop", [])))
	if street_key in ["turn", "river", "showdown", "hand_over"] or force_full_board:
		board.append_array(Array(community.get("turn", [])))
	if street_key in ["river", "showdown", "hand_over"] or force_full_board:
		board.append_array(Array(community.get("river", [])))
	return board


func _replay_stack_text(value: Variant) -> String:
	if value == null:
		return "-"
	return _format_number(int(value))


func _make_replay_section(title_text: String, min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = title_text.replace(" ", "_").capitalize()
	panel.custom_minimum_size = min_size
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.018, 0.58), Color(0.26, 0.30, 0.52, 0.24), 6, 1))
	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = title_text
	HomeTheme.make_font_settings(title, 13, HomeTheme.PINK)
	vbox.add_child(title)
	return panel


func _add_replay_metric(parent: Container, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text.to_upper()
	HomeTheme.make_font_settings(label, 10, HomeTheme.MUTED)
	parent.add_child(label)
	var value := Label.new()
	value.text = value_text if value_text != "" else "-"
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	HomeTheme.make_font_settings(value, 12, Color(0.90, 0.94, 1.0, 0.96))
	parent.add_child(value)


func _add_replay_players(parent: VBoxContainer, players: Array) -> void:
	var sorted_players: Array = players.duplicate(true)
	sorted_players.sort_custom(func(a, b): return int(Dictionary(a).get("seat_index", 99)) < int(Dictionary(b).get("seat_index", 99)))
	if sorted_players.is_empty():
		_add_replay_text(parent, "No player data.", HomeTheme.MUTED)
		return
	for player_item in sorted_players:
		var player: Dictionary = Dictionary(player_item)
		var start_stack: int = int(player.get("starting_stack", 0))
		var end_stack: int = int(player.get("ending_stack", 0))
		var delta: int = end_stack - start_stack
		var card_text: String = _card_list_text(Array(player.get("hole_cards", [])))
		var status_text: String = str(player.get("final_status", "-"))
		if status_text == "":
			status_text = "-"
		var player_box := VBoxContainer.new()
		player_box.add_theme_constant_override("separation", 2)
		parent.add_child(player_box)
		var name_line := Label.new()
		name_line.text = "Seat %d - %s" % [
			int(player.get("seat_index", -1)),
			str(player.get("player_name", player.get("player_id", "Unknown"))),
		]
		HomeTheme.make_font_settings(name_line, 12, Color(0.92, 0.95, 1.0, 0.96))
		player_box.add_child(name_line)
		_add_replay_text(player_box, "Cards: %s" % card_text, Color(0.82, 0.86, 1.0, 0.92))
		var stack_line := Label.new()
		stack_line.text = "Stack: %s -> %s (%s)" % [
			_format_number(start_stack),
			_format_number(end_stack),
			_format_replay_delta(delta),
		]
		stack_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		HomeTheme.make_font_settings(stack_line, 11, _replay_delta_color(delta))
		player_box.add_child(stack_line)
		_add_replay_text(player_box, "Status: %s" % _title_case_replay_status(status_text), Color(0.78, 0.82, 0.95, 0.92))


func _add_replay_board_and_results(parent: VBoxContainer, record: Dictionary) -> void:
	var community: Dictionary = Dictionary(record.get("community_cards", {}))
	var flop: Array = Array(community.get("flop", []))
	var turn: Array = Array(community.get("turn", []))
	var river: Array = Array(community.get("river", []))
	_add_replay_text(parent, "Board:", HomeTheme.CYAN)
	if flop.is_empty() and turn.is_empty() and river.is_empty():
		_add_replay_text(parent, "No board cards recorded.", HomeTheme.MUTED)
	else:
		_add_replay_text(parent, "Flop: %s" % _card_list_text(flop), Color(0.86, 0.90, 1.0))
		_add_replay_text(parent, "Turn: %s" % _card_list_text(turn), Color(0.86, 0.90, 1.0))
		_add_replay_text(parent, "River: %s" % _card_list_text(river), Color(0.86, 0.90, 1.0))
	var results: Dictionary = Dictionary(record.get("results", {}))
	var players: Array = Array(record.get("players", []))
	_add_replay_text(parent, "Results:", HomeTheme.CYAN)
	var winners: Array = Array(results.get("winners", []))
	if winners.is_empty():
		_add_replay_text(parent, "No results recorded.", HomeTheme.MUTED)
	else:
		for winner_item in winners:
			var winner: Dictionary = Dictionary(winner_item)
			var winner_seat: int = _winner_seat(winner)
			var winner_name: String = _player_name_for_seat(players, winner_seat, str(winner.get("winner_player_id", "")))
			_add_replay_text(parent, "Seat %d - %s wins %s" % [
				winner_seat,
				winner_name,
				_format_number(int(winner.get("amount_won", 0))),
			], Color(0.92, 0.84, 0.45, 0.96))
			_add_replay_text(parent, "Hand: %s" % _winner_rank_text(winner, results), Color(0.82, 0.86, 1.0, 0.92))
	var side_pots: Array = Array(results.get("side_pots", []))
	if not side_pots.is_empty():
		_add_replay_text(parent, "Side pots: %d" % side_pots.size(), HomeTheme.MUTED)


func _add_replay_actions(parent: VBoxContainer, actions: Array, players: Array) -> void:
	var sorted_actions: Array = actions.duplicate(true)
	sorted_actions.sort_custom(func(a, b): return int(Dictionary(a).get("seq", 0)) < int(Dictionary(b).get("seq", 0)))
	var filtered_actions: Array = []
	for action_item in sorted_actions:
		var candidate_action: Dictionary = Dictionary(action_item)
		if _is_replay_debug_action(candidate_action):
			continue
		filtered_actions.append(candidate_action)
	if filtered_actions.is_empty():
		_add_replay_text(parent, "No actions recorded.", HomeTheme.MUTED)
		return
	var current_street: String = ""
	var viewer_order: int = 1
	for action_item in filtered_actions:
		var action: Dictionary = Dictionary(action_item)
		var street: String = str(action.get("street", ""))
		if street != current_street:
			current_street = street
			_add_replay_text(parent, _street_label(street), HomeTheme.PINK)
		_add_replay_text(parent, "%d. %s" % [viewer_order, _action_line(action, players)], Color(0.82, 0.86, 1.0, 0.92))
		viewer_order += 1


func _add_replay_text(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(label, 11, color)
	parent.add_child(label)


func _card_list_text(cards: Array) -> String:
	var codes: Array[String] = []
	for card_item in cards:
		if card_item is Dictionary:
			var card: Dictionary = Dictionary(card_item)
			codes.append(str(card.get("code", "-")))
		else:
			codes.append(str(card_item))
	if codes.is_empty():
		return "Unknown"
	return " ".join(codes)


func _action_line(action: Dictionary, players: Array = []) -> String:
	var actor: String = _action_actor_name(action, players)
	var action_name: String = str(action.get("action", "-"))
	var amount: int = int(action.get("amount", 0))
	var bet_to: int = int(action.get("bet_to", 0))
	match action_name:
		"small_blind":
			return "%s posts small blind %s" % [actor, _format_number(amount)]
		"big_blind":
			return "%s posts big blind %s" % [actor, _format_number(amount)]
		"call":
			return "%s calls %s" % [actor, _format_number(amount)]
		"check":
			return "%s checks" % actor
		"fold":
			return "%s folds" % actor
		"bet":
			return "%s bets %s" % [actor, _format_number(amount)]
		"raise":
			var raise_to: int = bet_to if bet_to > 0 else amount
			return "%s raises to %s" % [actor, _format_number(raise_to)]
		"all_in":
			return "%s goes all-in %s" % [actor, _format_number(amount)]
		"timeout_auto_check":
			return "%s timed out. Auto-check." % actor
		"timeout_auto_fold":
			return "%s timed out. Auto-fold." % actor
	var message: String = str(action.get("message", "")).strip_edges()
	if message != "" and not _looks_like_replay_debug_text(message):
		return message
	var amount_suffix: String = ""
	if amount > 0:
		amount_suffix = " %s" % _format_number(amount)
	return "%s %s%s" % [actor, action_name.replace("_", " "), amount_suffix]


func _winner_summary(results: Dictionary, players: Array = []) -> String:
	var winners: Array = Array(results.get("winners", []))
	if winners.is_empty():
		return "-"
	var labels: Array[String] = []
	for winner_item in winners:
		var winner: Dictionary = Dictionary(winner_item)
		var winner_seat: int = _winner_seat(winner)
		var label: String = _player_name_for_seat(players, winner_seat, str(winner.get("winner_player_id", "")))
		if label == "":
			label = "Seat %d" % winner_seat
		labels.append(label)
	return ", ".join(labels)


func _replay_room_label(record: Dictionary) -> String:
	var room_code: String = str(record.get("room_code", ""))
	if room_code != "":
		return "Room Code %s" % room_code
	var room_id: String = str(record.get("room_id", ""))
	return room_id if room_id != "" else "-"


func _mode_label_for_replay(mode: String) -> String:
	match mode:
		"public":
			return "Public Table"
		"private":
			return "Private Room"
		"training":
			return "Training"
		"local_warmup":
			return "Local Warm-up"
	return "Unknown"


func _street_label(street: String) -> String:
	match street:
		"preflop":
			return "PREFLOP"
		"flop":
			return "FLOP"
		"turn":
			return "TURN"
		"river":
			return "RIVER"
		"showdown":
			return "SHOWDOWN"
		"hand_over":
			return "HAND OVER"
	return "OTHER"


func _format_replay_delta(value: int) -> String:
	if value > 0:
		return "+%s" % _format_number(value)
	if value < 0:
		return "-%s" % _format_number(abs(value))
	return _format_number(value)


func _load_replay_record_preview(index_entry: Dictionary) -> Dictionary:
	var file_path: String = str(index_entry.get("file_path", ""))
	if file_path == "" or not FileAccess.file_exists(file_path):
		return {}
	return ReplayServiceScript.new().load_replay_record(file_path)


func _make_replay_dealer_thumbnail(index_entry: Dictionary, record: Dictionary) -> Control:
	var texture: Texture2D = _replay_dealer_thumbnail_texture(index_entry, record)
	if texture == null:
		var placeholder := ColorRect.new()
		placeholder.name = "ReplayDealerThumbnailPlaceholder"
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placeholder.custom_minimum_size = Vector2(56, 68)
		placeholder.color = Color(0.18, 0.22, 0.38, 0.45)
		return placeholder
	var thumb := TextureRect.new()
	thumb.name = "ReplayDealerThumbnail"
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.custom_minimum_size = Vector2(56, 68)
	thumb.texture = texture
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	thumb.tooltip_text = "Dealer: %s" % DealerLibraryScript.display_name(_replay_dealer_id(index_entry, record))
	return thumb


func _replay_dealer_thumbnail_texture(index_entry: Dictionary, record: Dictionary) -> Texture2D:
	var texture_path: String = DealerLibraryScript.get_dealer_texture_path(_replay_dealer_id(index_entry, record))
	var texture := load(texture_path) as Texture2D
	if texture != null:
		return texture
	var fallback_path: String = DealerLibraryScript.get_dealer_texture_path(DealerLibraryScript.get_default_dealer_id())
	return load(fallback_path) as Texture2D


func _replay_dealer_id(index_entry: Dictionary, record: Dictionary) -> String:
	var dealer_id: String = str(index_entry.get("dealer_id", ""))
	if dealer_id == "":
		dealer_id = str(record.get("dealer_id", ""))
	return DealerLibraryScript.normalize_dealer_id(dealer_id)


func _replay_list_title(index_entry: Dictionary, record: Dictionary) -> String:
	var hand_id: String = str(record.get("hand_id", index_entry.get("replay_id", "")))
	if hand_id == "":
		return "Hand #Unknown"
	return "Hand #%s" % _compact_hand_number(hand_id)


func _replay_list_stakes_line(index_entry: Dictionary, record: Dictionary) -> String:
	var mode_label: String = _mode_label_for_replay(str(record.get("mode", "")))
	if mode_label == "Unknown":
		mode_label = str(index_entry.get("mode", "Table"))
	var blinds: String = _replay_blinds_label(record)
	var played_at: String = str(index_entry.get("played_at", ""))
	if blinds != "-":
		return "%s - NLH %s" % [mode_label, blinds]
	if played_at != "":
		return "%s - %s" % [mode_label, played_at]
	return mode_label


func _replay_list_result_line(index_entry: Dictionary, record: Dictionary) -> String:
	var results: Dictionary = Dictionary(record.get("results", {}))
	var players: Array = Array(record.get("players", []))
	var winner_text: String = _winner_summary(results, players)
	var pot_text: String = _replay_final_pot_label(results)
	if winner_text == "-" and pot_text == "-":
		return "Winner: - - Pot -"
	return "Winner: %s - Pot %s" % [winner_text, pot_text]


func _replay_list_time_label(index_entry: Dictionary) -> String:
	var played_at: String = str(index_entry.get("played_at", ""))
	return played_at if played_at != "" else "-"


func _replay_blinds_label(record: Dictionary) -> String:
	var small_blind: int = int(record.get("small_blind", 0))
	var big_blind: int = int(record.get("big_blind", 0))
	if small_blind <= 0 and big_blind <= 0:
		return "-"
	return "%s / %s" % [_format_number(small_blind), _format_number(big_blind)]


func _replay_hand_label(record: Dictionary, hand_id: String) -> String:
	var hand_number: int = int(record.get("hand_number", 0))
	var max_hands: int = int(record.get("max_hands", 0))
	if hand_number > 0 and max_hands > 0:
		return "%d / %d" % [hand_number, max_hands]
	if hand_number > 0 and max_hands == 0:
		return "%d / Unlimited" % hand_number
	return hand_id if hand_id != "" else "-"


func _replay_result_label(record: Dictionary, index_entry: Dictionary) -> String:
	var mode: String = str(record.get("mode", ""))
	if mode in ["training", "local_warmup"]:
		return "Practice"
	var profit: int = _replay_profit_value(index_entry)
	if profit > 0:
		return "Win"
	if profit < 0:
		return "Loss"
	var fallback: String = str(index_entry.get("result", index_entry.get("player_result", "")))
	return fallback if fallback != "" else "-"


func _replay_profit_label(index_entry: Dictionary, record: Dictionary = {}) -> String:
	var mode: String = str(record.get("mode", ""))
	if mode in ["training", "local_warmup"]:
		return "Practice"
	if not index_entry.has("net_chips") and not index_entry.has("profit"):
		return "-"
	var currency: String = str(record.get("currency", index_entry.get("currency", "gems" if str(record.get("table_type", "")).ends_with("_gem") else "chips")))
	return "%s %s" % [_format_replay_delta(_replay_profit_value(index_entry)), _currency_label(currency)]


func _replay_profit_value(index_entry: Dictionary) -> int:
	if index_entry.has("net_chips"):
		return int(index_entry.get("net_chips", 0))
	return int(index_entry.get("profit", 0))


func _replay_final_pot_label(results: Dictionary) -> String:
	var final_pot: int = int(results.get("final_pot", 0))
	if final_pot <= 0:
		return "-"
	return _format_number(final_pot)


func _compact_hand_number(hand_id: String) -> String:
	var compact: String = hand_id
	if compact.begins_with("hand_"):
		compact = compact.substr(5)
	if compact == "":
		return "Unknown"
	return compact


func _replay_delta_color(delta: int) -> Color:
	if delta > 0:
		return Color(0.28, 0.95, 0.58, 0.96)
	if delta < 0:
		return HomeTheme.PINK
	return Color(0.78, 0.82, 0.95, 0.92)


func _title_case_replay_status(status: String) -> String:
	if status == "-" or status == "":
		return "-"
	var words: Array[String] = []
	for word_item in status.replace("_", " ").split(" ", false):
		var word: String = str(word_item)
		words.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(words)


func _winner_seat(winner: Dictionary) -> int:
	if winner.has("winner_seat"):
		return int(winner.get("winner_seat", -1))
	if winner.has("seat_id"):
		return int(winner.get("seat_id", -1))
	if winner.has("seat"):
		return int(winner.get("seat", -1))
	return int(winner.get("seat_index", -1))


func _winner_rank_text(winner: Dictionary, results: Dictionary) -> String:
	var rank: String = str(winner.get("hand_rank_text", ""))
	if rank == "":
		rank = str(results.get("hand_rank_text", ""))
	return rank if rank != "" else "-"


func _player_name_for_seat(players: Array, seat_index: int, fallback: String = "") -> String:
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		if int(player.get("seat_index", -1)) == seat_index:
			var player_name: String = str(player.get("player_name", ""))
			if player_name != "":
				return player_name
			var player_id: String = str(player.get("player_id", ""))
			if player_id != "":
				return player_id
	return fallback


func _player_name_for_id(players: Array, player_id: String, fallback: String = "") -> String:
	if player_id == "":
		return fallback
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		if str(player.get("player_id", "")) == player_id:
			var player_name: String = str(player.get("player_name", ""))
			if player_name != "":
				return player_name
			return player_id
	return fallback


func _action_actor_name(action: Dictionary, players: Array) -> String:
	var actor_seat: int = int(action.get("actor_seat", action.get("seat_id", -1)))
	var actor_player_id: String = str(action.get("actor_player_id", ""))
	var fallback: String = _player_name_for_id(players, actor_player_id, actor_player_id)
	var name: String = _player_name_for_seat(players, actor_seat, fallback)
	if name != "":
		return name
	if actor_seat >= 0:
		return "Seat %d" % actor_seat
	return "Unknown"


func _is_replay_debug_action(action: Dictionary) -> bool:
	var message: String = str(action.get("message", ""))
	var action_name: String = str(action.get("action", ""))
	return _looks_like_replay_debug_text(message) or _looks_like_replay_debug_text(action_name)


func _looks_like_replay_debug_text(text: String) -> bool:
	var trimmed: String = text.strip_edges()
	if trimmed == "":
		return false
	if trimmed.begins_with("----") or trimmed.ends_with("----"):
		return true
	return trimmed.to_lower().find("---- hand") != -1


func _build_store_panel() -> void:
	_store_panel = PanelContainer.new()
	_store_panel.name = "StorePanel"
	_store_panel.anchor_left = 0.0
	_store_panel.anchor_top = 0.32
	_store_panel.anchor_right = 1.0
	_store_panel.anchor_bottom = 0.91
	_store_panel.offset_left = MAIN_LEFT
	_store_panel.offset_right = -MAIN_RIGHT
	_store_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_store_panel.custom_minimum_size = Vector2(0, 580)
	_store_panel.visible = false
	_store_panel.modulate.a = 0.0
	_store_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(0.52, 0.78, 1.0, 0.28), 8, 1))
	_lobby_ui_root.add_child(_store_panel)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	_store_panel.add_child(main_vbox)
	
	# Header
	var title_box := VBoxContainer.new()
	main_vbox.add_child(title_box)
	var title := Label.new()
	title.text = _t("store.title")
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = _t("store.subtitle")
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	
	var dev_label := Label.new()
	dev_label.text = _t("store.dev_badge")
	HomeTheme.make_font_settings(dev_label, 13, HomeTheme.GOLD)
	main_vbox.add_child(dev_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	main_vbox.add_child(tabs)
	for tab_name in [_t("store.chips").to_upper(), _t("store.gems").to_upper()]:
		var tab := Button.new()
		tab.text = tab_name
		tab.custom_minimum_size = Vector2(140, 36)
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.66), Color(0.52, 0.78, 1.0, 0.34), 18))
		tab.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 0.94))
		tabs.add_child(tab)

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 24)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(grid)

	_add_store_currency_column(grid, _t("store.chips").to_upper(), _t("store.chips_desc"), [10000, 50000, 100000], "chips", HomeTheme.GOLD)
	_add_store_currency_column(grid, _t("store.gems").to_upper(), _t("store.gems_desc"), [100, 500, 1200], "gems", HomeTheme.PINK)

func _add_store_currency_column(parent: Container, title_text: String, desc_text: String, packs: Array, currency: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.016, 0.035, 0.70), accent.darkened(0.25), 8, 1))
	parent.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)
	var title := Label.new()
	title.text = _tf("store.mock_purchase_title", {"currency": title_text.capitalize()})
	HomeTheme.make_font_settings(title, 18, accent)
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(desc, 12, HomeTheme.MUTED)
	vbox.add_child(desc)
	for pack_item in packs:
		var amount: int = int(pack_item)
		var button := Button.new()
		button.text = _tf("store.mock_buy", {"amount": _format_number(amount), "currency": title_text.capitalize()})
		button.custom_minimum_size = Vector2(220, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.70), accent.darkened(0.10), 18))
		button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.035, 0.04, 0.085, 0.86), accent, 18))
		button.pressed.connect(_show_mock_purchase_confirm.bind(currency, amount))
		vbox.add_child(button)

func _show_mock_purchase_confirm(currency: String, amount: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = _t("store.mock_purchase_confirm_title")
	var target := "server wallet" if server_authoritative_profile and _profile_server_connected else "local wallet"
	dialog.dialog_text = _tf("store.mock_purchase_confirm_text", {"amount": _format_number(amount), "currency": currency.to_upper(), "target": target})
	dialog.confirmed.connect(_confirm_mock_purchase.bind(currency, amount, dialog))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2(360, 180))

func _confirm_mock_purchase(currency: String, amount: int, dialog: ConfirmationDialog) -> void:
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		var err := _profile_ws_client.mock_purchase(currency, amount)
		if err == OK:
			_show_toast(_t("store.mock_purchase_sent"), [], 1.4)
		else:
			_show_toast(_t("store.mock_purchase_server_failed"), [], 2.4)
		if dialog != null:
			dialog.queue_free()
		return
	var store := StoreMockServiceScript.new()
	if currency == "gems":
		_player_profile = store.mock_purchase_gems(amount)
	else:
		_player_profile = store.mock_purchase_chips(amount)
	_play_currency_sfx(currency, "mock_purchase:local:%s:%d" % [currency, amount])
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()
	if dialog != null:
		dialog.queue_free()

func _on_server_mock_purchase_result(ok: bool, currency: String, amount: int, wallet: Dictionary) -> void:
	if not ok:
		_show_toast(_t("store.mock_purchase_failed"), [], 2.4)
		return
	if not wallet.is_empty():
		_player_profile = ProfileServiceScript.new().apply_wallet_snapshot(wallet)
		_refresh_profile_views_from_server()
	_play_currency_sfx(currency, "mock_purchase:server:%s:%d" % [currency, amount])
	var label := "Gems" if currency == "gems" else "Chips"
	_show_toast(_tf("store.mock_purchase_complete", {"amount": _format_number(amount), "currency": label}), [], 2.8)

func _build_profile_panel() -> void:
	_profile_panel = PanelContainer.new()
	_profile_panel.name = "ProfilePanel"
	_profile_panel.anchor_left = 0.0
	_profile_panel.anchor_top = 0.22
	_profile_panel.anchor_right = 1.0
	_profile_panel.anchor_bottom = 0.94
	_profile_panel.offset_left = MAIN_LEFT
	_profile_panel.offset_right = -MAIN_RIGHT
	_profile_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_profile_panel.custom_minimum_size = Vector2(0, 700)
	_profile_panel.visible = false
	_profile_panel.modulate.a = 0.0
	_profile_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(0.62, 0.36, 1.0, 0.28), 8, 1))
	_lobby_ui_root.add_child(_profile_panel)
	
	var page_scroll := ScrollContainer.new()
	page_scroll.name = "ProfilePageScroll"
	page_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_profile_panel.add_child(page_scroll)
	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 16)
	page_scroll.add_child(main_vbox)
	
	# Header
	var title_box := VBoxContainer.new()
	main_vbox.add_child(title_box)
	var title := Label.new()
	title.text = _t("profile.title")
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = _t("profile.subtitle")
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	
	# Card Body
	var body_hbox := HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 24)
	body_hbox.custom_minimum_size = Vector2(0, 204)
	main_vbox.add_child(body_hbox)
	
	# Left: Player Card info
	var card_info := PanelContainer.new()
	card_info.custom_minimum_size = Vector2(380, 0)
	card_info.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	var c_vbox := VBoxContainer.new()
	c_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	c_vbox.add_theme_constant_override("separation", 10)
	card_info.add_child(c_vbox)
	
	var avatar_frame := PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(154, 154)
	avatar_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar_frame.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.016, 0.038, 0.86), Color(0.60, 0.92, 1.0, 0.70), 20, 1))
	c_vbox.add_child(avatar_frame)
	_profile_avatar_rect = TextureRect.new()
	_profile_avatar_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_profile_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_profile_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_profile_avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_profile_avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_frame.add_child(_profile_avatar_rect)

	_profile_name_label = Label.new()
	_profile_name_label.name = "ProfileNameLabel"
	HomeTheme.make_font_settings(_profile_name_label, 22, Color(1, 1, 1, 0.95))
	_profile_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_vbox.add_child(_profile_name_label)

	_profile_level_label = Label.new()
	_profile_level_label.name = "ProfileLevelLabel"
	HomeTheme.make_font_settings(_profile_level_label, 13, HomeTheme.MUTED)
	_profile_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_vbox.add_child(_profile_level_label)

	_profile_avatar_name_label = Label.new()
	_profile_avatar_name_label.name = "ProfileAvatarNameLabel"
	HomeTheme.make_font_settings(_profile_avatar_name_label, 13, HomeTheme.CYAN)
	_profile_avatar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_vbox.add_child(_profile_avatar_name_label)
	
	body_hbox.add_child(card_info)
	
	# Right: Stats overview
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 12)
	right_panel.add_child(r_vbox)
	
	var s_title := Label.new()
	s_title.text = _t("profile.overview_stats")
	HomeTheme.make_font_settings(s_title, 16, HomeTheme.PURPLE)
	r_vbox.add_child(s_title)
	
	_profile_stats_labels.clear()
	var stats_grid := GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 8)
	r_vbox.add_child(stats_grid)
	for stat_id in [
		"total_chips",
		"total_sessions_played",
		"total_hands_played",
		"total_hands_won",
		"win_rate",
		"total_profit",
		"biggest_pot",
		"best_session_profit",
		"best_hand_desc",
	]:
		_profile_stats_labels[stat_id] = _make_profile_stat_tile(stats_grid, _profile_stat_title(stat_id))

	body_hbox.add_child(right_panel)

	var gallery_panel := PanelContainer.new()
	gallery_panel.name = "AvatarGalleryPanel"
	gallery_panel.custom_minimum_size = Vector2(0, 430)
	gallery_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gallery_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.010, 0.012, 0.030, 0.78), Color(0.62, 0.36, 1.0, 0.46), 8, 1))
	main_vbox.add_child(gallery_panel)
	var gallery_vbox := VBoxContainer.new()
	gallery_vbox.add_theme_constant_override("separation", 10)
	gallery_panel.add_child(gallery_vbox)
	var gallery_title := Label.new()
	gallery_title.text = _t("profile.character_avatars")
	HomeTheme.make_font_settings(gallery_title, 16, HomeTheme.PURPLE)
	gallery_vbox.add_child(gallery_title)
	var gallery_scroll := ScrollContainer.new()
	gallery_scroll.custom_minimum_size = Vector2(0, 370)
	gallery_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gallery_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gallery_vbox.add_child(gallery_scroll)
	_profile_avatar_grid = GridContainer.new()
	_profile_avatar_grid.columns = 7
	_profile_avatar_grid.add_theme_constant_override("h_separation", 14)
	_profile_avatar_grid.add_theme_constant_override("v_separation", 14)
	gallery_scroll.add_child(_profile_avatar_grid)
	_build_avatar_gallery()
		
	var ach_title := Label.new()
	ach_title.text = _t("profile.achievements")
	HomeTheme.make_font_settings(ach_title, 16, HomeTheme.PURPLE)
	r_vbox.add_child(ach_title)
	
	var achievements := [
		{"name_key": "achievement.first_blood.name", "desc_key": "achievement.first_blood.desc", "status_key": "achievement.status.unlocked"},
		{"name_key": "achievement.showdown_master.name", "desc_key": "achievement.showdown_master.desc", "status_key": "achievement.status.locked"},
	]
	for ach_value in achievements:
		var ach: Dictionary = Dictionary(ach_value)
		var a_lbl := Label.new()
		a_lbl.text = _tf("achievement.line", {
			"name": _t(str(ach.get("name_key", ""))),
			"desc": _t(str(ach.get("desc_key", ""))),
			"status": _t(str(ach.get("status_key", ""))),
		})
		HomeTheme.make_font_settings(a_lbl, 12, Color(0.72, 0.76, 0.92))
		r_vbox.add_child(a_lbl)
	_refresh_profile_panel()

func _make_profile_stat_tile(parent: Container, title_text: String) -> Label:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(168, 54)
	tile.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.018, 0.022, 0.052, 0.64), Color(0.55, 0.48, 0.88, 0.30), 8, 1))
	parent.add_child(tile)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	tile.add_child(box)
	var title := Label.new()
	title.text = title_text
	HomeTheme.make_font_settings(title, 11, HomeTheme.MUTED)
	box.add_child(title)
	var value := Label.new()
	HomeTheme.make_font_settings(value, 15, Color(0.92, 0.96, 1.0))
	box.add_child(value)
	return value

func _profile_stat_title(stat_id: String) -> String:
	match stat_id:
		"total_chips":
			return _t("profile.total_chips").to_upper()
		"total_sessions_played":
			return _t("profile.total_sessions").to_upper()
		"total_hands_played":
			return _t("profile.total_hands").to_upper()
		"total_hands_won":
			return _t("profile.hands_won").to_upper()
		"win_rate":
			return _t("profile.win_rate").to_upper()
		"total_profit":
			return _t("profile.total_profit").to_upper()
		"biggest_pot":
			return _t("profile.biggest_pot").to_upper()
		"best_session_profit":
			return _t("profile.best_session_profit").to_upper()
		"best_hand_desc":
			return _t("profile.best_hand").to_upper()
		_:
			return stat_id.to_upper()

func _refresh_profile_panel() -> void:
	if _player_profile.is_empty():
		_player_profile = ProfileServiceScript.new().get_current_profile()
	if _profile_name_label != null:
		_profile_name_label.text = PlayerProfileScript.get_player_name(_player_profile)
	if _profile_level_label != null:
		var total_xp: int = PlayerProfileScript.get_total_xp(_player_profile)
		var level: int = PlayerProfileScript.level_for_total_xp(total_xp)
		_profile_level_label.text = "%s: %s\n%s\n%s" % [
			_t("profile.title_label"),
			_localized_profile_title(level),
			_tf("profile.level", {"level": level}),
			_tf("profile.xp", {"current": PlayerProfileScript.xp_current_for_total_xp(total_xp), "next": PlayerProfileScript.XP_PER_LEVEL}),
		]
	if _profile_avatar_rect != null:
		var selected_avatar_id: String = PlayerProfileScript.get_avatar_id(_player_profile)
		var texture: Texture2D = AvatarLibraryScript.get_avatar_by_id(PlayerProfileScript.get_avatar_id(_player_profile))
		if texture == null:
			var avatar_path := str(_player_profile.get("avatar", ""))
			if avatar_path != "" and ResourceLoader.exists(avatar_path):
				texture = load(avatar_path) as Texture2D
		_profile_avatar_rect.texture = texture
		_profile_avatar_rect.visible = texture != null
		if _profile_avatar_name_label != null:
			_profile_avatar_name_label.text = _tf("profile.selected_avatar", {"avatar": _avatar_display_name(selected_avatar_id)})
	_set_profile_stat("total_chips", _format_number(PlayerProfileScript.get_total_chips(_player_profile)))
	_set_profile_stat("total_sessions_played", _format_number(int(_player_profile.get("total_sessions_played", 0))))
	_set_profile_stat("total_hands_played", _format_number(int(_player_profile.get("total_hands_played", 0))))
	_set_profile_stat("total_hands_won", _format_number(int(_player_profile.get("total_hands_won", 0))))
	_set_profile_stat("win_rate", "%.1f%%" % (PlayerProfileScript.win_rate(_player_profile) * 100.0))
	_set_profile_stat("total_profit", _signed_number(int(_player_profile.get("total_profit", 0))))
	_set_profile_stat("biggest_pot", _format_number(int(_player_profile.get("biggest_pot", 0))))
	_set_profile_stat("best_session_profit", _signed_number(int(_player_profile.get("best_session_profit", 0))))
	var best_hand := str(_player_profile.get("best_hand_desc", ""))
	_set_profile_stat("best_hand_desc", best_hand if best_hand != "" else "-")
	_refresh_avatar_gallery()

func _set_profile_stat(stat_id: String, value: String) -> void:
	var label: Label = _profile_stats_labels.get(stat_id) as Label
	if label != null:
		label.text = value

func _build_avatar_gallery() -> void:
	if _profile_avatar_grid == null:
		return
	_profile_avatar_buttons.clear()
	for avatar_id in AvatarLibraryScript.load_all_avatars():
		var button := Button.new()
		button.name = "Avatar_%s" % avatar_id
		button.text = _avatar_display_name(avatar_id)
		button.custom_minimum_size = Vector2(138, 174)
		button.icon = AvatarLibraryScript.get_avatar_by_id(avatar_id)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.clip_text = true
		button.tooltip_text = avatar_id
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_avatar_selected.bind(avatar_id))
		_profile_avatar_grid.add_child(button)
		_profile_avatar_buttons[avatar_id] = button
	_refresh_avatar_gallery()

func _refresh_avatar_gallery() -> void:
	var unlocked: Array = Array(_player_profile.get("unlocked_avatar_ids", []))
	var selected_id: String = PlayerProfileScript.get_avatar_id(_player_profile)
	for avatar_key in _profile_avatar_buttons.keys():
		var avatar_id: String = str(avatar_key)
		var button: Button = _profile_avatar_buttons[avatar_key] as Button
		if button == null:
			continue
		var is_unlocked: bool = unlocked.has(avatar_id)
		var is_selected: bool = avatar_id == selected_id
		var price_chips: int = _avatar_price_chips(avatar_id)
		var can_afford: bool = PlayerProfileScript.get_total_chips(_player_profile) >= price_chips
		button.disabled = not is_unlocked and not can_afford
		var display_name: String = _avatar_display_name(avatar_id)
		var status_text := _t("avatar.select").to_upper()
		if is_selected:
			status_text = _t("avatar.selected").to_upper()
		elif not is_unlocked:
			if can_afford:
				status_text = _tf("avatar.buy_chips", {"price": _format_number(price_chips)})
			else:
				status_text = _tf("avatar.need_chips", {"price": _format_number(price_chips)})
		button.text = "%s\n%s" % [display_name, status_text]
		button.tooltip_text = "%s\n%s" % [avatar_id, status_text]
		button.modulate = Color(1.08, 1.08, 1.12, 1.0) if is_unlocked else Color(0.62, 0.62, 0.72, 0.88)
		button.add_theme_stylebox_override("normal", _avatar_gallery_button_style(is_selected, is_unlocked, false))
		button.add_theme_stylebox_override("hover", _avatar_gallery_button_style(is_selected, is_unlocked, true))
		button.add_theme_stylebox_override("pressed", _avatar_gallery_button_style(is_selected, is_unlocked, true))
		button.add_theme_stylebox_override("disabled", _avatar_gallery_button_style(false, false, false))
		button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 0.98))
		button.add_theme_color_override("font_disabled_color", Color(0.72, 0.74, 0.84, 0.92))

func _avatar_gallery_button_style(selected: bool, unlocked: bool, hover: bool) -> StyleBoxFlat:
	var bg := Color(0.030, 0.036, 0.082, 0.84)
	var border := Color(0.58, 0.58, 0.92, 0.42)
	if selected:
		bg = Color(0.055, 0.075, 0.120, 0.94)
		border = Color(0.35, 0.95, 1.0, 1.00)
	elif not unlocked:
		bg = Color(0.018, 0.020, 0.040, 0.76)
		border = Color(0.34, 0.34, 0.50, 0.38)
	elif hover:
		bg = Color(0.045, 0.050, 0.105, 0.92)
		border = Color(0.82, 0.58, 1.0, 0.76)
	var style := HomeTheme.make_button_style(bg, border, 10)
	style.shadow_color = Color(border.r, border.g, border.b, 0.28 if selected else 0.10)
	style.shadow_size = 14 if selected else 6
	return style

func _on_avatar_selected(avatar_id: String) -> void:
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		var unlocked: Array = Array(_player_profile.get("unlocked_avatar_ids", []))
		if unlocked.has(avatar_id):
			_profile_ws_client.select_avatar(_server_avatar_id_for_client(avatar_id))
			_show_toast(_t("avatar.selecting_server"), [], 1.4)
		else:
			var server_price_chips: int = _avatar_price_chips(avatar_id)
			if PlayerProfileScript.get_total_chips(_player_profile) < server_price_chips:
				_show_toast(_tf("avatar.not_enough", {"price": _format_number(server_price_chips)}), [], 2.4)
				return
			_show_avatar_purchase_confirm(avatar_id, server_price_chips)
		return
	var service := ProfileServiceScript.new()
	var local_unlocked: Array = Array(_player_profile.get("unlocked_avatar_ids", []))
	if local_unlocked.has(avatar_id):
		_player_profile = service.select_avatar(avatar_id)
	else:
		var local_price_chips: int = _avatar_price_chips(avatar_id)
		if PlayerProfileScript.get_total_chips(_player_profile) < local_price_chips:
			_show_toast(_tf("avatar.not_enough", {"price": _format_number(local_price_chips)}), [], 2.4)
			return
		_show_avatar_purchase_confirm(avatar_id, local_price_chips)
		return
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()

func _show_avatar_purchase_confirm(avatar_id: String, price_chips: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = _t("avatar.confirm_title")
	dialog.dialog_text = _tf("avatar.confirm_text", {
		"name": _avatar_display_name(avatar_id),
		"price": _format_number(price_chips),
	})
	dialog.confirmed.connect(_confirm_avatar_purchase.bind(avatar_id, price_chips, dialog))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.get_ok_button().text = _t("common.confirm").to_upper()
	dialog.get_cancel_button().text = _t("common.cancel").to_upper()
	dialog.popup_centered(Vector2(380, 150))

func _confirm_avatar_purchase(avatar_id: String, price_chips: int, dialog: ConfirmationDialog) -> void:
	if PlayerProfileScript.get_total_chips(_player_profile) < price_chips:
		_show_toast(_tf("avatar.not_enough", {"price": _format_number(price_chips)}), [], 2.4)
		if dialog != null:
			dialog.queue_free()
		_refresh_profile_panel()
		return
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_profile_ws_client.buy_avatar(_server_avatar_id_for_client(avatar_id))
		_show_toast(_t("avatar.purchase_sent"), [], 1.4)
		if dialog != null:
			dialog.queue_free()
		return
	var service := ProfileServiceScript.new()
	var result: Dictionary = service.purchase_avatar_with_chips(avatar_id, price_chips)
	_player_profile = Dictionary(result.get("profile", service.get_current_profile()))
	if bool(result.get("success", false)):
		_show_toast(_tf("avatar.purchased_selected", {"name": _avatar_display_name(avatar_id)}), [], 2.2)
	else:
		_show_toast(_tf("avatar.not_enough", {"price": _format_number(price_chips)}), [], 2.4)
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()
	if dialog != null:
		dialog.queue_free()

func _avatar_price_text(avatar_id: String) -> String:
	return _tf("common.chips_amount", {"amount": _format_number(_avatar_price_chips(avatar_id))})

func _avatar_price_chips(avatar_id: String) -> int:
	var item := _catalog_item_for_avatar(avatar_id)
	if item.is_empty():
		return AvatarLibraryScript.price_chips_for_avatar_id(avatar_id)
	var price: int = int(item.get("price_chips", 0))
	return price if price > 0 else AvatarLibraryScript.price_chips_for_avatar_id(avatar_id)

func _avatar_display_name(avatar_id: String) -> String:
	var key := "avatar.%s.name" % avatar_id
	var localized := _t(key)
	if localized != key:
		return localized
	return AvatarLibraryScript.display_name_for_avatar_id(avatar_id)

func _localized_profile_title(level: int) -> String:
	var raw_title := PlayerProfileScript.title_for_level(level)
	var key := "profile.title.%s" % raw_title.to_lower().replace(" ", "_")
	var localized := _t(key)
	return localized if localized != key else raw_title

func _catalog_item_for_avatar(avatar_id: String) -> Dictionary:
	var server_avatar_id := _server_avatar_id_for_client(avatar_id)
	return Dictionary(_avatar_catalog_by_id.get(server_avatar_id, {}))

func _server_avatar_id_for_client(avatar_id: String) -> String:
	var normalized := avatar_id.strip_edges()
	if normalized == "" or normalized == PlayerProfileScript.DEFAULT_AVATAR_ID:
		return "default"
	return normalized

func _signed_number(value: int) -> String:
	if value == 0:
		return "0"
	if value > 0:
		return "+%s" % _format_number(value)
	return "-%s" % _format_number(abs(value))

func _build_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.anchor_left = 0.5
	_settings_panel.anchor_top = 0.16
	_settings_panel.anchor_right = 0.5
	_settings_panel.anchor_bottom = 0.88
	_settings_panel.offset_left = -430
	_settings_panel.offset_right = 430
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_settings_panel.custom_minimum_size = Vector2(860, 560)
	_settings_panel.visible = false
	_settings_panel.modulate.a = 0.0
	_settings_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.72), Color(0.62, 0.36, 1.0, 0.28), 8, 1))
	_lobby_ui_root.add_child(_settings_panel)
	
	var settings := _settings_service.load_settings()
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	_settings_panel.add_child(main_vbox)

	var title_box := VBoxContainer.new()
	main_vbox.add_child(title_box)
	var title := Label.new()
	title.text = _t("settings.title")
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = _t("settings.subtitle")
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	main_vbox.add_child(content)

	var master_slider := _add_settings_slider(content, _t("settings.audio"), _t("settings.master_volume"), float(settings.get("master_volume", 1.0)))
	var music_slider := _add_settings_slider(content, "", _t("settings.music_volume"), float(settings.get("music_volume", 0.8)))
	var sfx_slider := _add_settings_slider(content, "", _t("settings.sfx_volume"), float(settings.get("sfx_volume", 0.8)))
	var mute_all := _add_settings_checkbox(content, "", _t("settings.mute_all"), bool(settings.get("mute_all", false)))

	var show_hand_hints := _add_settings_checkbox(content, _t("settings.gameplay"), _t("settings.show_hand_hints"), bool(settings.get("show_hand_hints", true)))
	var confirm_big_bets := _add_settings_checkbox(content, "", _t("settings.confirm_big_bets"), bool(settings.get("confirm_big_bets", true)))
	var animation_speed := _add_settings_option(content, "", _t("settings.animation_speed"), [
		{"label": _t("option.slow"), "value": "slow"},
		{"label": _t("option.normal"), "value": "normal"},
		{"label": _t("option.fast"), "value": "fast"},
	], str(settings.get("animation_speed", "normal")))

	var reduce_motion := _add_settings_checkbox(content, _t("settings.display"), _t("settings.reduce_motion"), bool(settings.get("reduce_motion", false)))
	var ui_scale := _add_settings_option(content, "", _t("settings.ui_scale"), [
		{"label": "100%", "value": 1.0},
		{"label": "110%", "value": 1.1},
		{"label": "120%", "value": 1.2},
	], float(settings.get("ui_scale", 1.0)), _t("settings.ui_scale_note"))
	var language_option := _add_settings_option(content, "", _t("settings.language"), LocalizationManagerScript.language_options(), str(settings.get("language_locale", LocalizationManagerScript.DEFAULT_LOCALE)), _t("settings.language_note"))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	main_vbox.add_child(footer)

	var reset_button := _settings_button(_t("common.reset_defaults"))
	reset_button.pressed.connect(func() -> void:
		var defaults := _settings_service.reset_defaults()
		LocalizationManagerScript.load_saved_locale(defaults)
		_refresh_settings_panel()
		_refresh_localized_ui(false)
		_apply_settings(defaults)
		_show_toast(_t("settings.reset"))
	)
	footer.add_child(reset_button)

	var apply_button := _settings_button(_t("common.apply"))
	apply_button.pressed.connect(func() -> void:
		var next_settings := {
			"master_volume": float(master_slider.value),
			"music_volume": float(music_slider.value),
			"sfx_volume": float(sfx_slider.value),
			"mute_all": mute_all.button_pressed,
			"show_hand_hints": show_hand_hints.button_pressed,
			"confirm_big_bets": confirm_big_bets.button_pressed,
			"animation_speed": str(animation_speed.get_meta("selected_value")),
			"ui_scale": float(ui_scale.get_meta("selected_value")),
			"reduce_motion": reduce_motion.button_pressed,
			"language_locale": str(language_option.get_meta("selected_value")),
		}
		var saved := _settings_service.save_settings(next_settings)
		LocalizationManagerScript.load_saved_locale(saved)
		_apply_settings(saved)
		_refresh_localized_ui(true)
		_show_toast(_t("settings.saved"))
	)
	footer.add_child(apply_button)

	var close_button := _settings_button(_t("common.close"))
	close_button.pressed.connect(func() -> void:
		set_state(LobbyState.COLLAPSED)
	)
	footer.add_child(close_button)

func _refresh_settings_panel() -> void:
	if _settings_panel == null:
		return
	_settings_panel.queue_free()
	_settings_panel = null
	_build_settings_panel()
	if current_state == LobbyState.SETTINGS:
		_settings_panel.visible = true
		_settings_panel.modulate.a = 1.0

func _refresh_localized_ui(refresh_settings_panel: bool = true) -> void:
	if _prompt != null:
		_prompt.text = _t("home.prompt")
	if _cta_button != null:
		_cta_button.text = _t("home.cta_play")
	if _top_bar != null and _top_bar.has_method("apply_localization"):
		_top_bar.call("apply_localization")
	if _left_nav != null and _left_nav.has_method("apply_localization"):
		_left_nav.call("apply_localization")
	if _play_panel != null:
		var title := _play_panel.get_node_or_null("ContentColumn/ChooseRoomTitle") as Label
		if title != null:
			title.text = _t("home.choose_room")
	var lobby_vm := MockDataProvider.get_lobby_view_model()
	var modes: Array = Array(lobby_vm.get("modes", []))
	for index in range(min(_mode_cards.size(), modes.size())):
		var mode_data := Dictionary(modes[index]).duplicate(true)
		mode_data["image"] = MODE_IMAGES.get(mode_data["id"], "")
		mode_data["title"] = _t("mode.%s.title" % str(mode_data["id"]))
		mode_data["subtitle"] = _t("mode.%s.subtitle" % str(mode_data["id"]))
		_mode_cards[index].configure(mode_data)
	_refresh_daily_bonus_bar()
	_rebuild_localized_store_profile_pages()
	_rebuild_localized_home_modals()
	if refresh_settings_panel and _settings_panel != null:
		_refresh_settings_panel()

func _rebuild_localized_store_profile_pages() -> void:
	var store_visible := _store_panel != null and _store_panel.visible
	var profile_visible := _profile_panel != null and _profile_panel.visible
	if _store_panel != null:
		_store_panel.queue_free()
		_store_panel = null
	if _profile_panel != null:
		_profile_panel.queue_free()
		_profile_panel = null
	_build_store_panel()
	_build_profile_panel()
	_store_panel.visible = store_visible
	_profile_panel.visible = profile_visible
	if store_visible:
		_store_panel.modulate.a = 1.0
	if profile_visible:
		_profile_panel.modulate.a = 1.0

func _rebuild_localized_home_modals() -> void:
	var social_visible := _social_panel != null and _social_panel.visible
	var help_visible := _help_panel != null and _help_panel.visible
	var events_visible := _events_panel != null and _events_panel.visible
	if _social_panel != null:
		_social_panel.queue_free()
		_social_panel = null
	if _help_panel != null:
		_help_panel.queue_free()
		_help_panel = null
	if _events_panel != null:
		_events_panel.queue_free()
		_events_panel = null
	_build_social_panel()
	_build_help_panel()
	_build_events_panel()
	_social_panel.visible = social_visible
	_help_panel.visible = help_visible
	_events_panel.visible = events_visible
	if events_visible:
		_events_panel.modulate.a = 1.0

func _apply_settings(settings: Dictionary) -> void:
	var normalized := SettingsServiceScript.normalize_settings(settings)
	if _settings_service != null:
		_settings_service.apply_safe_settings(normalized)
	set_background_motion_enabled(not bool(normalized.get("reduce_motion", false)))

func _add_settings_slider(parent: VBoxContainer, section_title: String, label_text: String, value: float) -> HSlider:
	_add_settings_section_label(parent, section_title)
	var row := _settings_row(parent, label_text)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = clampf(value, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(190, 34)
	row.add_child(slider)
	return slider

func _add_settings_checkbox(parent: VBoxContainer, section_title: String, label_text: String, value: bool) -> CheckBox:
	_add_settings_section_label(parent, section_title)
	var row := _settings_row(parent, label_text)
	var checkbox := CheckBox.new()
	checkbox.button_pressed = value
	checkbox.text = _t("option.on") if value else _t("option.off")
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(func(enabled: bool) -> void:
		checkbox.text = _t("option.on") if enabled else _t("option.off")
	)
	row.add_child(checkbox)
	return checkbox

func _add_settings_option(parent: VBoxContainer, section_title: String, label_text: String, options: Array, selected_value: Variant, note: String = "") -> OptionButton:
	_add_settings_section_label(parent, section_title)
	var row := _settings_row(parent, label_text, note)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(230, 34)
	option.focus_mode = Control.FOCUS_NONE
	var selected_index := 0
	for i in range(options.size()):
		var item := Dictionary(options[i])
		option.add_item(str(item.get("label", "")), i)
		option.set_item_metadata(i, item.get("value", ""))
		if bool(item.get("disabled", false)):
			option.set_item_disabled(i, true)
		if item.get("value", "") == selected_value:
			selected_index = i
	option.select(selected_index)
	option.set_meta("selected_value", option.get_item_metadata(selected_index))
	option.item_selected.connect(func(index: int) -> void:
		option.set_meta("selected_value", option.get_item_metadata(index))
	)
	row.add_child(option)
	return option

func _add_settings_section_label(parent: VBoxContainer, section_title: String) -> void:
	if section_title == "":
		return
	var label := Label.new()
	label.text = section_title
	HomeTheme.make_font_settings(label, 13, Color(1.0, 0.58, 0.92, 0.98))
	parent.add_child(label)

func _settings_row(parent: VBoxContainer, label_text: String, note: String = "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var label := Label.new()
	label.text = label_text
	HomeTheme.make_font_settings(label, 14, Color(0.92, 0.94, 1.0, 0.95))
	text_box.add_child(label)
	if note != "":
		var note_label := Label.new()
		note_label.text = note
		HomeTheme.make_font_settings(note_label, 11, HomeTheme.MUTED)
		text_box.add_child(note_label)
	return row

func _settings_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(130, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.72), Color(0.62, 0.36, 1.0, 0.55), 8))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.040, 0.046, 0.094, 0.92), Color(1.0, 0.28, 0.78, 0.90), 8))
	button.add_theme_stylebox_override("pressed", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.96), Color(0.52, 0.78, 1.0, 0.90), 8))
	return button
