extends PanelContainer
class_name ModeCard

signal mode_selected(id: String)

var mode_id := ""
var _featured := false
var _image_path := ""
var _visual: PanelContainer
var _image: TextureRect
var _title: Label
var _subtitle: Label
var _accent: ColorRect
var _visual_base_position := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(240, 360)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_visual = PanelContainer.new()
	_visual.name = "CardVisual"
	_visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.pivot_offset = custom_minimum_size * 0.5
	_visual.add_theme_stylebox_override("panel", _style(false))
	add_child(_visual)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_visual.add_child(box)
	_accent = ColorRect.new()
	_accent.color = HomeTheme.PINK
	_accent.custom_minimum_size = Vector2(1, 3)
	box.add_child(_accent)
	_image = TextureRect.new()
	_image.custom_minimum_size = Vector2(1, 214)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_image)
	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(_title, 24)
	box.add_child(_title)
	_subtitle = Label.new()
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(_subtitle, 13, HomeTheme.TEXT)
	box.add_child(_subtitle)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	gui_input.connect(_on_gui_input)
	call_deferred("_capture_visual_base")

func configure(data: Dictionary) -> void:
	mode_id = data["id"]
	_featured = data.get("featured", false)
	_image_path = data.get("image", "")
	if not is_node_ready():
		await ready
	_title.text = data["title"]
	_subtitle.text = data["subtitle"]
	_accent.color = HomeTheme.PINK if _featured else HomeTheme.CYAN
	if _image_path != "":
		_image.texture = load(_image_path)
	_visual.add_theme_stylebox_override("panel", _style(false))
	queue_redraw()

func _capture_visual_base() -> void:
	_visual_base_position = _visual.position
	_visual.pivot_offset = _visual.size * 0.5

var _hover_tween: Tween

func _hover(value: bool) -> void:
	_visual.add_theme_stylebox_override("panel", _style(value))
	if _hover_tween:
		_hover_tween.kill()
	
	_hover_tween = create_tween().set_parallel(true)
	var target_scale := Vector2(1.025, 1.025) if value else Vector2.ONE
	var target_modulate := Color(1.05, 1.05, 1.05, 1.0) if value else Color.WHITE
	
	_hover_tween.tween_property(_visual, "scale", target_scale, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_visual, "modulate", target_modulate, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		mode_selected.emit(mode_id)

func _draw() -> void:
	var glow := HomeTheme.PINK if _featured else HomeTheme.CYAN
	draw_rect(Rect2(Vector2(18, 44), Vector2(size.x - 36, 208)), Color(0.0, 0.0, 0.0, 0.16), true)
	draw_line(Vector2(26, 252), Vector2(size.x - 26, 252), Color(glow.r, glow.g, glow.b, 0.24), 1.0)

func _style(hovered: bool) -> StyleBoxFlat:
	var border := Color(HomeTheme.PINK.r, HomeTheme.PINK.g, HomeTheme.PINK.b, 0.38) if _featured else Color(0.46, 0.54, 0.78, 0.24)
	if hovered:
		border = HomeTheme.PINK
	var bg := Color(0.014, 0.017, 0.04, 0.76)
	if hovered:
		bg = Color(0.022, 0.026, 0.058, 0.84)
	if _featured and not hovered:
		bg = Color(0.026, 0.016, 0.054, 0.80)
	var style := HomeTheme.make_panel_style(bg, border, 8, 1)
	style.shadow_color = Color(HomeTheme.PINK.r, HomeTheme.PINK.g, HomeTheme.PINK.b, 0.28 if hovered else (0.07 if _featured else 0.0))
	style.shadow_size = 14 if hovered else (8 if _featured else 0)
	style.shadow_offset = Vector2(0, 4)
	return style

func set_visual_reveal_offset(offset_y: float) -> void:
	if not is_node_ready():
		await ready
	_visual.position = _visual_base_position + Vector2(0, offset_y)

func tween_visual_reveal(delay: float) -> Tween:
	_visual.modulate.a = 1.0
	_visual.position = _visual_base_position
	_visual.scale = Vector2.ONE
	var tween := _visual.create_tween()
	return tween

func set_hover_preview(value: bool) -> void:
	_hover(value)
