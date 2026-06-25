extends PanelContainer
class_name ModeCard

signal mode_selected(id: String)

var mode_id := ""
var _featured := false
var _image_path := ""
var _image: TextureRect
var _title: Label
var _subtitle: Label
var _accent: ColorRect
var _base_position := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(238, 360)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pivot_offset = custom_minimum_size * 0.5
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("panel", HomeTheme.make_panel_style(HomeTheme.CARD, HomeTheme.STROKE, 8, 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
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
	call_deferred("_capture_base")

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
	add_theme_stylebox_override("panel", _style(false))
	queue_redraw()

func _capture_base() -> void:
	_base_position = position

func _hover(value: bool) -> void:
	var target_pos := _base_position + Vector2(0, -6 if value else 0)
	var target_scale := Vector2.ONE * (1.025 if value else 1.0)
	add_theme_stylebox_override("panel", _style(value))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE * 0.98, 0.06)
		tween.tween_property(self, "scale", Vector2.ONE * 1.025, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		mode_selected.emit(mode_id)

func _draw() -> void:
	var glow := HomeTheme.PINK if _featured else HomeTheme.CYAN
	draw_rect(Rect2(Vector2(18, 44), Vector2(size.x - 36, 208)), Color(0.0, 0.0, 0.0, 0.16), true)
	draw_line(Vector2(26, 252), Vector2(size.x - 26, 252), Color(glow.r, glow.g, glow.b, 0.24), 1.0)

func _style(hovered: bool) -> StyleBoxFlat:
	var border := HomeTheme.PINK if _featured else HomeTheme.STROKE
	if hovered:
		border = HomeTheme.PINK if _featured else HomeTheme.CYAN
	var bg := HomeTheme.CARD_HOVER if hovered else HomeTheme.CARD
	if _featured and not hovered:
		bg = Color(0.035, 0.022, 0.07, 0.86)
	var style := HomeTheme.make_panel_style(bg, border, 8, 1)
	style.shadow_color = Color(border.r, border.g, border.b, 0.22 if hovered or _featured else 0.08)
	style.shadow_size = 18 if hovered or _featured else 10
	style.shadow_offset = Vector2(0, 6)
	return style
