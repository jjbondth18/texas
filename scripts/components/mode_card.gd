extends PanelContainer
class_name ModeCard

signal mode_selected(id: String)

var mode_id := ""
var _featured := false
var _image_path := ""

var _hover_wrapper: Control
var _glass_panel: PanelContainer
var _illustration: TextureRect
var _title_label: Label
var _subtitle_label: Label

var _hover_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(240, 360)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	_hover_wrapper = Control.new()
	_hover_wrapper.name = "HoverWrapper"
	_hover_wrapper.custom_minimum_size = Vector2(240, 360)
	_hover_wrapper.size = Vector2(240, 360)
	_hover_wrapper.pivot_offset = Vector2(120, 180)
	_hover_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_wrapper)
	
	_glass_panel = PanelContainer.new()
	_glass_panel.name = "DarkGlassPanel"
	_glass_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glass_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass_panel.add_theme_stylebox_override("panel", _style(false))
	_hover_wrapper.add_child(_glass_panel)
	
	var box := VBoxContainer.new()
	box.name = "CardBox"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	_glass_panel.add_child(box)
	
	_illustration = TextureRect.new()
	_illustration.name = "Illustration"
	_illustration.custom_minimum_size = Vector2(1, 214)
	_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_illustration)
	
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeTheme.make_font_settings(_title_label, 24)
	box.add_child(_title_label)
	
	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeTheme.make_font_settings(_subtitle_label, 13, HomeTheme.TEXT)
	box.add_child(_subtitle_label)
	
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	gui_input.connect(_on_gui_input)

func configure(data: Dictionary) -> void:
	mode_id = data["id"]
	_featured = data.get("featured", false)
	_image_path = data.get("image", "")
	if not is_node_ready():
		await ready
	_title_label.text = data["title"]
	_subtitle_label.text = data["subtitle"]
	if _image_path != "":
		_illustration.texture = load(_image_path)
	_glass_panel.add_theme_stylebox_override("panel", _style(false))
	queue_redraw()

func _hover(value: bool) -> void:
	_glass_panel.add_theme_stylebox_override("panel", _style(value))
	if _hover_tween:
		_hover_tween.kill()
	
	_hover_tween = create_tween().set_parallel(true)
	var target_scale := Vector2(1.025, 1.025) if value else Vector2.ONE
	var target_modulate := Color(1.05, 1.05, 1.05, 1.0) if value else Color.WHITE
	
	_hover_tween.tween_property(_hover_wrapper, "scale", target_scale, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_hover_wrapper, "modulate", target_modulate, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

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
	_hover_wrapper.position = Vector2(0, offset_y)

func tween_visual_reveal(delay: float) -> Tween:
	_hover_wrapper.modulate.a = 1.0
	_hover_wrapper.position = Vector2.ZERO
	_hover_wrapper.scale = Vector2.ONE
	var tween := _hover_wrapper.create_tween()
	return tween

func set_hover_preview(value: bool) -> void:
	_hover(value)
