extends Control
class_name HomeLobbyScreen

@export var background_motion_enabled := false

const BACKGROUND_TEXTURE_PATH := "res://assets/home_lobby/backgrounds/home_background_v1.png"
const NAV_WIDTH := 280.0
const MAIN_LEFT := 360.0
const MAIN_RIGHT := 70.0

var _background_root: Control
var _lobby_ui_root: Control
var _left_nav: LeftNavRail
var _top_bar: TopBar
var _center_brand: Control
var _logo_fallback: Control
var _prompt: Label
var _play_panel: PanelContainer
var _welcome_pack: PanelContainer
var _daily_bonus: Control
var _mode_cards: Array[ModeCard] = []
var _foreground_decor: TextureRect
var _expanded := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_foreground()
	_build_layout()
	_build_play_panel()
	_top_bar.configure(MockHomeData.player())
	_left_nav.set_active("home")
	_set_expanded(false, true)
	_handle_runtime_capture_args()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.alt_pressed and event.keycode == KEY_ENTER:
			_toggle_window_mode()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _build_background() -> void:
	_background_root = Control.new()
	_background_root.name = "BackgroundRoot"
	_background_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background_root)
	var base := TextureRect.new()
	base.name = "BackgroundTexture"
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.texture = load(BACKGROUND_TEXTURE_PATH)
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	base.modulate = Color(1.34, 1.30, 1.40, 1.0)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_root.add_child(base)
	var center_lift := ColorRect.new()
	center_lift.name = "BackgroundCenterLift"
	center_lift.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_lift.color = Color(0.06, 0.08, 0.18, 0.08)
	center_lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_root.add_child(center_lift)

func _build_layout() -> void:
	_lobby_ui_root = Control.new()
	_lobby_ui_root.name = "LobbyUIRoot"
	_lobby_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lobby_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lobby_ui_root)

	_left_nav = preload("res://scenes/components/left_nav_rail.tscn").instantiate() as LeftNavRail
	_left_nav.name = "LeftNavRail"
	_left_nav.anchor_bottom = 1.0
	_left_nav.offset_right = NAV_WIDTH
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
	_logo_fallback.add_child(_make_logo_label("LogoMainShadow", "TEXAS\nHOLD'EM", 116, Color(0.0, 0.0, 0.03, 0.72), 0, Vector2(5, 7), 0.08, 0.78))
	_logo_fallback.add_child(_make_logo_label("LogoMainGlow", "TEXAS\nHOLD'EM", 116, Color(0.72, 0.82, 1.0, 0.22), 10, Vector2(0, 1), 0.08, 0.78))
	_logo_fallback.add_child(_make_logo_label("LogoMain", "TEXAS\nHOLD'EM", 116, Color(0.93, 0.95, 1.0, 1.0), 3, Vector2.ZERO, 0.08, 0.78))
	_logo_fallback.add_child(_make_logo_label("LogoSubShadow", "POKER CLUB", 22, Color(0.0, 0.0, 0.04, 0.76), 0, Vector2(2, 3), 0.70, 0.86))
	_logo_fallback.add_child(_make_logo_label("LogoSub", "POKER CLUB", 22, Color(0.74, 0.86, 1.0, 1.0), 2, Vector2.ZERO, 0.70, 0.86))

func _make_logo_label(label_name: String, text: String, font_size: int, color: Color, outline_size: int, offset: Vector2, anchor_top: float, anchor_bottom: float) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.anchor_left = 0.0
	label.anchor_top = anchor_top
	label.anchor_right = 1.0
	label.anchor_bottom = anchor_bottom
	label.offset_left = offset.x
	label.offset_top = offset.y
	label.offset_right = offset.x
	label.offset_bottom = offset.y
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.10, 0.92))
	label.add_theme_constant_override("outline_size", outline_size)
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
	_play_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_play_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.016, 0.0), Color(0.2, 0.28, 0.6, 0.0), 8, 0))
	_lobby_ui_root.add_child(_play_panel)
	var content := VBoxContainer.new()
	content.name = "PlayContent"
	content.add_theme_constant_override("separation", 22)
	_play_panel.add_child(content)
	var header := HBoxContainer.new()
	header.name = "PlayHeader"
	content.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := Label.new()
	title.text = "CHOOSE YOUR ROOM"
	HomeTheme.make_font_settings(title, 20, Color(0.9, 0.92, 1.0, 0.9))
	title_box.add_child(title)
	var sub := Label.new()
	sub.text = "Prototype modes use mock data only."
	HomeTheme.make_font_settings(sub, 12, HomeTheme.MUTED)
	title_box.add_child(sub)

	var card_row := HBoxContainer.new()
	card_row.name = "ModeCardRow"
	card_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_row.custom_minimum_size = Vector2(1, 370)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 20)
	content.add_child(card_row)
	for mode_data in MockHomeData.MODES:
		var card := preload("res://scenes/components/mode_card.tscn").instantiate() as ModeCard
		card.configure(mode_data)
		card.mode_selected.connect(_on_mode_selected)
		_mode_cards.append(card)
		card_row.add_child(card)

	var bottom_row := HBoxContainer.new()
	bottom_row.name = "ExpandedBottomRow"
	bottom_row.add_theme_constant_override("separation", 18)
	content.add_child(bottom_row)
	_welcome_pack = _build_welcome_pack_card()
	bottom_row.add_child(_welcome_pack)
	_daily_bonus = preload("res://scenes/components/daily_bonus_bar.tscn").instantiate()
	_daily_bonus.name = "DailyBonusBar"
	_daily_bonus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(_daily_bonus)

func _build_welcome_pack_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "WelcomePackCard"
	card.custom_minimum_size = Vector2(230, 96)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.016, 0.018, 0.048, 0.56), Color(0.74, 0.48, 1.0, 0.28), 8, 1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var chip := ColorRect.new()
	chip.custom_minimum_size = Vector2(48, 64)
	chip.color = Color(0.42, 0.26, 0.82, 0.70)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(chip)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var title := Label.new()
	title.text = "WELCOME PACK"
	HomeTheme.make_font_settings(title, 14, Color(0.86, 0.78, 1.0, 0.95))
	copy.add_child(title)
	var body := Label.new()
	body.text = "Claim your free chips."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(body, 11, Color(0.72, 0.76, 0.92, 0.82))
	copy.add_child(body)
	return card

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
	if id == "play":
		_set_expanded(true)
	elif id == "home":
		_set_expanded(false)
	else:
		_set_expanded(false)
		print("%s is coming soon." % id.capitalize())

func _on_play_submenu_selected(id: String) -> void:
	print("Selected play submenu: %s" % id)

func _set_expanded(value: bool, immediate: bool = false) -> void:
	_expanded = value
	_play_panel.visible = true
	var logo_target := 0.0 if value else 1.0
	var foreground_target := 0.0
	var panel_target := 1.0 if value else 0.0
	if immediate:
		_center_brand.modulate.a = logo_target
		_prompt.modulate.a = 0.0 if value else 1.0
		_foreground_decor.modulate.a = foreground_target
		_play_panel.modulate.a = panel_target
		_play_panel.offset_left = MAIN_LEFT
		_play_panel.visible = value
		return
	_center_brand.modulate.a = logo_target
	_prompt.modulate.a = 0.0 if value else 1.0
	_foreground_decor.modulate.a = foreground_target
	_play_panel.modulate.a = panel_target
	_play_panel.offset_left = MAIN_LEFT
	_play_panel.visible = value
	for card in _mode_cards:
		card.modulate.a = 1.0

func _on_mode_selected(id: String) -> void:
	print("Selected lobby mode: %s" % id)

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
	if not args.has("--capture-lobby-state"):
		args = OS.get_cmdline_args()
	if not args.has("--capture-lobby-state"):
		return
	var state := _arg_value(args, "--capture-lobby-state", "collapsed")
	var output := _arg_value(args, "--capture-lobby-output", "")
	if state == "expanded":
		_left_nav.set_active("play")
		_set_expanded(true, true)
	else:
		_left_nav.set_active("home")
		_set_expanded(false, true)
	var hover_index := _arg_value(args, "--capture-lobby-hover-index", "")
	if hover_index.is_valid_int():
		var index := hover_index.to_int()
		if index >= 0 and index < _mode_cards.size():
			_mode_cards[index].set_hover_preview(true)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if output != "":
		var image := get_viewport().get_texture().get_image()
		var path := ProjectSettings.globalize_path(output) if output.begins_with("res://") else output
		var err := image.save_png(path)
		if err != OK:
			push_error("Failed to save Home Lobby runtime screenshot: %s" % output)
	get_tree().quit()

func _arg_value(args: PackedStringArray, key: String, fallback: String) -> String:
	var index := args.find(key)
	if index == -1 or index + 1 >= args.size():
		return fallback
	return args[index + 1]
