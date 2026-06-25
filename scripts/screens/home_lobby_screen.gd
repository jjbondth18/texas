extends Control
class_name HomeLobbyScreen

@export var background_motion_enabled := true

var _background_material: ShaderMaterial
var _left_nav: LeftNavRail
var _top_bar: TopBar
var _logo: Control
var _brand: Control
var _prompt: Label
var _play_panel: PanelContainer
var _daily_bonus: Control
var _mode_cards: Array[ModeCard] = []
var _foreground_decor: TextureRect
var _expanded := false

class PokerLogo:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, 152, Color(0.02, 0.025, 0.06, 0.22))
		draw_arc(center, 154, 0.0, TAU, 120, Color(0.52, 0.78, 1.0, 0.18), 2.0)
		draw_arc(center, 178, PI * 0.08, PI * 1.42, 120, Color(1.0, 0.28, 0.78, 0.12), 1.5)
		var spade := PackedVector2Array([
			center + Vector2(0, -90),
			center + Vector2(72, -12),
			center + Vector2(34, 58),
			center + Vector2(0, 30),
			center + Vector2(-34, 58),
			center + Vector2(-72, -12),
		])
		draw_colored_polygon(spade, Color(0.055, 0.075, 0.16, 0.32))
		var outline := PackedVector2Array(spade)
		outline.append(spade[0])
		draw_polyline(outline, Color(0.3, 0.86, 1.0, 0.32), 2.0)
		draw_circle(center + Vector2(0, -8), 24, Color(1.0, 0.28, 0.78, 0.18))

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_foreground()
	_build_layout()
	_build_play_panel()
	_top_bar.configure(MockHomeData.player())
	_left_nav.set_active("home")
	_set_expanded(false, true)
	MotionManager.pulse_canvas_item(_logo, 4.2, 0.78, 1.0)
	MotionManager.drift(_foreground_decor, Vector2(0, -5), 12.0)
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
	var base := TextureRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.texture = preload("res://assets/home_lobby/backgrounds/home_background.png")
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.02)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var flow := ColorRect.new()
	flow.set_anchors_preset(Control.PRESET_FULL_RECT)
	flow.modulate.a = 1.0
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_material = ShaderMaterial.new()
	_background_material.shader = preload("res://shaders/flow_noise_bg.gdshader")
	_background_material.set_shader_parameter("motion_enabled", background_motion_enabled)
	_background_material.set_shader_parameter("layer_alpha", 0.04)
	flow.material = _background_material
	add_child(flow)

func _build_layout() -> void:
	_left_nav = preload("res://scenes/components/left_nav_rail.tscn").instantiate() as LeftNavRail
	_left_nav.anchor_bottom = 1.0
	_left_nav.offset_right = 280
	_left_nav.nav_selected.connect(_on_nav_selected)
	add_child(_left_nav)

	_top_bar = preload("res://scenes/components/top_bar.tscn").instantiate() as TopBar
	_top_bar.anchor_left = 0.0
	_top_bar.anchor_right = 1.0
	_top_bar.offset_left = 320
	_top_bar.offset_right = -24
	_top_bar.offset_top = 18
	_top_bar.offset_bottom = 82
	_top_bar.exit_requested.connect(_quit_game)
	add_child(_top_bar)

	_logo = PokerLogo.new()
	_logo.custom_minimum_size = Vector2(520, 360)
	_logo.anchor_left = 0.5
	_logo.anchor_top = 0.5
	_logo.anchor_right = 0.5
	_logo.anchor_bottom = 0.5
	_logo.offset_left = -260
	_logo.offset_top = -245
	_logo.offset_right = 260
	_logo.offset_bottom = 115
	_logo.pivot_offset = Vector2(260, 180)
	add_child(_logo)

	_brand = VBoxContainer.new()
	_brand.anchor_left = 0.5
	_brand.anchor_top = 0.5
	_brand.anchor_right = 0.5
	_brand.anchor_bottom = 0.5
	_brand.offset_left = -430
	_brand.offset_top = -20
	_brand.offset_right = 430
	_brand.offset_bottom = 170
	_brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brand.add_theme_constant_override("separation", -8)
	add_child(_brand)
	var title := Label.new()
	title.text = "TEXAS\nHOLD'EM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", HomeTheme.TEXT)
	title.add_theme_color_override("font_shadow_color", Color(1.0, 0.28, 0.78, 0.38))
	title.add_theme_color_override("font_outline_color", Color(0.42, 0.55, 1.0, 0.28))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	_brand.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "POKER CLUB  -  NO-LIMIT ROOMS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(subtitle, 18, HomeTheme.CYAN)
	_brand.add_child(subtitle)

	_prompt = Label.new()
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
	HomeTheme.make_font_settings(_prompt, 14, Color(0.78, 0.84, 1.0, 0.78))
	add_child(_prompt)

func _build_play_panel() -> void:
	_play_panel = PanelContainer.new()
	_play_panel.anchor_left = 0.0
	_play_panel.anchor_top = 0.32
	_play_panel.anchor_right = 1.0
	_play_panel.anchor_bottom = 0.91
	_play_panel.offset_left = 360
	_play_panel.offset_right = -80
	_play_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.016, 0.14), Color(0.2, 0.28, 0.6, 0.0), 8, 0))
	add_child(_play_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 28)
	_play_panel.add_child(content)
	var header := HBoxContainer.new()
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
	card_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_row.custom_minimum_size = Vector2(1, 380)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 24)
	content.add_child(card_row)
	for mode_data in MockHomeData.MODES:
		var card := preload("res://scenes/components/mode_card.tscn").instantiate() as ModeCard
		card.configure(mode_data)
		card.mode_selected.connect(_on_mode_selected)
		_mode_cards.append(card)
		card_row.add_child(card)

	_daily_bonus = preload("res://scenes/components/daily_bonus_bar.tscn").instantiate()
	content.add_child(_daily_bonus)

func _build_foreground() -> void:
	_foreground_decor = TextureRect.new()
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

func _set_expanded(value: bool, immediate: bool = false) -> void:
	_expanded = value
	_play_panel.visible = true
	var logo_target := 0.14 if value else 1.0
	var brand_target := 0.16 if value else 1.0
	var foreground_target := 0.10 if value else 0.0
	var panel_target := 1.0 if value else 0.0
	var panel_left := 360.0 if value else 392.0
	if immediate:
		_logo.modulate.a = logo_target
		_brand.modulate.a = brand_target
		_prompt.modulate.a = 0.0 if value else 1.0
		_foreground_decor.modulate.a = foreground_target
		_play_panel.modulate.a = panel_target
		_play_panel.offset_left = panel_left
		_play_panel.visible = value
		return
	if value:
		_play_panel.modulate.a = 0.0
		_play_panel.offset_left = 392.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_logo, "modulate:a", logo_target, 0.22)
	tween.tween_property(_brand, "modulate:a", brand_target, 0.22)
	tween.tween_property(_prompt, "modulate:a", 0.0 if value else 1.0, 0.18)
	tween.tween_property(_foreground_decor, "modulate:a", foreground_target, 0.22)
	tween.tween_property(_play_panel, "modulate:a", panel_target, 0.22)
	tween.tween_property(_play_panel, "offset_left", panel_left, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not value:
		tween.chain().tween_callback(func() -> void: _play_panel.visible = false)
	else:
		if _daily_bonus:
			_daily_bonus.modulate.a = 0.0
			_daily_bonus.position.y += 10
			var daily_tween := create_tween()
			daily_tween.set_parallel(true)
			daily_tween.tween_interval(0.22)
			daily_tween.chain().tween_property(_daily_bonus, "modulate:a", 1.0, 0.18)
			daily_tween.parallel().tween_property(_daily_bonus, "position:y", _daily_bonus.position.y - 10, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		for i in range(_mode_cards.size()):
			var card := _mode_cards[i]
			card.modulate.a = 0.0
			card.position.y += 14
			var card_tween := create_tween()
			card_tween.set_parallel(true)
			card_tween.tween_interval(0.04 * float(i))
			card_tween.chain().tween_property(card, "modulate:a", 1.0, 0.14)
			card_tween.parallel().tween_property(card, "position:y", card.position.y - 14, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_mode_selected(id: String) -> void:
	print("Selected lobby mode: %s" % id)

func set_background_motion_enabled(value: bool) -> void:
	background_motion_enabled = value
	if _background_material:
		_background_material.set_shader_parameter("motion_enabled", value)

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
