extends PanelContainer
class_name ModeCard

signal mode_selected(id: String)

var mode_id := ""
var _featured := false
var _title: Label
var _subtitle: Label
var _accent: ColorRect
var _base_position := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(238, 360)
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
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 190)
	box.add_child(spacer)
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
	if not is_node_ready():
		await ready
	_title.text = data["title"]
	_subtitle.text = data["subtitle"]
	_accent.color = HomeTheme.PINK if _featured else HomeTheme.CYAN
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
	draw_rect(Rect2(Vector2(18, 52), Vector2(size.x - 36, 150)), Color(0.03, 0.035, 0.08, 0.34), true)
	draw_line(Vector2(26, 214), Vector2(size.x - 26, 214), Color(glow.r, glow.g, glow.b, 0.22), 1.0)
	match mode_id:
		"quick_play":
			_draw_cards(glow)
		"cash_tables":
			_draw_chips(glow)
		"tournaments":
			_draw_trophy(glow)
		"private_table":
			_draw_table(glow)
		_:
			_draw_club_badge(glow)

func _draw_cards(glow: Color) -> void:
	draw_set_transform(Vector2(88, 138), -0.12, Vector2.ONE)
	draw_rect(Rect2(Vector2(-36, -54), Vector2(72, 108)), Color(0.86, 0.88, 0.96, 0.86), true)
	draw_rect(Rect2(Vector2(-36, -54), Vector2(72, 108)), Color(glow.r, glow.g, glow.b, 0.38), false, 2.0)
	draw_circle(Vector2(0, 10), 18, Color(0.02, 0.025, 0.05, 0.72))
	draw_set_transform(Vector2(136, 136), 0.1, Vector2.ONE)
	draw_rect(Rect2(Vector2(-36, -54), Vector2(72, 108)), Color(0.9, 0.88, 0.95, 0.82), true)
	draw_rect(Rect2(Vector2(-36, -54), Vector2(72, 108)), Color(HomeTheme.PINK.r, HomeTheme.PINK.g, HomeTheme.PINK.b, 0.36), false, 2.0)
	draw_circle(Vector2(0, 10), 16, Color(HomeTheme.PINK.r, HomeTheme.PINK.g, HomeTheme.PINK.b, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_chips(glow: Color) -> void:
	for i in range(5):
		var p := Vector2(72 + i * 24, 154 - i * 10)
		draw_circle(p, 28, Color(0.025, 0.025, 0.055, 0.9))
		draw_arc(p, 28, 0, TAU, 42, Color(glow.r, glow.g, glow.b, 0.45), 3.0)
		draw_arc(p, 17, 0, TAU, 42, Color(HomeTheme.PURPLE.r, HomeTheme.PURPLE.g, HomeTheme.PURPLE.b, 0.38), 2.0)

func _draw_trophy(glow: Color) -> void:
	var cup := Rect2(Vector2(size.x * 0.5 - 38, 88), Vector2(76, 80))
	draw_rect(cup, Color(0.18, 0.16, 0.28, 0.78), true)
	draw_rect(cup, Color(glow.r, glow.g, glow.b, 0.38), false, 2.0)
	draw_line(Vector2(size.x * 0.5, 168), Vector2(size.x * 0.5, 196), Color(glow.r, glow.g, glow.b, 0.5), 4.0)
	draw_arc(Vector2(size.x * 0.5 - 40, 120), 32, -PI * 0.5, PI * 0.5, 32, Color(glow.r, glow.g, glow.b, 0.4), 3.0)
	draw_arc(Vector2(size.x * 0.5 + 40, 120), 32, PI * 0.5, PI * 1.5, 32, Color(glow.r, glow.g, glow.b, 0.4), 3.0)

func _draw_table(glow: Color) -> void:
	draw_set_transform(Vector2(size.x * 0.5, 145), 0.0, Vector2(1.8, 0.72))
	draw_circle(Vector2.ZERO, 52, Color(0.08, 0.05, 0.14, 0.82))
	draw_arc(Vector2.ZERO, 52, 0, TAU, 64, Color(glow.r, glow.g, glow.b, 0.36), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(Vector2(size.x * 0.5 - 24, 130), Vector2(48, 28)), Color(0.9, 0.9, 1.0, 0.26), true)

func _draw_club_badge(glow: Color) -> void:
	var center := Vector2(size.x * 0.5, 138)
	var shield := PackedVector2Array([
		center + Vector2(0, -62),
		center + Vector2(54, -28),
		center + Vector2(42, 42),
		center + Vector2(0, 72),
		center + Vector2(-42, 42),
		center + Vector2(-54, -28),
	])
	draw_colored_polygon(shield, Color(0.09, 0.07, 0.13, 0.8))
	var outline := PackedVector2Array(shield)
	outline.append(shield[0])
	draw_polyline(outline, Color(glow.r, glow.g, glow.b, 0.42), 3.0)
	draw_circle(center, 24, Color(glow.r, glow.g, glow.b, 0.22))

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
