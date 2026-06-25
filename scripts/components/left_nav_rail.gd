extends PanelContainer
class_name LeftNavRail

signal nav_selected(id: String)

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
	_play_submenu.visible = false
	_play_submenu.add_theme_constant_override("separation", 8)
	_list.add_child(_play_submenu)
	for label_text in ["QUICK PLAY", "CASH TABLES", "TOURNAMENTS", "PRIVATE TABLE", "CLUB GAMES"]:
		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size = Vector2(190, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", HomeTheme.MUTED)
		label.add_theme_constant_override("outline_size", 0)
		label.set("theme_override_constants/line_spacing", 1)
		var indent := MarginContainer.new()
		indent.add_theme_constant_override("margin_left", 42)
		indent.add_child(label)
		_play_submenu.add_child(indent)
