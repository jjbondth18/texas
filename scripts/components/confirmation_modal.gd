extends Control
class_name ConfirmationModal

signal confirmed
signal cancelled

var _title_label: Label
var _description_label: Label
var _detail_label: Label
var _error_label: Label
var _cancel_button: Button
var _confirm_button: Button
var _close_button: Button
var _pending := false
var _confirm_text := "CONFIRM"


func _ready() -> void:
	name = "ConfirmationModal"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 1000
	_build_ui()
	visible = false


func configure(title_text: String, description_text: String, detail_text: String, cancel_text: String, confirm_text: String) -> void:
	_title_label.text = title_text
	_description_label.text = description_text
	_detail_label.text = detail_text
	_detail_label.visible = detail_text.strip_edges() != ""
	_cancel_button.text = cancel_text
	_confirm_text = confirm_text
	_confirm_button.text = confirm_text
	set_error("")
	set_pending(false)


func open() -> void:
	visible = true
	move_to_front()
	_confirm_button.grab_focus()


func close() -> void:
	if _pending:
		return
	visible = false
	set_error("")


func is_open() -> bool:
	return visible


func set_pending(value: bool, pending_text: String = "WORKING...") -> void:
	_pending = value
	_confirm_button.disabled = value
	_cancel_button.disabled = value
	_close_button.disabled = value
	_confirm_button.text = pending_text if value else _confirm_text


func set_error(message: String) -> void:
	_error_label.text = message
	_error_label.visible = message.strip_edges() != ""


func request_cancel() -> void:
	if not visible or _pending:
		return
	visible = false
	cancelled.emit()


func request_confirm() -> void:
	if not visible or _pending or _confirm_button.disabled:
		return
	confirmed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		request_cancel()
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		request_confirm()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.004, 0.003, 0.014, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 320)
	panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.016, 0.010, 0.040, 0.98), Color(0.72, 0.24, 0.90, 0.82), 10, 1))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HomeTheme.make_font_settings(_title_label, 19, HomeTheme.CYAN)
	title_row.add_child(_title_label)
	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(34, 30)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.pressed.connect(request_cancel)
	_apply_button_style(_close_button, false)
	title_row.add_child(_close_button)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.custom_minimum_size = Vector2(460, 72)
	HomeTheme.make_font_settings(_description_label, 14, Color(0.90, 0.91, 1.0, 0.94))
	content.add_child(_description_label)
	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(_detail_label, 14, Color(1.0, 0.78, 0.30, 0.98))
	content.add_child(_detail_label)
	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(_error_label, 12, Color(1.0, 0.35, 0.55, 0.98))
	content.add_child(_error_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	_cancel_button = Button.new()
	_cancel_button.custom_minimum_size = Vector2(140, 42)
	_cancel_button.pressed.connect(request_cancel)
	_apply_button_style(_cancel_button, false)
	actions.add_child(_cancel_button)
	_confirm_button = Button.new()
	_confirm_button.custom_minimum_size = Vector2(170, 42)
	_confirm_button.pressed.connect(request_confirm)
	_apply_button_style(_confirm_button, true)
	actions.add_child(_confirm_button)


func _apply_button_style(button: Button, emphasized: bool) -> void:
	var fill := Color(0.14, 0.025, 0.11, 0.88) if emphasized else Color(0.025, 0.022, 0.060, 0.86)
	var border := Color(1.0, 0.12, 0.50, 0.86) if emphasized else Color(0.55, 0.34, 0.78, 0.70)
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(fill, border, 8))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(fill.lightened(0.08), border.lightened(0.08), 8))
	button.add_theme_stylebox_override("pressed", HomeTheme.make_button_style(fill.darkened(0.06), border, 8))
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0, 0.98))
	button.add_theme_font_size_override("font_size", 13)
