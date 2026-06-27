extends Control
class_name PokerTableRuntimeLayoutEditor

const Config := preload("res://scripts/dev/poker_table_layout_config.gd")

var design_size := Vector2(2560, 1000)
var content_origin := Vector2.ZERO
var content_scale := 1.0
var targets := {}
var default_items := {}
var selected_id := ""
var edit_enabled := false

var _dragging := false
var _resizing := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_rect := Rect2()
var _help_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_help()

func configure_layout_space(origin: Vector2, scale_value: float) -> void:
	content_origin = origin
	content_scale = max(scale_value, 0.0001)

func register_targets(new_targets: Dictionary) -> void:
	targets = {}
	for id in new_targets.keys():
		var node = new_targets[id]
		if node is Control:
			targets[id] = node
		else:
			print("[LayoutEditor] Missing target: %s" % id)
	capture_defaults()
	apply_saved_layout()

func capture_defaults() -> void:
	default_items.clear()
	for id in targets.keys():
		default_items[id] = Config.rect_to_dict(_node_to_design_rect(targets[id]))

func apply_saved_layout() -> void:
	var config := Config.load_user_config()
	var items := Dictionary(config.get("items", {}))
	for id in items.keys():
		if not targets.has(id):
			print("[LayoutEditor] Missing target: %s" % id)
			continue
		_apply_design_rect(targets[id], Config.dict_to_rect(Dictionary(items[id])))
	queue_redraw()

func reset_to_default() -> void:
	for id in default_items.keys():
		if targets.has(id):
			_apply_design_rect(targets[id], Config.dict_to_rect(Dictionary(default_items[id])))
	Config.save_user_config(default_items)
	queue_redraw()

func save_layout() -> void:
	var items := {}
	for id in targets.keys():
		items[id] = Config.rect_to_dict(_node_to_design_rect(targets[id]))
	var err := Config.save_user_config(items)
	print("[LayoutEditor] Saved layout to %s, err=%s" % [Config.USER_CONFIG_PATH, err])

func _gui_input(event: InputEvent) -> void:
	if not edit_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			selected_id = _target_at(event.position)
			if selected_id != "":
				_dragging = true
				_resizing = event.shift_pressed
				_drag_start_mouse = event.position
				_drag_start_rect = targets[selected_id].get_global_rect()
				accept_event()
		else:
			_dragging = false
			_resizing = false
			accept_event()
	elif event is InputEventMouseMotion and _dragging and selected_id != "":
		var delta: Vector2 = event.position - _drag_start_mouse
		var rect := _drag_start_rect
		if _resizing:
			rect.size = Vector2(max(20.0, rect.size.x + delta.x), max(20.0, rect.size.y + delta.y))
		else:
			rect.position += delta
		_set_control_global_rect(targets[selected_id], rect)
		queue_redraw()
		accept_event()

func handle_key_event(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:
		return false
	if event.keycode == KEY_F9:
		set_edit_enabled(not edit_enabled)
		return true
	if not edit_enabled:
		return false
	if event.ctrl_pressed and event.keycode == KEY_S:
		save_layout()
		return true
	if event.ctrl_pressed and event.keycode == KEY_R:
		reset_to_default()
		return true
	if selected_id != "" and event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		var amount := 10.0 if event.shift_pressed else 1.0
		var delta := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: delta.x = -amount
			KEY_RIGHT: delta.x = amount
			KEY_UP: delta.y = -amount
			KEY_DOWN: delta.y = amount
		var rect := _node_to_design_rect(targets[selected_id])
		rect.position += delta
		_apply_design_rect(targets[selected_id], rect)
		queue_redraw()
		return true
	return false

func set_edit_enabled(value: bool) -> void:
	edit_enabled = value
	mouse_filter = Control.MOUSE_FILTER_STOP if edit_enabled else Control.MOUSE_FILTER_IGNORE
	_help_label.visible = edit_enabled
	queue_redraw()
	print("[LayoutEditor] %s" % ("Enabled" if edit_enabled else "Disabled"))

func _draw() -> void:
	if not edit_enabled:
		return
	for id in targets.keys():
		var rect := _design_to_overlay_rect(_node_to_design_rect(targets[id]))
		var selected: bool = id == selected_id
		draw_rect(rect, Color(1.0, 0.2, 0.75, 0.9) if selected else Color(0.2, 0.9, 1.0, 0.65), false, 3.0 if selected else 1.5)
		draw_string(get_theme_default_font(), rect.position + Vector2(4, -6), id, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	_update_help()

func _build_help() -> void:
	_help_label = Label.new()
	_help_label.visible = false
	_help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_label.position = Vector2(24, 24)
	_help_label.size = Vector2(360, 180)
	_help_label.add_theme_font_size_override("font_size", 14)
	_help_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_help_label)
	_update_help()

func _update_help() -> void:
	if _help_label == null:
		return
	_help_label.text = "LAYOUT EDIT MODE\nF9 toggle\nDrag move\nShift+Drag resize\nArrow keys nudge\nShift+Arrow larger nudge\nCtrl+S save\nCtrl+R reset\nSelected: %s" % (selected_id if selected_id != "" else "none")

func _target_at(point: Vector2) -> String:
	var ids := targets.keys()
	ids.reverse()
	for id in ids:
		if _control_contains_global_point(targets[id], point):
			return String(id)
	return ""

func _global_mouse_to_control_local(target: Control, global_mouse_pos: Vector2) -> Vector2:
	return global_mouse_pos - target.get_global_rect().position

func _control_contains_global_point(target: Control, global_mouse_pos: Vector2) -> bool:
	return target.get_global_rect().has_point(global_mouse_pos)

func _node_to_design_rect(node: Control) -> Rect2:
	var global := node.get_global_rect()
	return Rect2((global.position - content_origin) / content_scale, global.size / content_scale)

func _apply_design_rect(node: Control, rect: Rect2) -> void:
	var global_pos := content_origin + rect.position * content_scale
	var global_size := rect.size * content_scale
	_set_control_global_rect(node, Rect2(global_pos, global_size))

func _set_control_global_rect(target: Control, global_rect: Rect2) -> void:
	var parent_control := target.get_parent() as Control
	if parent_control != null:
		target.position = global_rect.position - parent_control.get_global_rect().position
	else:
		target.position = global_rect.position
	target.size = global_rect.size

func _design_to_overlay_rect(rect: Rect2) -> Rect2:
	return Rect2(content_origin + rect.position * content_scale, rect.size * content_scale)
