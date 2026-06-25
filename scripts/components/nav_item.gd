extends Button
class_name NavItem

signal nav_selected(id: String)

const DEBUG_SHOW_HIT_RECTS := false

@export var item_id := ""
@export var label_text := "ITEM"

var active := false
var _hovered := false
var _indicator: ColorRect

func _ready() -> void:
	custom_minimum_size = Vector2(246, 50)
	text = label_text
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", HomeTheme.MUTED)
	add_theme_color_override("font_hover_color", HomeTheme.TEXT)
	add_theme_color_override("font_pressed_color", HomeTheme.CYAN)
	add_theme_constant_override("h_separation", 10)
	add_theme_stylebox_override("normal", _style(Color.TRANSPARENT))
	add_theme_stylebox_override("hover", _style(Color(0.06, 0.08, 0.16, 0.5)))
	add_theme_stylebox_override("pressed", _style(Color(0.08, 0.11, 0.22, 0.62)))
	_indicator = ColorRect.new()
	_indicator.color = HomeTheme.CYAN
	_indicator.custom_minimum_size = Vector2(3, 34)
	_indicator.size = Vector2(3, 34)
	_indicator.position = Vector2(0, 8)
	_indicator.modulate.a = 0.0
	add_child(_indicator)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	pressed.connect(func() -> void: nav_selected.emit(item_id))
	_refresh_visuals()

func setup(id: String, title: String) -> void:
	item_id = id
	label_text = title
	if is_node_ready():
		text = label_text
		_refresh_visuals()

func set_active(value: bool) -> void:
	active = value
	_refresh_visuals()

func _set_hovered(value: bool) -> void:
	_hovered = value
	_refresh_visuals()

func _refresh_visuals() -> void:
	var color := HomeTheme.PINK if active else (HomeTheme.TEXT if _hovered else HomeTheme.MUTED)
	add_theme_color_override("font_color", color)
	if _indicator:
		_indicator.color = HomeTheme.PINK if active else HomeTheme.CYAN
		var target := 1.0 if active else (0.55 if _hovered else 0.0)
		var tween := create_tween()
		tween.tween_property(_indicator, "modulate:a", target, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _draw() -> void:
	if DEBUG_SHOW_HIT_RECTS:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.8, 1.0, 0.18), false, 1.0)

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 26
	style.content_margin_right = 12
	return style
