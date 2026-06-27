extends Control
class_name PokerTableLayoutCalibrator

const Schema := preload("res://scripts/dev/poker_table_layout_schema.gd")
const BACKGROUND_PATH := "res://assets/poker_table/backgrounds/table_neon_v1.png"

var _background: TextureRect
var _boxes_root: Control
var _help: Label
var _boxes := {}
var _items := {}
var _selected_id := "seat_5_local"
var _dragging := false
var _resizing := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_rect := Rect2()
var _scale := 1.0
var _origin := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_boxes()
	_build_help()
	_load_layout()
	_layout()
	_handle_capture_args()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_selected_id = _target_at(event.position)
			if _selected_id != "":
				_dragging = true
				_resizing = _is_resize_hit(_boxes[_selected_id], event.position)
				_drag_start_mouse = _screen_to_design(event.position)
				_drag_start_rect = Schema.dict_to_rect(Dictionary(_items[_selected_id]))
				accept_event()
		else:
			_dragging = false
			_resizing = false
			accept_event()
	elif event is InputEventMouseMotion and _dragging and _selected_id != "":
		var delta := _screen_to_design(event.position) - _drag_start_mouse
		var rect := _drag_start_rect
		if _resizing or event.shift_pressed:
			rect.size = Vector2(max(20.0, rect.size.x + delta.x), max(20.0, rect.size.y + delta.y))
		else:
			rect.position += delta
		_items[_selected_id] = Schema.rect_to_dict(rect)
		_apply_items_to_boxes()
		accept_event()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed and event.keycode == KEY_S:
		_save_layout()
		get_viewport().set_input_as_handled()
	elif event.ctrl_pressed and event.keycode == KEY_R:
		_items = Schema.DEFAULT_ITEMS.duplicate(true)
		_apply_items_to_boxes()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB:
		_cycle_selected()
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN] and _selected_id != "":
		var amount := 10.0 if event.shift_pressed else 1.0
		var rect := Schema.dict_to_rect(Dictionary(_items[_selected_id]))
		match event.keycode:
			KEY_LEFT: rect.position.x -= amount
			KEY_RIGHT: rect.position.x += amount
			KEY_UP: rect.position.y -= amount
			KEY_DOWN: rect.position.y += amount
		_items[_selected_id] = Schema.rect_to_dict(rect)
		_apply_items_to_boxes()
		get_viewport().set_input_as_handled()

func _build_background() -> void:
	_background = TextureRect.new()
	_background.name = "TableBackground"
	_background.texture = _load_texture(BACKGROUND_PATH)
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

func _build_boxes() -> void:
	_boxes_root = Control.new()
	_boxes_root.name = "LayoutBoxes"
	add_child(_boxes_root)
	for id in Schema.TARGET_IDS:
		var box := PanelContainer.new()
		box.name = id
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_stylebox_override("panel", _box_style(false))
		var label := Label.new()
		label.text = id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		box.add_child(label)
		_boxes_root.add_child(box)
		_boxes[id] = box

func _build_help() -> void:
	_help = Label.new()
	_help.name = "HelpOverlay"
	_help.position = Vector2(24, 24)
	_help.size = Vector2(560, 180)
	_help.add_theme_font_size_override("font_size", 16)
	_help.add_theme_color_override("font_color", Color.WHITE)
	add_child(_help)
	_update_help()

func _load_layout() -> void:
	_items = Schema.merged_items_with_defaults(Schema.load_user_config())
	_apply_items_to_boxes()

func _layout() -> void:
	if _background:
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _boxes_root == null:
		return
	_scale = minf(size.x / Schema.DESIGN_SIZE.x, size.y / Schema.DESIGN_SIZE.y)
	_origin = (size - Schema.DESIGN_SIZE * _scale) * 0.5
	_boxes_root.position = _origin
	_boxes_root.size = Schema.DESIGN_SIZE * _scale
	_apply_items_to_boxes()

func _apply_items_to_boxes() -> void:
	for id in _boxes.keys():
		if not _items.has(id):
			continue
		var box: Control = _boxes[id]
		var rect := Schema.dict_to_rect(Dictionary(_items[id]))
		box.position = rect.position * _scale
		box.size = rect.size * _scale
		box.add_theme_stylebox_override("panel", _box_style(id == _selected_id))
	_update_help()

func _save_layout() -> void:
	var err := Schema.save_user_config(_items)
	print("[LayoutCalibrator] Saved layout to %s, err=%s" % [Schema.USER_CONFIG_PATH, err])
	_update_help("Saved to %s" % Schema.USER_CONFIG_PATH)

func _target_at(screen_pos: Vector2) -> String:
	var ids := Schema.TARGET_IDS.duplicate()
	ids.reverse()
	for id in ids:
		var rect := Rect2(_origin + Schema.dict_to_rect(Dictionary(_items[id])).position * _scale, Schema.dict_to_rect(Dictionary(_items[id])).size * _scale)
		if rect.has_point(screen_pos):
			return String(id)
	return ""

func _is_resize_hit(box: Control, screen_pos: Vector2) -> bool:
	var rect := box.get_global_rect()
	return Rect2(rect.end - Vector2(22, 22), Vector2(22, 22)).has_point(screen_pos)

func _screen_to_design(screen_pos: Vector2) -> Vector2:
	return (screen_pos - _origin) / max(_scale, 0.0001)

func _cycle_selected() -> void:
	var index := Schema.TARGET_IDS.find(_selected_id)
	_selected_id = Schema.TARGET_IDS[(index + 1) % Schema.TARGET_IDS.size()]
	_apply_items_to_boxes()

func _box_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.18, 0.34, 0.34) if not selected else Color(0.75, 0.12, 0.55, 0.42)
	style.border_color = Color(0.35, 0.9, 1.0, 0.9) if not selected else Color(1.0, 0.25, 0.8, 1.0)
	style.set_border_width_all(3 if selected else 2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _update_help(extra: String = "") -> void:
	if _help == null:
		return
	_help.text = "POKER TABLE LAYOUT CALIBRATOR\nClick box: select\nDrag: move\nDrag corner / Shift+Drag: resize\nArrow keys: nudge\nShift+Arrow: large nudge\nTab: cycle\nCtrl+S: save user layout\nCtrl+R: reset defaults\nSelected: %s%s" % [_selected_id, "\n" + extra if extra != "" else ""]

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Failed to load calibrator background: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _handle_capture_args() -> void:
	var args := OS.get_cmdline_args()
	if OS.has_method("get_cmdline_user_args"):
		args.append_array(OS.get_cmdline_user_args())
	var index := args.find("--capture-output")
	if index >= 0 and index + 1 < args.size():
		call_deferred("_capture_and_quit", String(args[index + 1]))

func _capture_and_quit(output: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(output)
	get_tree().quit()
