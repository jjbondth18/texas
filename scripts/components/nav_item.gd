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
	custom_minimum_size = Vector2(244, 50)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	text = label_text
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(0.886, 0.910, 0.941, 0.70))
	add_theme_color_override("font_hover_color", Color(0.92, 0.94, 1.0, 1.0))
	add_theme_color_override("font_pressed_color", HomeTheme.CYAN)
	add_theme_constant_override("h_separation", 10)
	add_theme_stylebox_override("normal", _style(Color.TRANSPARENT))
	add_theme_stylebox_override("hover", _style(Color(0.06, 0.08, 0.16, 0.5)))
	add_theme_stylebox_override("pressed", _style(Color(0.08, 0.11, 0.22, 0.62)))
	_indicator = ColorRect.new()
	_indicator.name = "ActiveIndicator"
	_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicator.color = HomeTheme.CYAN
	_indicator.custom_minimum_size = Vector2(4, 30)
	_indicator.size = Vector2(4, 30)
	_indicator.anchor_left = 0.0
	_indicator.anchor_right = 0.0
	_indicator.anchor_top = 0.5
	_indicator.anchor_bottom = 0.5
	_indicator.offset_left = 0.0
	_indicator.offset_right = 4.0
	_indicator.offset_top = -15.0
	_indicator.offset_bottom = 15.0
	_indicator.grow_vertical = Control.GROW_DIRECTION_BOTH
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
	var color := HomeTheme.PINK if active else (Color(1.0, 1.0, 1.0, 1.0) if _hovered else Color(0.886, 0.910, 0.941, 0.70))
	add_theme_color_override("font_color", color)
	if _indicator:
		_indicator.color = HomeTheme.PINK if active else HomeTheme.CYAN
		var target := 1.0 if active else (0.55 if _hovered else 0.0)
		var tween := create_tween()
		tween.tween_property(_indicator, "modulate:a", target, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 26
	style.content_margin_right = 12
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
