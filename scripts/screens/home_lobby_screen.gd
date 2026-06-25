extends Control
class_name HomeLobbyScreen

enum LobbyState {
	COLLAPSED,
	PLAY_EXPANDED
}

@export var background_motion_enabled := true

const BACKGROUND_TEXTURE_PATH := "res://assets/home_lobby/backgrounds/home_background_v1.png"
const NEON_SWEEP_SHADER_PATH := "res://shaders/neon_sweep.gdshader"
const NAV_WIDTH := 280.0
const MAIN_LEFT := 360.0
const MAIN_RIGHT := 70.0

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
var _welcome_pack: PanelContainer
var _daily_bonus: Control
var _mode_cards: Array[ModeCard] = []
var _foreground_decor: TextureRect
var _expanded := false
var _bg_breath_tween: Tween

func _ready() -> void:
	# Force standalone windowed mode to bypass Godot editor stretch bugs
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_foreground()
	_build_layout()
	_build_play_panel()
	_top_bar.configure(MockHomeData.player())
	set_state(LobbyState.COLLAPSED, false)
	_handle_runtime_capture_args()

func set_state(new_state: LobbyState, animated: bool = true) -> void:
	current_state = new_state
	
	if current_state == LobbyState.COLLAPSED:
		if _left_nav.active_id == "play":
			_left_nav.set_active("home")
	elif current_state == LobbyState.PLAY_EXPANDED:
		_left_nav.set_active("play")
		
	_set_expanded(current_state == LobbyState.PLAY_EXPANDED, not animated)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.alt_pressed and event.keycode == KEY_ENTER:
			_toggle_window_mode()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if current_state == LobbyState.PLAY_EXPANDED:
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
	flow_mat.set_shader_parameter("layer_alpha", 0.035) # extremely subtle blend overlay
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
	for mode_data in MockHomeData.MODES:
		var card := preload("res://scenes/components/mode_card.tscn").instantiate() as ModeCard
		card.configure(mode_data)
		card.mode_selected.connect(_on_mode_selected)
		_mode_cards.append(card)
		card_row.add_child(card)

	_daily_bonus = preload("res://scenes/components/daily_bonus_bar.tscn").instantiate()
	_daily_bonus.name = "DailyBonusBar"
	_daily_bonus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_daily_bonus)


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
		set_state(LobbyState.PLAY_EXPANDED)
	else:
		set_state(LobbyState.COLLAPSED)
		_left_nav.set_active(id)
		if id != "home":
			print("%s is coming soon." % id.capitalize())

func _on_play_submenu_selected(id: String) -> void:
	print("Selected play submenu: %s" % id)

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

func _set_expanded(value: bool, immediate: bool = false) -> void:
	_expanded = value
	
	var logo_target := 0.15 if value else 1.0
	var prompt_target := 0.0 if value else 1.0
	var panel_target := 1.0 if value else 0.0
	var bg_target := Color(0.48, 0.45, 0.52, 1.0) if value else Color(1.34, 1.30, 1.40, 1.0)
	
	if _transition_tween:
		_transition_tween.kill()
		
	if immediate:
		_center_brand.modulate.a = logo_target
		_center_brand.visible = true
		_prompt.modulate.a = prompt_target
		_prompt.visible = not value
		_play_panel.modulate.a = panel_target
		_play_panel.visible = value
		_stop_bg_breathing()
		if _background_texture:
			_background_texture.modulate = bg_target
		if not value:
			_start_bg_breathing()
		return
		
	_transition_tween = create_tween().set_parallel(true)
	
	if value:
		_stop_bg_breathing()
		_play_panel.visible = true
		_play_panel.modulate.a = 0.0
		_transition_tween.tween_property(_play_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_center_brand.visible = true
		_transition_tween.tween_property(_center_brand, "modulate:a", 0.15, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_prompt, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if _background_texture:
			_transition_tween.tween_property(_background_texture, "modulate", bg_target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.chain().tween_callback(func() -> void:
			_prompt.visible = false
		)
	else:
		_center_brand.visible = true
		_prompt.visible = true
		_prompt.modulate.a = 0.0
		
		_transition_tween.tween_property(_center_brand, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_prompt, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.tween_property(_play_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if _background_texture:
			_transition_tween.tween_property(_background_texture, "modulate", bg_target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		_transition_tween.chain().tween_callback(func() -> void:
			_play_panel.visible = false
			_start_bg_breathing()
		)

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
	print("CMD user args: ", args)
	if not args.has("--capture-lobby-state"):
		args = OS.get_cmdline_args()
	print("CMD args: ", args)
	if not args.has("--capture-lobby-state"):
		print("No capture lobby state argument found")
		return
	var state := _arg_value(args, "--capture-lobby-state", "collapsed")
	var output := _arg_value(args, "--capture-lobby-output", "")
	if state == "expanded":
		set_state(LobbyState.PLAY_EXPANDED, false)
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
	particles.amount = 16
	particles.lifetime = 6.0
	particles.preprocess = 3.0
	particles.randomness = 0.6
	particles.position = Vector2(1000, 1090)
	
	var p_mat := ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(700, 10, 1)
	p_mat.direction = Vector3(0, -1, 0)
	p_mat.spread = 15.0
	p_mat.gravity = Vector3(0, -8, 0)
	p_mat.initial_velocity_min = 4.0
	p_mat.initial_velocity_max = 10.0
	p_mat.color = Color(0.8, 0.2, 0.6, 0.22)
	p_mat.scale_min = 2.0
	p_mat.scale_max = 4.0
	
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.8, 0.2, 0.6, 0.0),
		Color(0.8, 0.2, 0.6, 0.22),
		Color(0.8, 0.2, 0.6, 0.18),
		Color(0.8, 0.2, 0.6, 0.0)
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
