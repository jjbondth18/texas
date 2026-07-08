extends PanelContainer
class_name LeftNavRail

signal nav_selected(id: String)
signal play_submenu_selected(id: String)

const ITEMS := [
	{ "id": "home", "title": "HOME" },
	{ "id": "play", "title": "PLAY" },
	{ "id": "replay", "title": "REPLAY" },
	{ "id": "store", "title": "STORE" },
	{ "id": "profile", "title": "PROFILE" },
	{ "id": "settings", "title": "SETTINGS" },
]
const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

var _list: VBoxContainer
var _items: Dictionary = {}
var _play_submenu: VBoxContainer
var _play_submenu_buttons: Dictionary = {}
var active_id := "home"

const DEBUG_SHOW_HIT_RECTS := false

func _ready() -> void:
	custom_minimum_size = Vector2(280, 0)
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel", style)

	# 1. Premium Horizontal Gradient Background (Dark Navy to semi-trans purple)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.04, 0.04, 0.08, 0.65), # left dark navy/black (65% opacity)
		Color(0.06, 0.05, 0.1, 0.35)   # right faint magenta/violet glow (35% opacity)
	])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill_from = Vector2(0.0, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)

	var bg_rect := TextureRect.new()
	bg_rect.name = "GradientBackground"
	bg_rect.texture = grad_tex
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# 2. 1px Neon Right Border Glow
	var border_right := ColorRect.new()
	border_right.name = "BorderRight"
	border_right.color = Color(0.6, 0.2, 0.5, 0.15) # 15% opacity magenta border
	border_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_right.anchor_left = 1.0
	border_right.anchor_right = 1.0
	border_right.anchor_top = 0.0
	border_right.anchor_bottom = 1.0
	border_right.offset_left = -1.0
	border_right.offset_right = 0.0
	border_right.offset_top = 0.0
	border_right.offset_bottom = 0.0
	border_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	border_right.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(border_right)

	# 3. NavList VBoxContainer
	_list = VBoxContainer.new()
	_list.name = "NavList"
	_list.alignment = BoxContainer.ALIGNMENT_BEGIN
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", 12)
	add_child(_list)
	var spacer_top := Control.new()
	spacer_top.name = "SpacerTop"
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer_top.custom_minimum_size = Vector2(1, 136)
	_list.add_child(spacer_top)
	for item_data in ITEMS:
		var item := preload("res://scenes/components/nav_item.tscn").instantiate() as NavItem
		item.setup(item_data["id"], item_data["title"])
		item.debug_show_hit_rects = DEBUG_SHOW_HIT_RECTS
		item.nav_selected.connect(_on_item_selected)
		_items[item_data["id"]] = item
		_list.add_child(item)
		if item_data["id"] == "play":
			_build_play_submenu()
	var fill := Control.new()
	fill.name = "SpacerFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(fill)
	var version := Label.new()
	version.name = "VersionLabel"
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version.text = "ALPHA LOBBY"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(version, 11, Color(0.45, 0.54, 0.74, 0.55))
	_list.add_child(version)
	set_active(active_id)
	apply_localization()
	queue_redraw()

func apply_localization() -> void:
	for item_data in ITEMS:
		var id := str(item_data["id"])
		if _items.has(id):
			_items[id].setup(id, LocalizationManagerScript.tr_key("nav.%s" % id))
	for mode_id in _play_submenu_buttons.keys():
		var button := _play_submenu_buttons[mode_id] as Button
		if button != null:
			button.text = LocalizationManagerScript.tr_key("mode.%s.title" % str(mode_id))

func _draw() -> void:
	if DEBUG_SHOW_HIT_RECTS:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 1.0, 0.15), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 1.0, 0.7), false, 2.0)

func set_active(id: String) -> void:
	active_id = id
	for key in _items:
		_items[key].set_active(key == active_id)
	if _play_submenu:
		if active_id == "play":
			_play_submenu.visible = true
			_play_submenu.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(_play_submenu, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_play_submenu.visible = false
			_play_submenu.modulate.a = 0.0

func _on_item_selected(id: String) -> void:
	set_active(id)
	nav_selected.emit(id)

func _build_play_submenu() -> void:
	var MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")
	var lobby_vm := MockDataProviderScript.get_lobby_view_model()
	_play_submenu = VBoxContainer.new()
	_play_submenu.name = "PlaySubmenu"
	_play_submenu.visible = false
	_play_submenu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_submenu.add_theme_constant_override("separation", 8)
	_list.add_child(_play_submenu)
	for mode_data in lobby_vm["modes"]:
		var button := Button.new()
		button.text = mode_data["title"]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(190, 24)
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_color_override("font_color", Color(0.886, 0.910, 0.941, 0.70))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.58, 0.88, 1.0))
		button.add_theme_color_override("font_pressed_color", HomeTheme.PINK)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", _submenu_hover_style())
		button.add_theme_stylebox_override("pressed", _submenu_hover_style())
		button.pressed.connect(func() -> void: play_submenu_selected.emit(mode_data["id"]))
		_play_submenu_buttons[str(mode_data["id"])] = button
		var indent := MarginContainer.new()
		indent.add_theme_constant_override("margin_left", 42)
		indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		indent.add_child(button)
		_play_submenu.add_child(indent)

func _submenu_hover_style() -> StyleBoxFlat:
	var style := HomeTheme.make_panel_style(Color(0.12, 0.036, 0.13, 0.42), Color(1.0, 0.28, 0.78, 0.24), 4, 0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style
