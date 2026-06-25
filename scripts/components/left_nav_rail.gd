extends PanelContainer
class_name LeftNavRail

signal nav_selected(id: String)
signal play_submenu_selected(id: String)

const ITEMS := [
	{ "id": "home", "title": "HOME" },
	{ "id": "play", "title": "PLAY" },
	{ "id": "club", "title": "CLUB" },
	{ "id": "tournaments", "title": "TOURNAMENTS" },
	{ "id": "store", "title": "STORE" },
	{ "id": "profile", "title": "PROFILE" },
]

var _list: VBoxContainer
var _items: Dictionary = {}
var _play_submenu: VBoxContainer
var active_id := "home"

func _ready() -> void:
	custom_minimum_size = Vector2(280, 0)
	add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.018, 0.82), Color(0.36, 0.42, 0.7, 0.16), 0, 0))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	add_child(_list)
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(1, 136)
	_list.add_child(spacer_top)
	for item_data in ITEMS:
		var item := preload("res://scenes/components/nav_item.tscn").instantiate() as NavItem
		item.setup(item_data["id"], item_data["title"])
		item.nav_selected.connect(_on_item_selected)
		_items[item_data["id"]] = item
		_list.add_child(item)
		if item_data["id"] == "play":
			_build_play_submenu()
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(fill)
	var version := Label.new()
	version.text = "ALPHA LOBBY"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(version, 11, Color(0.45, 0.54, 0.74, 0.55))
	_list.add_child(version)
	set_active(active_id)

func set_active(id: String) -> void:
	active_id = id
	for key in _items:
		_items[key].set_active(key == active_id)
	if _play_submenu:
		_play_submenu.visible = active_id == "play"
		_play_submenu.modulate.a = 0.0 if active_id == "play" else 1.0
		if active_id == "play":
			create_tween().tween_property(_play_submenu, "modulate:a", 1.0, 0.18)

func _on_item_selected(id: String) -> void:
	set_active(id)
	nav_selected.emit(id)

func _build_play_submenu() -> void:
	_play_submenu = VBoxContainer.new()
	_play_submenu.name = "PlaySubmenu"
	_play_submenu.visible = false
	_play_submenu.add_theme_constant_override("separation", 8)
	_list.add_child(_play_submenu)
	for mode_data in MockHomeData.MODES:
		var button := Button.new()
		button.text = mode_data["title"]
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(190, 24)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_color_override("font_color", HomeTheme.MUTED)
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.58, 0.88, 1.0))
		button.add_theme_color_override("font_pressed_color", HomeTheme.PINK)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", _submenu_hover_style())
		button.add_theme_stylebox_override("pressed", _submenu_hover_style())
		button.pressed.connect(func() -> void: play_submenu_selected.emit(mode_data["id"]))
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
