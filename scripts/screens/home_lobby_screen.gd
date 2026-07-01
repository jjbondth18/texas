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
	FRIENDS_ROOM
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
	"buy_in": 10000,
	"small_blind": 50,
	"big_blind": 100,
	"max_hands": 10,
	"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
	"max_players": 9,
}

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
var _replay_panel: PanelContainer
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
var _bgm_player: AudioStreamPlayer

const MockDataProvider := preload("res://scripts/demo/mock_data_provider.gd")
const ScreenNavigator := preload("res://scripts/app/screen_navigator.gd")
const TableLaunchContext := preload("res://scripts/app/table_launch_context.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const StoreMockServiceScript := preload("res://scripts/services/store_mock_service.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const SettingsServiceScript := preload("res://scripts/services/settings_service.gd")
const PokerWsClientScript := preload("res://scripts/network/poker_ws_client.gd")
const NetworkConfigScript := preload("res://scripts/network/network_config.gd")
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
var _quick_play_mode := "chip"
var _selected_quick_buy_in := 20000
var _selected_quick_small_blind := 25
var _selected_quick_big_blind := 50
var _selected_quick_max_hands := 10
var _public_table_setup_panel: PanelContainer
var _private_room_setup_panel: PanelContainer
var _public_table_setup_values := {
	"buy_in": 10000,
	"small_blind": 50,
	"big_blind": 100,
	"max_hands": 10,
	"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
	"max_players": 6,
}
var _private_room_setup_values := {
	"buy_in": 20000,
	"small_blind": 50,
	"big_blind": 100,
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
	_build_background()
	_build_foreground()
	_build_layout()
	_build_play_panel()
	_build_room_browser_panel()
	_build_friends_room_panel()
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

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	var ogg = load("res://assets/music/bgm1.ogg") if ResourceLoader.exists("res://assets/music/bgm1.ogg") else AudioStreamOggVorbis.load_from_file(ProjectSettings.globalize_path("res://assets/music/bgm1.ogg"))
	if ogg:
		if ogg.has_method("set_loop"):
			ogg.set_loop(true)
		elif "loop" in ogg:
			ogg.loop = true
		_bgm_player.stream = ogg
	_bgm_player.finished.connect(func() -> void:
		_bgm_player.play()
	)
	add_child(_bgm_player)
	_bgm_player.play()
	_apply_settings(_settings_service.load_settings())
	
	var lobby_vm := MockDataProvider.get_lobby_view_model()
	_player_profile = ProfileServiceScript.new().get_current_profile()
	if server_authoritative_profile:
		_connect_profile_server()
	else:
		_claim_daily_login_bonus()
	lobby_vm["player"] = _player_profile
	_top_bar.configure(_player_profile)
	set_state(LobbyState.COLLAPSED, false)
	call_deferred("_show_pending_launch_error")
	_handle_runtime_capture_args()

func set_state(new_state: LobbyState, animated: bool = true) -> void:
	current_state = new_state
	if _quick_play_setup_panel != null and new_state != LobbyState.PLAY_EXPANDED:
		_quick_play_setup_panel.visible = false
	if new_state == LobbyState.PROFILE:
		_reload_player_profile()
	if new_state == LobbyState.ROOM_BROWSER:
		_request_server_table_list()
	
	var nav_id := "home"
	match current_state:
		LobbyState.COLLAPSED: nav_id = "home"
		LobbyState.PLAY_EXPANDED, LobbyState.ROOM_BROWSER, LobbyState.FRIENDS_ROOM: nav_id = "play"
		LobbyState.REPLAY: nav_id = "replay"
		LobbyState.STORE: nav_id = "store"
		LobbyState.PROFILE: nav_id = "profile"
		LobbyState.SETTINGS: nav_id = "settings"
	
	if _left_nav:
		_left_nav.set_active(nav_id)
		
	_set_expanded(current_state != LobbyState.COLLAPSED, not animated)

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
	_prompt.text = "Select PLAY to choose a table mode"
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
	title.text = "CHOOSE YOUR ROOM"
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
		card.configure(data_with_img)
		card.mode_selected.connect(_on_mode_selected)
		_mode_cards.append(card)
		card_row.add_child(card)

	_daily_bonus = preload("res://scenes/components/daily_bonus_bar.tscn").instantiate()
	_daily_bonus.name = "DailyBonusBar"
	_daily_bonus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_daily_bonus)


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
	title.text = "QUICK PLAY"
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
	chip_mode_note.text = "Quickly join an available public chip table with your selected stakes."
	chip_mode_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chip_mode_note.custom_minimum_size = Vector2(520, 0)
	HomeTheme.make_font_settings(chip_mode_note, 13, HomeTheme.MUTED)
	_quick_chip_settings_container.add_child(chip_mode_note)
	_build_quick_setup_section(_quick_chip_settings_container, "BUY-IN", _quick_buy_in_buttons, [5000, 10000, 20000, 50000], _select_quick_buy_in)
	_build_quick_blinds_section(_quick_chip_settings_container)
	_build_quick_setup_section(_quick_chip_settings_container, "HAND COUNT", _quick_hand_count_buttons, [5, 10, 20, 999], _select_quick_hand_count)

	_build_quick_gem_placeholder(column)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	column.add_child(button_row)

	var start_button := Button.new()
	_quick_start_button = start_button
	start_button.text = "FIND TABLE"
	start_button.custom_minimum_size = Vector2(180, 48)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_button.add_theme_font_size_override("font_size", 15)
	start_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.68), Color(1.0, 0.0, 0.5, 0.85), 22))
	start_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.86), Color(1.0, 0.0, 0.5, 1.0), 22))
	start_button.pressed.connect(_start_quick_play_from_setup)
	button_row.add_child(start_button)

	var cancel_button := Button.new()
	cancel_button.text = "CANCEL"
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

	_add_quick_mode_button(switch_row, "chip", "CHIP TABLE")
	_add_quick_mode_button(switch_row, "gem", "GEM MATCH")


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


func _build_quick_gem_placeholder(parent: VBoxContainer) -> void:
	_quick_gem_placeholder_container = VBoxContainer.new()
	_quick_gem_placeholder_container.visible = false
	_quick_gem_placeholder_container.custom_minimum_size = Vector2(1, 204)
	_quick_gem_placeholder_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_quick_gem_placeholder_container.add_theme_constant_override("separation", 10)
	parent.add_child(_quick_gem_placeholder_container)

	var mode_label := Label.new()
	mode_label.text = "GEM MATCH"
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(mode_label, 20, Color(1.0, 0.78, 0.98))
	_quick_gem_placeholder_container.add_child(mode_label)

	var coming_soon_label := Label.new()
	coming_soon_label.text = "Coming Soon"
	coming_soon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(coming_soon_label, 16, HomeTheme.GOLD)
	_quick_gem_placeholder_container.add_child(coming_soon_label)

	var detail_label := Label.new()
	detail_label.text = "Gem matches require secure server matchmaking. They will be available in a future update."
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(520, 0)
	HomeTheme.make_font_settings(detail_label, 14, HomeTheme.MUTED)
	_quick_gem_placeholder_container.add_child(detail_label)


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
	title.text = "CREATE PUBLIC TABLE" if public_table else "CREATE PRIVATE ROOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(title, 28, HomeTheme.TEXT)
	column.add_child(title)

	_add_table_setup_mode_switch(column, public_table, selected_mode)
	_add_table_setup_profile_row(column)

	var mode_note := Label.new()
	var buy_in := int(values.get("buy_in", 10000))
	var wallet_chips := _wallet_chips_for_public_chip_setup()
	var can_afford_public_buy_in := not public_table or gem_selected or _can_afford_public_buy_in(buy_in)
	if public_table:
		if gem_selected:
			mode_note.text = "Gem public tables require secure server matchmaking."
		elif not can_afford_public_buy_in:
			mode_note.text = "Not enough server wallet chips. Required: %s. Wallet: %s." % [_format_number(buy_in), _format_number(wallet_chips)]
		else:
			mode_note.text = "Create a public chip table with your selected stakes."
	else:
		mode_note.text = "Private casual room. Not listed in public tables." if not gem_selected else "Gem private rooms are reserved for future private match support."
	mode_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_note.custom_minimum_size = Vector2(520, 0)
	HomeTheme.make_font_settings(mode_note, 13, HomeTheme.MUTED)
	column.add_child(mode_note)

	_add_table_setup_option_row(column, values, "buy_in", "BUY-IN" if public_table else "STARTING STACK / BUY-IN", [5000, 10000, 20000, 50000], public_table)
	_add_blinds_setup_option_row(column, values, public_table)
	_add_table_setup_option_row(column, values, "max_hands", "HAND COUNT", [5, 10, 20, 999], public_table)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)

	var confirm := Button.new()
	confirm.text = "COMING SOON" if gem_selected else ("CREATE TABLE" if public_table else "CREATE ROOM")
	confirm.custom_minimum_size = Vector2(180, 48)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.disabled = gem_selected or (public_table and not can_afford_public_buy_in)
	confirm.mouse_default_cursor_shape = Control.CURSOR_ARROW if confirm.disabled else Control.CURSOR_POINTING_HAND
	confirm.add_theme_font_size_override("font_size", 15)
	confirm.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.68), Color(1.0, 0.0, 0.5, 0.85), 22))
	confirm.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.86), Color(1.0, 0.0, 0.5, 1.0), 22))
	confirm.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(Color(0.08, 0.06, 0.10, 0.62), Color(0.76, 0.52, 0.9, 0.28), 22))
	confirm.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.86, 0.72))
	confirm.pressed.connect(Callable(self, "_confirm_public_table_setup") if public_table else Callable(self, "_confirm_private_room_setup"))
	buttons.add_child(confirm)

	var cancel := Button.new()
	cancel.text = "CANCEL"
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
	var chip_button: Button = _table_setup_mode_button("CHIP TABLE", selected_mode == "chip", false)
	chip_button.pressed.connect(func() -> void:
		if public_table:
			_public_table_setup_mode = "chip"
		else:
			_private_room_setup_mode = "chip"
		_render_table_creation_setup_panel(_public_table_setup_panel if public_table else _private_room_setup_panel, public_table)
	)
	switch_row.add_child(chip_button)

	var gem_disabled: bool = public_table
	var gem_button: Button = _table_setup_mode_button("GEM MATCH", selected_mode == "gem", gem_disabled)
	gem_button.tooltip_text = "Gem public tables require secure server matchmaking." if public_table else "Gem private rooms are reserved for future private match support."
	gem_button.pressed.connect(func() -> void:
		if public_table:
			_show_toast("Gem public tables require secure server matchmaking.")
			return
		_private_room_setup_mode = "gem"
		_render_table_creation_setup_panel(_private_room_setup_panel, false)
	)
	switch_row.add_child(gem_button)


func _add_table_setup_profile_row(parent: VBoxContainer) -> void:
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
	chips_label.text = "%s: %s" % [_wallet_label_for_public_chip_setup(), _format_number(_wallet_chips_for_public_chip_setup())]
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
		var disabled := public_table and key == "buy_in" and not _can_afford_public_buy_in(option_value)
		button.disabled = disabled
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
		if disabled:
			button.tooltip_text = "Not enough server wallet chips."
			button.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(Color(0.012, 0.014, 0.028, 0.46), Color(0.34, 0.32, 0.48, 0.28), 18))
			button.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.68, 0.72))
		button.pressed.connect(func() -> void:
			if disabled:
				_show_toast("Not enough chips for this buy-in.")
				return
			values[key] = option_value
			_render_table_creation_setup_panel(_public_table_setup_panel if public_table else _private_room_setup_panel, public_table)
		)
		row.add_child(button)


func _add_blinds_setup_option_row(parent: VBoxContainer, values: Dictionary, public_table: bool) -> void:
	var label := Label.new()
	label.text = "BLINDS"
	HomeTheme.make_font_settings(label, 12, HomeTheme.MUTED)
	parent.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	for blind_pair in [[25, 50], [50, 100], [100, 200]]:
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
		return "Unlimited" if value >= 999 else "%d hands" % value
	if key == "max_players":
		return "%d players" % value
	return _format_number(value)


func _clear_node_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _build_quick_setup_section(parent: VBoxContainer, title_text: String, buttons: Dictionary, values: Array, callback: Callable) -> void:
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
		button.text = _quick_option_label(title_text, value)
		button.custom_minimum_size = Vector2(150, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 13)
		var captured_value: int = value
		button.pressed.connect(func() -> void: callback.call(captured_value))
		buttons[value] = button
		row.add_child(button)


func _build_quick_blinds_section(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "BLINDS"
	HomeTheme.make_font_settings(title, 12, HomeTheme.MUTED)
	parent.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var blind_pairs := [[25, 50], [50, 100], [100, 200]]
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
		_quick_blinds_buttons[key] = button
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
		_: return null

func _set_expanded(value: bool, immediate: bool = false) -> void:
	_expanded = value
	
	var prompt_target := 0.0 if value else 1.0
	var bg_target := Color(0.48, 0.45, 0.52, 1.0) if value else Color(1.34, 1.30, 1.40, 1.0)
	
	var logo_pos_y := LOGO_EXPANDED_Y if value else LOGO_COLLAPSED_Y
	var logo_scale := LOGO_EXPANDED_SCALE if value else LOGO_COLLAPSED_SCALE
	
	var active_panel := _get_panel_for_state(current_state)
	var all_panels := [_play_panel, _replay_panel, _store_panel, _profile_panel, _settings_panel, _room_browser_panel, _friends_room_panel]
	
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
			_show_coming_soon("EVENTS")
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
	if _quick_play_mode != "chip":
		return
	if not _can_afford_public_buy_in(_selected_quick_buy_in):
		_refresh_quick_play_setup_options()
		_show_toast("Not enough chips for this buy-in.")
		return
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		var table_name := "%s's Table" % PlayerProfileScript.get_player_name(_player_profile)
		_hide_quick_play_setup()
		_start_table_launch_transition("Creating server table...", func() -> void:
			_profile_ws_client.create_table(table_name, _quick_server_table_config())
		)
		return
	var setup_config := {
		"table_type": "public_chip",
		"currency": "chip",
		"buy_in": _selected_quick_buy_in,
		"small_blind": _selected_quick_small_blind,
		"big_blind": _selected_quick_big_blind,
		"hand_count": _normalized_hand_count_for_context(_selected_quick_max_hands),
		"max_hands": _selected_quick_max_hands,
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": int(DEFAULT_QUICK_PUBLIC_TABLE_CONFIG.get("max_players", 9)),
		"allow_quick_join": true,
		"buy_in_deducted_from_wallet": true,
	}
	_hide_quick_play_setup()
	_start_table_launch_transition("Finding a public chip table...", func() -> void:
		var context: Dictionary = _local_backend.quick_join_public_table(_player_profile, setup_config)
		if context.is_empty():
			_finish_table_launch_transition()
			_show_toast("No public table is available.")
			return
		if not bool(context.get("is_ai_warmup", false)):
			var service := ProfileServiceScript.new()
			var buy_in_profile: Dictionary = service.deduct_table_buy_in(_selected_quick_buy_in)
			if buy_in_profile.is_empty():
				_finish_table_launch_transition()
				_show_toast("Not enough wallet chips.")
				return
			_player_profile = buy_in_profile
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
	return {
		"table_type": "public_chip",
		"currency": "chip",
		"buy_in": _selected_quick_buy_in,
		"small_blind": _selected_quick_small_blind,
		"big_blind": _selected_quick_big_blind,
		"hand_count": hand_count,
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": int(DEFAULT_QUICK_PUBLIC_TABLE_CONFIG.get("max_players", 9)),
		"allow_quick_join": true,
		"is_public": true,
	}


func _update_quick_play_setup_profile() -> void:
	var player_name := PlayerProfileScript.get_player_name(_player_profile)
	var total_chips := _wallet_chips_for_public_chip_setup()
	_quick_play_setup_name_label.text = player_name
	_quick_play_setup_chips_label.text = "%s: %s" % [_wallet_label_for_public_chip_setup(), _format_number(total_chips)]
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

func _claim_daily_login_bonus() -> void:
	var service := ProfileServiceScript.new()
	_player_profile = service.claim_daily_login_bonus()
	if service.was_last_daily_bonus_claimed():
		_show_toast("Daily Login Bonus\n+%s Chips", [_format_number(PlayerProfileScript.DAILY_LOGIN_CHIPS)], 2.6)

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
	_profile_ws_client.daily_login_awarded.connect(_on_profile_server_daily_login_awarded)
	_profile_ws_client.avatar_catalog_received.connect(_on_avatar_catalog_received)
	_profile_ws_client.table_list_received.connect(_on_server_table_list_received)
	_profile_ws_client.table_created.connect(_on_server_table_created)
	_profile_ws_client.table_joined.connect(_on_server_table_joined)
	_profile_ws_client.mock_purchase_result_received.connect(_on_server_mock_purchase_result)
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

func _on_profile_server_wallet_synced(wallet: Dictionary) -> void:
	_player_profile = ProfileServiceScript.new().apply_wallet_snapshot(wallet)
	_profile_server_wallet_synced = true
	_refresh_profile_views_from_server()

func _on_profile_server_daily_login_awarded(chips: int) -> void:
	if chips > 0:
		_show_toast("Daily Bonus\n+%s Chips", [_format_number(chips)], 2.6)

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
		_show_toast("Server Profile\n%s", [message], 2.2)
	if _is_launching_table:
		_finish_table_launch_transition()

func _refresh_profile_views_from_server() -> void:
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()
	if _quick_play_setup_panel != null and _quick_play_setup_panel.visible:
		_update_quick_play_setup_profile()
		_refresh_quick_play_setup_options()
	if _public_table_setup_panel != null and _public_table_setup_panel.visible:
		_render_table_creation_setup_panel(_public_table_setup_panel, true)

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
	if max_hands <= 0:
		max_hands = 999
	return {
		"mode": "quick_play",
		"backend_type": "server_authoritative",
		"local_player_profile": _player_profile.duplicate(true),
		"table_id": room_id,
		"room_id": room_id,
		"seats": [],
		"buy_in": buy_in,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"action_time_seconds": action_time_seconds,
		"is_training": false,
		"table_type": "public_chip",
		"uses_practice_chips": false,
		"affects_account_balance": true,
		"buy_in_deducted_from_wallet": false,
		"allow_debug_tools": true,
		"requested_seat_index": requested_seat_index,
		"ai_player_count": 0,
		"max_hands": max_hands,
		"waiting_for_real_players": int(table_info.get("current_players", table_info.get("seated_count", 0))) < 2,
		"is_ai_warmup": false,
		"warmup_ai_player_ids": [],
		"table_session": {
			"mode": "quick_play",
			"table_type": "public_chip",
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
			"waiting_for_real_players": int(table_info.get("current_players", table_info.get("seated_count", 0))) < 2,
			"is_ai_warmup": false,
			"warmup_ai_player_ids": [],
		},
	}


func _select_default_quick_buy_in() -> void:
	var total_chips := _wallet_chips_for_public_chip_setup()
	var best := 0
	for option in [5000, 10000, 20000, 50000]:
		var value: int = int(option)
		if value <= total_chips and value <= 20000:
			best = value
	if best == 0:
		for option in [5000, 10000, 20000, 50000]:
			var value: int = int(option)
			if value <= total_chips:
				best = max(best, value)
	_selected_quick_buy_in = best if best > 0 else 5000


func _select_quick_buy_in(value: int) -> void:
	if not _can_afford_public_buy_in(value):
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
	_refresh_quick_play_setup_options()


func _refresh_quick_play_setup_options() -> void:
	var is_chip_mode := _quick_play_mode == "chip"
	var total_chips := _wallet_chips_for_public_chip_setup()
	if _quick_chip_settings_container != null:
		_quick_chip_settings_container.visible = is_chip_mode
	if _quick_gem_placeholder_container != null:
		_quick_gem_placeholder_container.visible = not is_chip_mode
	if _quick_start_button != null:
		_quick_start_button.disabled = not is_chip_mode or _selected_quick_buy_in > total_chips
		_quick_start_button.text = "FIND TABLE" if is_chip_mode else "COMING SOON"
		_quick_start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_chip_mode else Control.CURSOR_ARROW
		_quick_start_button.add_theme_stylebox_override("disabled", HomeTheme.make_button_style(Color(0.08, 0.06, 0.10, 0.62), Color(0.76, 0.52, 0.9, 0.28), 22))
		_quick_start_button.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.86, 0.72))
	if _quick_play_setup_hint_label != null:
		if not is_chip_mode:
			_quick_play_setup_hint_label.text = "Gem matches require secure server matchmaking and will be available in a future update."
		elif _selected_quick_buy_in > total_chips:
			_quick_play_setup_hint_label.text = "Not enough server wallet chips."
		else:
			_quick_play_setup_hint_label.text = "Quickly join an available public chip table with your selected stakes.\nBuy-in will be moved from wallet to table. Unused table chips return to wallet after the session."
	for key_item in _quick_mode_buttons.keys():
		var mode := str(key_item)
		var button: Button = _quick_mode_buttons[key_item] as Button
		_apply_quick_mode_style(button, mode == _quick_play_mode)
	for key_item in _quick_buy_in_buttons.keys():
		var value: int = int(key_item)
		var button: Button = _quick_buy_in_buttons[key_item] as Button
		if button == null:
			continue
		var disabled: bool = value > total_chips
		_apply_quick_option_style(button, value == _selected_quick_buy_in, disabled)
	for key_item in _quick_blinds_buttons.keys():
		var key: String = str(key_item)
		var button: Button = _quick_blinds_buttons[key_item] as Button
		if button == null:
			continue
		_apply_quick_option_style(button, key == "%d/%d" % [_selected_quick_small_blind, _selected_quick_big_blind], false)
	for key_item in _quick_hand_count_buttons.keys():
		var value: int = int(key_item)
		var button: Button = _quick_hand_count_buttons[key_item] as Button
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


func _quick_option_label(title_text: String, value: int) -> String:
	if title_text == "HAND COUNT" and value >= 999:
		return "Unlimited"
	if title_text == "HAND COUNT":
		return "%d hands" % value
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
	_friends_room_context = _local_backend.create_friends_room(_player_profile)
	_update_friends_room_panel()
	set_state(LobbyState.FRIENDS_ROOM)


func _confirm_public_table_setup() -> void:
	if _public_table_setup_mode == "gem":
		_show_toast("Gem public tables require secure server matchmaking.")
		return
	var buy_in: int = int(_public_table_setup_values.get("buy_in", 10000))
	if not _can_afford_public_buy_in(buy_in):
		_show_toast("Not enough chips for this buy-in.")
		_render_table_creation_setup_panel(_public_table_setup_panel, true)
		return
	_hide_table_creation_setup_panels()
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		_start_table_launch_transition("Creating public table...", func() -> void:
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
		_show_toast("Not enough wallet chips.")
		return
	_start_table_launch_transition("Creating public table...", func() -> void:
		var table: Dictionary = _local_backend.create_public_table(_public_table_config_from_values(_public_table_setup_values))
		_join_public_chip_table_after_wallet_check(str(table.get("table_id", "")))
	)


func _confirm_private_room_setup() -> void:
	if _private_room_setup_mode == "gem":
		_show_toast("Gem private rooms are reserved for future private match support.")
		return
	_hide_table_creation_setup_panels()
	_start_table_launch_transition("Creating private room...", func() -> void:
		_friends_room_context = _local_backend.create_friends_room(_player_profile, _private_room_config_from_values())
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
		"buy_in": int(values.get("buy_in", 10000)),
		"hand_count": int(values.get("max_hands", 10)),
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": int(values.get("max_players", 6)),
		"created_by": str(_player_profile.get("player_id", "local_player")),
		"allow_quick_join": true,
	}


func _private_room_config_from_values() -> Dictionary:
	return {
		"buy_in": int(_private_room_setup_values.get("buy_in", 20000)),
		"small_blind": int(_private_room_setup_values.get("small_blind", 50)),
		"big_blind": int(_private_room_setup_values.get("big_blind", 100)),
		"max_hands": int(_private_room_setup_values.get("max_hands", 10)),
		"action_time_seconds": DEFAULT_ACTION_TIME_SECONDS,
		"max_players": int(_private_room_setup_values.get("max_players", 6)),
	}


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
	pass

func _build_cta_button() -> void:
	_cta_button = Button.new()
	_cta_button.name = "LobbyCTAButton"
	_cta_button.text = "→  CLICK PLAY TO START"
	
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
		_show_toast("This table is no longer available.")
		_refresh_room_browser_rows()
		return
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		var buy_in: int = int(table_info.get("buy_in", 10000))
		if not _can_afford_public_buy_in(buy_in):
			_show_toast("Not enough chips for this buy-in.")
			return
		_start_table_launch_transition("Joining server table...", func() -> void:
			_profile_ws_client.join_table(room_id)
		)
		return
	_start_table_launch_transition("Joining public table...", func() -> void:
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
	var buy_in: int = int(table_info.get("buy_in", 10000))
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
	title.text = "SOCIAL"
	HomeTheme.make_font_settings(title, 24, Color(1, 1, 1, 0.96))
	column.add_child(title)
	var copy := Label.new()
	copy.text = "Friends and messages will be available in a future update."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(copy, 15, Color(0.82, 0.86, 1.0, 0.92))
	column.add_child(copy)
	column.add_child(_modal_spacer())
	var close_button := _modal_button("Close")
	close_button.pressed.connect(func() -> void:
		_social_panel.visible = false
	)
	column.add_child(close_button)

func _build_help_panel() -> void:
	_help_panel = _create_home_modal("HelpRulesPanel", Vector2(760, 620))
	var column := _modal_column(_help_panel)
	var title := Label.new()
	title.text = "HELP & RULES"
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
	_add_help_section(content, "Poker Basics", [
		"Each player gets 2 private cards.",
		"Use community cards to make the best 5-card hand.",
		"Betting rounds: Pre-Flop, Flop, Turn, River.",
	])
	_add_help_section(content, "Hand Rankings", [
		"Royal Flush",
		"Straight Flush",
		"Four of a Kind",
		"Full House",
		"Flush",
		"Straight",
		"Three of a Kind",
		"Two Pair",
		"One Pair",
		"High Card",
	])
	_add_help_section(content, "Game Modes", [
		"Quick Chip auto-joins a public chip table.",
		"Table Browser lets you choose public chip tables.",
		"Friends Room is private and uses a room code.",
		"Training uses practice chips only.",
		"Gem Match is Coming Soon and requires secure server matchmaking.",
	])
	_add_help_section(content, "Chips & Gems", [
		"Chips are used for public table buy-ins and betting.",
		"Gems are reserved for future premium features such as Replay access.",
		"Add Chips moves chips from wallet to table. It is not a purchase.",
	])
	_add_help_section(content, "Table Rules", [
		"Leaving during a hand folds your hand.",
		"Chips already committed stay in the pot.",
		"Timeout may auto-check or auto-fold.",
		"Repeated timeouts may put you in Sit Out.",
	])

	var close_button := _modal_button("Close")
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
	title.text = "ROOM BROWSER"
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = "PUBLIC CHIP TABLES - BROWSE, CREATE, OR JOIN"
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	var browser_note := Label.new()
	browser_note.text = "Public chip tables. Create a table or join one manually. Quick Chip players may also be seated into these tables."
	HomeTheme.make_font_settings(browser_note, 12, Color(0.72, 0.78, 0.94, 0.92))
	title_box.add_child(browser_note)

	var create_button := Button.new()
	create_button.text = "CREATE PUBLIC TABLE"
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
	var headers := ["ROOM NAME", "BLINDS", "PLAYERS", "BUY-IN LIMITS", ""]
	
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
	if rooms.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No public tables yet. Create one to start a server-authoritative room." if _profile_server_connected else "Server unavailable. Showing local mock fallback when available."
		empty_label.custom_minimum_size = Vector2(0, 54)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		HomeTheme.make_font_settings(empty_label, 13, HomeTheme.MUTED)
		_room_browser_list_vbox.add_child(empty_label)
		return
	var visible_count := 0
	for room_value in rooms:
		var normalized_room: Dictionary = _normalized_room_browser_table(Dictionary(room_value))
		if not _is_joinable_room_browser_table(normalized_room):
			continue
		_add_room_browser_row(normalized_room)
		visible_count += 1
	if visible_count == 0:
		var filtered_empty_label := Label.new()
		filtered_empty_label.text = "No clean public chip tables are available. Create a new table to start fresh."
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
		"table_name": str(room.get("table_name", room_id if room_id != "" else "Public Table")),
		"table_type": str(room.get("table_type", "public_chip")),
		"currency": str(room.get("currency", "chip")),
		"small_blind": int(room.get("small_blind", 10)),
		"big_blind": int(room.get("big_blind", 20)),
		"buy_in": int(room.get("buy_in", 1000)),
		"seated_count": seated_count,
		"max_players": max_players,
		"hand_state": hand_state,
		"status": "full" if seated_count >= max_players else status,
		"is_ai_warmup": bool(room.get("is_ai_warmup", false)),
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
	if str(room.get("table_type", "public_chip")) != "public_chip":
		return false
	if str(room.get("currency", "chip")) != "chip":
		return false
	var status := str(room.get("status", ""))
	var hand_state := str(room.get("hand_state", status))
	if status in ["full", "closed", "dirty", "paused", "hand_over", "showdown_reveal", "showdown", "finished"]:
		return false
	if hand_state in ["closed", "dirty", "paused", "hand_over", "showdown_reveal", "finished"]:
		return false
	if status not in ["waiting", "waiting_for_players", "waiting_ready", "starting_countdown", "hand_result", "ready_to_start", "open", "playing", "ai_warmup"]:
		return false
	if hand_state not in ["waiting", "waiting_for_players", "waiting_ready", "starting_countdown", "hand_result", "ready_to_start", "open", "playing", "preflop", "flop", "turn", "river", "showdown", "ai_warmup", "idle", "pre_hand"]:
		return false
	if int(room.get("current_turn_seat", -1)) == -1 and hand_state not in ["waiting", "waiting_for_players", "waiting_ready", "starting_countdown", "hand_result", "ready_to_start", "open", "playing", "preflop", "flop", "turn", "river", "showdown", "ai_warmup", "idle", "pre_hand"]:
		return false
	if int(room.get("seated_count", 0)) >= int(room.get("max_players", 6)):
		return false
	if int(room.get("seated_count", 0)) <= 0 and (not Array(room.get("players", [])).is_empty() or not Array(room.get("seats", [])).is_empty()) and _connected_room_player_count(room) > 0:
		return false
	return true

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
	name_lbl.text = str(room.get("table_name", "Public Table"))
	HomeTheme.make_font_settings(name_lbl, 15, Color(1, 1, 1, 0.95))
	name_box.add_child(name_lbl)
	var public_badge := Label.new()
	public_badge.text = "WARM-UP / WAITING FOR PLAYERS" if bool(room.get("host_in_local_warmup", false)) else ("SERVER PUBLIC CHIP" if _profile_server_connected else "LOCAL MOCK CHIP")
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
	buyin_lbl.text = "%d Chips" % int(room.get("buy_in", 1000))
	buyin_lbl.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[3], 0)
	HomeTheme.make_font_settings(buyin_lbl, 14, Color(0.85, 0.90, 1.0))
	row_hbox.add_child(buyin_lbl)
	var btn_container := CenterContainer.new()
	btn_container.custom_minimum_size = Vector2(ROOM_BROWSER_COL_WIDTHS[4], 0)
	row_hbox.add_child(btn_container)
	var join_btn := Button.new()
	join_btn.text = "JOIN"
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
	title.text = "FRIENDS ROOM"
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	content.add_child(title)

	var sub := Label.new()
	sub.text = "PRIVATE CASUAL ROOM - SHARE THE ROOM CODE WITH FRIENDS"
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	content.add_child(sub)
	var room_note := Label.new()
	room_note.text = "Not listed in public tables. Gem private rooms are reserved for future support."
	HomeTheme.make_font_settings(room_note, 12, Color(0.72, 0.78, 0.94, 0.92))
	content.add_child(room_note)

	var room_card := PanelContainer.new()
	room_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room_card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	content.add_child(room_card)

	var room_box := VBoxContainer.new()
	room_box.add_theme_constant_override("separation", 12)
	room_card.add_child(room_box)

	_friends_room_id_label = _room_lobby_label("ROOM ID: -", 17, Color(1.0, 0.92, 0.72, 0.96))
	_friends_room_seats_label = _room_lobby_label("SEATS: -", 15, Color(0.88, 0.92, 1.0, 0.92))
	_friends_room_ready_label = _room_lobby_label("READY: -", 15, HomeTheme.PURPLE)
	room_box.add_child(_room_lobby_label("PRIVATE CASUAL", 13, HomeTheme.CYAN))
	room_box.add_child(_friends_room_id_label)
	room_box.add_child(_friends_room_seats_label)
	room_box.add_child(_friends_room_ready_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	room_box.add_child(button_row)

	var start_button := Button.new()
	start_button.text = "CREATE PRIVATE ROOM"
	start_button.custom_minimum_size = Vector2(190, 42)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_button.add_theme_font_size_override("font_size", 13)
	start_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	start_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 21))
	start_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.82), Color(1.0, 0.0, 0.5, 1.0), 21))
	start_button.pressed.connect(_show_private_room_setup)
	button_row.add_child(start_button)

	var back_button := Button.new()
	back_button.text = "BACK"
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
	_friends_room_id_label.text = "ROOM ID: %s" % str(_friends_room_context.get("room_id", "-"))
	_friends_room_seats_label.text = "SEATS: %d / 9" % occupied
	_friends_room_ready_label.text = "READY: Seat 5 local player"

func _build_replay_panel() -> void:
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
	title.text = "REPLAY ROOM"
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	
	var sub := Label.new()
	sub.text = "HAND REVIEW & PERFORMANCE ANALYSIS"
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	
	var content_hbox := HBoxContainer.new()
	content_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(content_hbox)
	
	# Left: Hand list
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(400, 0)
	list_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	list_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	content_hbox.add_child(list_panel)
	
	var list_scroll := ScrollContainer.new()
	list_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	list_panel.add_child(list_scroll)
	
	var list_vbox := VBoxContainer.new()
	list_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 10)
	list_scroll.add_child(list_vbox)
	
	var mock_hands := [
		{"id": "#1482", "mode": "Quick Play", "result": "+3,450 Chips", "win": true, "time": "2 mins ago"},
		{"id": "#1481", "mode": "Cash Table", "result": "-1,250 Chips", "win": false, "time": "12 mins ago"},
		{"id": "#1480", "mode": "Private Table", "result": "+800 Chips", "win": true, "time": "45 mins ago"},
		{"id": "#1479", "mode": "Quick Play", "result": "+450 Chips", "win": true, "time": "1 hour ago"},
		{"id": "#1478", "mode": "Training", "result": "+1,200 Chips", "win": true, "time": "2 hours ago"}
	]
	
	for hand in mock_hands:
		var item := PanelContainer.new()
		item.custom_minimum_size = Vector2(0, 72)
		item.mouse_filter = Control.MOUSE_FILTER_PASS
		item.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.016, 0.035, 0.65), Color(0.3, 0.35, 0.55, 0.15), 6, 1))
		var item_hbox := HBoxContainer.new()
		item_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		item_hbox.add_theme_constant_override("separation", 10)
		item.add_child(item_hbox)
		
		var icon_rect := ColorRect.new()
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.color = Color(0.18, 0.22, 0.38, 0.45)
		item_hbox.add_child(icon_rect)
		
		var desc_vbox := VBoxContainer.new()
		desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_hbox.add_child(desc_vbox)
		
		var item_title := Label.new()
		item_title.text = "Hand " + hand["id"] + " (" + hand["mode"] + ")"
		HomeTheme.make_font_settings(item_title, 13, Color(0.9, 0.92, 0.98))
		desc_vbox.add_child(item_title)
		
		var item_time := Label.new()
		item_time.text = hand["time"]
		HomeTheme.make_font_settings(item_time, 11, HomeTheme.MUTED)
		desc_vbox.add_child(item_time)
		
		var item_res := Label.new()
		item_res.text = hand["result"]
		HomeTheme.make_font_settings(item_res, 13, Color(0.2, 0.8, 0.3) if hand["win"] else HomeTheme.PINK)
		item_hbox.add_child(item_res)
		
		list_vbox.add_child(item)
		
	# Right: Hand Preview & Premium Lock Module
	var right_vbox := VBoxContainer.new()
	right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 16)
	content_hbox.add_child(right_vbox)
	
	# Preview Box
	var prev_box := PanelContainer.new()
	prev_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_box.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.012, 0.50), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	var prev_vbox := VBoxContainer.new()
	prev_vbox.add_theme_constant_override("separation", 12)
	prev_box.add_child(prev_vbox)
	
	var prev_title := Label.new()
	prev_title.text = "HAND REVIEW — HAND #1482"
	HomeTheme.make_font_settings(prev_title, 16, HomeTheme.CYAN)
	prev_vbox.add_child(prev_title)
	
	var cards_hbox := HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 15)
	prev_vbox.add_child(cards_hbox)
	
	var cards_desc := Label.new()
	cards_desc.text = "Hero Pocket: [A♠, K♥]  |  Board: [Q♦, J♥, 10♣, 7♠, 2♣]"
	HomeTheme.make_font_settings(cards_desc, 13, Color(0.85, 0.90, 1.0))
	cards_hbox.add_child(cards_desc)
	
	var showdown_desc := Label.new()
	showdown_desc.text = "Showdown: Hero wins pot of 3,450 Chips with Straight (Ace High)."
	HomeTheme.make_font_settings(showdown_desc, 13, Color(0.72, 0.76, 0.92))
	prev_vbox.add_child(showdown_desc)
	
	right_vbox.add_child(prev_box)
	
	# Equity Timeline Premium Lock Box
	var equity_box := PanelContainer.new()
	equity_box.custom_minimum_size = Vector2(0, 200)
	equity_box.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.014, 0.008, 0.022, 0.85), Color(1.0, 0.0, 0.5, 0.35), 8, 1.5))
	var eq_vbox := VBoxContainer.new()
	eq_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	eq_vbox.add_theme_constant_override("separation", 10)
	equity_box.add_child(eq_vbox)
	
	var eq_title := Label.new()
	eq_title.text = "🔒 STREET-BY-STREET EQUITY TIMELINE"
	HomeTheme.make_font_settings(eq_title, 15, HomeTheme.PINK)
	eq_vbox.add_child(eq_title)
	
	var eq_lock_desc := Label.new()
	eq_lock_desc.text = "Unlock Replay Pro to view street-by-street win probability graphs, range charts, and premium GTO analysis."
	eq_lock_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_lock_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(eq_lock_desc, 12, HomeTheme.MUTED)
	eq_vbox.add_child(eq_lock_desc)
	
	var upgrade_btn := Button.new()
	upgrade_btn.text = "UPGRADE TO REPLAY PRO"
	upgrade_btn.custom_minimum_size = Vector2(240, 36)
	upgrade_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	upgrade_btn.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.016, 0.018, 0.048, 0.56), Color(1.0, 0.0, 0.5, 0.80), 18))
	upgrade_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	upgrade_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	upgrade_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	eq_vbox.add_child(upgrade_btn)
	
	right_vbox.add_child(equity_box)

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
	title.text = "STORE"
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = "Mock wallet packs for local development testing."
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)
	
	var dev_label := Label.new()
	dev_label.text = "MOCK PURCHASE / DEV ONLY"
	HomeTheme.make_font_settings(dev_label, 13, HomeTheme.GOLD)
	main_vbox.add_child(dev_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	main_vbox.add_child(tabs)
	for tab_name in ["CHIPS", "GEMS"]:
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

	_add_store_currency_column(grid, "CHIPS", "Mock Purchase Chips\nDEV ONLY\nGame chips are used for buy-ins, betting, and standard cosmetics.", [10000, 50000, 100000], "chips", HomeTheme.GOLD)
	_add_store_currency_column(grid, "GEMS", "Mock Purchase Gems\nDEV ONLY\nGems are used for premium features such as replay access in future versions.", [100, 500, 1200], "gems", HomeTheme.PINK)

func _add_store_currency_column(parent: Container, title_text: String, desc_text: String, packs: Array, currency: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.012, 0.016, 0.035, 0.70), accent.darkened(0.25), 8, 1))
	parent.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)
	var title := Label.new()
	title.text = "Mock Purchase %s" % title_text.capitalize()
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
		button.text = "Mock Buy %s %s" % [_format_number(amount), title_text.capitalize()]
		button.custom_minimum_size = Vector2(220, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.70), accent.darkened(0.10), 18))
		button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.035, 0.04, 0.085, 0.86), accent, 18))
		button.pressed.connect(_show_mock_purchase_confirm.bind(currency, amount))
		vbox.add_child(button)

func _show_mock_purchase_confirm(currency: String, amount: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Mock purchase?"
	var target := "server wallet" if server_authoritative_profile and _profile_server_connected else "local wallet"
	dialog.dialog_text = "MOCK PURCHASE / DEV ONLY\nThis is a mock purchase for development only.\nAdd %s %s to your %s?" % [_format_number(amount), currency.to_upper(), target]
	dialog.confirmed.connect(_confirm_mock_purchase.bind(currency, amount, dialog))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2(360, 180))

func _confirm_mock_purchase(currency: String, amount: int, dialog: ConfirmationDialog) -> void:
	if server_authoritative_profile and _profile_server_connected and _profile_ws_client != null:
		var err := _profile_ws_client.mock_purchase(currency, amount)
		if err == OK:
			_show_toast("Mock purchase sent to server wallet.", [], 1.4)
		else:
			_show_toast("Mock purchase failed.\nServer wallet sync failed.", [], 2.4)
		if dialog != null:
			dialog.queue_free()
		return
	var store := StoreMockServiceScript.new()
	if currency == "gems":
		_player_profile = store.mock_purchase_gems(amount)
	else:
		_player_profile = store.mock_purchase_chips(amount)
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()
	if dialog != null:
		dialog.queue_free()

func _on_server_mock_purchase_result(ok: bool, currency: String, amount: int, wallet: Dictionary) -> void:
	if not ok:
		_show_toast("Mock purchase failed.", [], 2.4)
		return
	if not wallet.is_empty():
		_player_profile = ProfileServiceScript.new().apply_wallet_snapshot(wallet)
		_refresh_profile_views_from_server()
	var label := "Gems" if currency == "gems" else "Chips"
	_show_toast("Mock purchase complete.\n+%s %s added to server wallet.", [_format_number(amount), label], 2.8)

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
	title.text = "PLAYER PROFILE"
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = "STATISTICS & UNLOCKED ACHIEVEMENTS"
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
	s_title.text = "OVERVIEW & STATS"
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
	gallery_title.text = "CHARACTER AVATARS"
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
	ach_title.text = "ACHIEVEMENTS"
	HomeTheme.make_font_settings(ach_title, 16, HomeTheme.PURPLE)
	r_vbox.add_child(ach_title)
	
	var achievements := [
		"🏆 First Blood: Win a hand in Quick Play (Unlocked)",
		"🏆 Showdown Master: Win with a Royal Flush (Locked)"
	]
	for ach in achievements:
		var a_lbl := Label.new()
		a_lbl.text = ach
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
			return "TOTAL CHIPS"
		"total_sessions_played":
			return "TOTAL SESSIONS"
		"total_hands_played":
			return "TOTAL HANDS"
		"total_hands_won":
			return "HANDS WON"
		"win_rate":
			return "WIN RATE"
		"total_profit":
			return "TOTAL PROFIT"
		"biggest_pot":
			return "BIGGEST POT"
		"best_session_profit":
			return "BEST SESSION PROFIT"
		"best_hand_desc":
			return "BEST HAND"
		_:
			return stat_id.to_upper()

func _refresh_profile_panel() -> void:
	if _player_profile.is_empty():
		_player_profile = ProfileServiceScript.new().get_current_profile()
	if _profile_name_label != null:
		_profile_name_label.text = PlayerProfileScript.get_player_name(_player_profile)
	if _profile_level_label != null:
		_profile_level_label.text = "Level %d  |  XP %d / %d" % [
			int(_player_profile.get("level", PlayerProfileScript.DEFAULT_LEVEL)),
			int(_player_profile.get("xp_current", PlayerProfileScript.DEFAULT_XP_CURRENT)),
			int(_player_profile.get("xp_max", PlayerProfileScript.DEFAULT_XP_MAX)),
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
			_profile_avatar_name_label.text = "Selected Avatar: %s" % AvatarLibraryScript.display_name_for_avatar_id(selected_avatar_id)
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
		button.text = AvatarLibraryScript.display_name_for_avatar_id(avatar_id)
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
		button.disabled = not is_unlocked and not _profile_server_connected
		var display_name: String = AvatarLibraryScript.display_name_for_avatar_id(avatar_id)
		var status_text := "Unlocked"
		if is_selected:
			status_text = "Selected"
		elif not is_unlocked:
			if _profile_server_connected:
				status_text = "Buy %s" % _avatar_price_text(avatar_id)
			else:
				status_text = "Locked"
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
			_show_toast("Avatar\nSelecting on server...", [], 1.4)
		else:
			_profile_ws_client.buy_avatar(_server_avatar_id_for_client(avatar_id))
			_show_toast("Avatar\nPurchase request sent...", [], 1.4)
		return
	var service := ProfileServiceScript.new()
	_player_profile = service.select_avatar(avatar_id)
	if _top_bar != null:
		_top_bar.configure(_player_profile)
	_refresh_profile_panel()

func _avatar_price_text(avatar_id: String) -> String:
	var item := _catalog_item_for_avatar(avatar_id)
	if item.is_empty():
		return "Locked"
	var currency := str(item.get("currency", "free"))
	if currency == "chips":
		return "%s Chips" % _format_number(int(item.get("price_chips", 0)))
	if currency == "gems":
		return "%s Gems" % _format_number(int(item.get("price_gems", 0)))
	return "Free"

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
	title.text = "SETTINGS"
	HomeTheme.make_font_settings(title, 20, Color(1, 1, 1, 0.95))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = "LOCAL PREFERENCES ONLY. ECONOMY, TABLE RULES, AND SERVER MODE ARE UNCHANGED."
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	main_vbox.add_child(content)

	var master_slider := _add_settings_slider(content, "AUDIO", "Master Volume", float(settings.get("master_volume", 1.0)))
	var music_slider := _add_settings_slider(content, "", "Music Volume", float(settings.get("music_volume", 0.8)))
	var sfx_slider := _add_settings_slider(content, "", "SFX Volume", float(settings.get("sfx_volume", 0.8)))
	var mute_all := _add_settings_checkbox(content, "", "Mute All", bool(settings.get("mute_all", false)))

	var show_hand_hints := _add_settings_checkbox(content, "GAMEPLAY", "Show Hand Hints", bool(settings.get("show_hand_hints", true)))
	var confirm_big_bets := _add_settings_checkbox(content, "", "Confirm Big Bets", bool(settings.get("confirm_big_bets", true)))
	var animation_speed := _add_settings_option(content, "", "Animation Speed", [
		{"label": "Slow", "value": "slow"},
		{"label": "Normal", "value": "normal"},
		{"label": "Fast", "value": "fast"},
	], str(settings.get("animation_speed", "normal")))

	var reduce_motion := _add_settings_checkbox(content, "DISPLAY", "Reduce Motion", bool(settings.get("reduce_motion", false)))
	var ui_scale := _add_settings_option(content, "", "UI Scale", [
		{"label": "100%", "value": 1.0},
		{"label": "110%", "value": 1.1},
		{"label": "120%", "value": 1.2},
	], float(settings.get("ui_scale", 1.0)), "Saved locally. Applied in future UI scale pass.")

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	main_vbox.add_child(footer)

	var reset_button := _settings_button("Reset Defaults")
	reset_button.pressed.connect(func() -> void:
		var defaults := _settings_service.reset_defaults()
		_refresh_settings_panel()
		_apply_settings(defaults)
		_show_toast("Settings reset. Profile and wallet were not changed.")
	)
	footer.add_child(reset_button)

	var apply_button := _settings_button("Apply")
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
		}
		var saved := _settings_service.save_settings(next_settings)
		_apply_settings(saved)
		_show_toast("Settings saved locally.")
	)
	footer.add_child(apply_button)

	var close_button := _settings_button("Close")
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

func _apply_settings(settings: Dictionary) -> void:
	var normalized := SettingsServiceScript.normalize_settings(settings)
	if _settings_service != null:
		_settings_service.apply_safe_settings(normalized)
	set_background_motion_enabled(not bool(normalized.get("reduce_motion", false)))
	if _bgm_player != null:
		var master := 0.0 if bool(normalized.get("mute_all", false)) else float(normalized.get("master_volume", 1.0))
		var lobby_music_volume := clampf(master * float(normalized.get("music_volume", 0.8)), 0.0, 1.0)
		_bgm_player.volume_db = -80.0 if lobby_music_volume <= 0.0 else linear_to_db(lobby_music_volume)

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
	checkbox.text = "On" if value else "Off"
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(func(enabled: bool) -> void:
		checkbox.text = "On" if enabled else "Off"
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
