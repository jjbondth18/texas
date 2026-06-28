extends PanelContainer
class_name TableInfoPanel

# POKER TABLE UI FREEZE:
# Do not change layout/position/size of existing poker table UI nodes unless the task explicitly asks for visual changes.
# Logic/data binding changes are allowed, but must not move or resize frozen UI components.

@export_enum("Chat", "Log") var panel_mode: String = "Chat"

const CATEGORY_COLORS := {
	"HAND HISTORY": Color(1.0, 0.0, 0.50),
	"SYSTEM MESSAGES": Color(0.0, 0.95, 1.0),
	"GAME EVENT": Color(1.0, 0.86, 0.08),
	"PLAYER ACTION": Color(0.25, 1.0, 0.48),
}

const CHAT_COLORS := {
	"StealyHealy": Color(1.0, 0.0, 0.50),
	"DealerSniper": Color(0.0, 1.0, 0.60),
	"Luna0581": Color(0.0, 0.78, 1.0),
	"guang-seong": Color(1.0, 0.86, 0.08),
}

var _log_list: VBoxContainer
var _chat_list: VBoxContainer
var _chat_input: LineEdit
var _send_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", _panel_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	if panel_mode == "Chat":
		_build_chat_panel(margin)
	else:
		_build_log_panel(margin)


func _build_log_panel(parent: Control) -> void:
	var root := VBoxContainer.new()
	root.name = "TableLog"
	root.add_theme_constant_override("separation", 11)
	parent.add_child(root)

	root.add_child(_title_label("TABLE LOG", Color(0.62, 0.78, 1.0)))

	var scroll := ScrollContainer.new()
	scroll.name = "TimelineScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(scroll)

	_log_list = VBoxContainer.new()
	_log_list.name = "TimelineRows"
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_log_list)


func _build_chat_panel(parent: Control) -> void:
	var root := VBoxContainer.new()
	root.name = "ChatBox"
	root.add_theme_constant_override("separation", 10)
	parent.add_child(root)

	root.add_child(_title_label("TABLE CHAT", Color(1.0, 0.0, 0.50)))

	var scroll := ScrollContainer.new()
	scroll.name = "ChatScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_chat_list = VBoxContainer.new()
	_chat_list.name = "ChatMessages"
	_chat_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_list.add_theme_constant_override("separation", 9)
	scroll.add_child(_chat_list)

	var input_row := HBoxContainer.new()
	input_row.name = "ChatInputRow"
	input_row.add_theme_constant_override("separation", 8)
	root.add_child(input_row)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Type a message..."
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.focus_mode = Control.FOCUS_CLICK
	_chat_input.add_theme_stylebox_override("normal", _input_style(false))
	_chat_input.add_theme_stylebox_override("focus", _input_style(true))
	_chat_input.add_theme_color_override("font_placeholder_color", Color(0.78, 0.78, 0.88, 0.36))
	_chat_input.add_theme_color_override("font_color", Color.WHITE)
	_chat_input.add_theme_font_size_override("font_size", 13)
	input_row.add_child(_chat_input)

	_send_button = Button.new()
	_send_button.text = "Send"
	_send_button.custom_minimum_size = Vector2(56, 30)
	_send_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_send_button(_send_button)
	input_row.add_child(_send_button)

	var send_action := func() -> void:
		var text := _chat_input.text.strip_edges()
		if text == "":
			return
		_add_chat_message("Luna0581", text, true)
		_chat_input.text = ""
	_chat_input.text_submitted.connect(func(_value: String): send_action.call())
	_send_button.pressed.connect(send_action)

	_add_chat_message("StealyHealy", "Nice hand!", false)
	_add_chat_message("DealerSniper", "Good game guys.", false)
	_add_chat_message("Luna0581", "Let's play!", true)
	_add_chat_message("guang-seong", "Check check.", false)


func set_info(history: Array, messages: Array) -> void:
	if _log_list == null:
		return
	for child in _log_list.get_children():
		child.queue_free()

	var time_base := Time.get_time_dict_from_system()
	if not history.is_empty():
		_add_log_item("HAND HISTORY", _time_text(time_base, 0), history)
	if not messages.is_empty():
		_add_log_item("SYSTEM MESSAGES", _time_text(time_base, 5), messages)


func _add_log_item(category: String, time_text: String, lines: Array) -> void:
	var color := Color(CATEGORY_COLORS.get(category, Color.WHITE))
	var row := HBoxContainer.new()
	row.name = category.capitalize().replace(" ", "") + "Row"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 9)
	_log_list.add_child(row)

	var rail := Control.new()
	rail.custom_minimum_size = Vector2(18, 66)
	row.add_child(rail)
	rail.draw.connect(func() -> void:
		var center_x := 9.0
		rail.draw_line(Vector2(center_x, 0), Vector2(center_x, rail.size.y), Color(0.65, 0.56, 1.0, 0.22), 1.0)
		rail.draw_circle(Vector2(center_x, 15), 4.0, color)
	)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 3)
	row.add_child(content)

	var time_label := _body_label(time_text, 13, Color(0.78, 0.78, 0.88, 0.70))
	content.add_child(time_label)
	var cat_label := _body_label(category, 16, color)
	cat_label.add_theme_font_override("font", _bold_font())
	content.add_child(cat_label)

	for item in lines:
		var line_label := _body_label(String(item), 14, Color(0.92, 0.92, 0.98, 0.94))
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(line_label)


func _add_chat_message(player_name: String, text: String, is_you: bool) -> void:
	if _chat_list == null:
		return
	var row := VBoxContainer.new()
	row.name = player_name + "Message"
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_list.add_child(row)

	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(top)

	var name_label := _body_label(player_name, 14, Color(CHAT_COLORS.get(player_name, Color.WHITE)))
	name_label.add_theme_font_override("font", _bold_font())
	top.add_child(name_label)
	if is_you:
		var badge := _you_badge()
		top.add_child(badge)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_body_label(_short_time(), 12, Color(0.75, 0.75, 0.84, 0.62)))

	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.add_theme_stylebox_override("panel", _bubble_style(is_you))
	row.add_child(bubble)

	var bubble_text := _body_label(text, 14, Color(0.96, 0.96, 1.0, 0.96))
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.custom_minimum_size = Vector2(minf(230, maxf(90, text.length() * 8.4)), 0)
	bubble.add_child(bubble_text)


func _title_label(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", _bold_font())
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	return label


func _body_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _you_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _badge_style())
	var label := _body_label("YOU", 10, Color(0.92, 0.96, 1.0))
	label.add_theme_font_override("font", _bold_font())
	badge.add_child(label)
	return badge


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.006, 0.024, 0.62)
	style.border_color = Color(0.68, 0.38, 1.0, 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.75, 0.18, 1.0, 0.18)
	style.shadow_size = 12
	return style


func _bubble_style(is_you: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.20, 0.74) if not is_you else Color(0.02, 0.12, 0.20, 0.78)
	style.border_color = Color(0.72, 0.46, 1.0, 0.20) if not is_you else Color(0.0, 0.80, 1.0, 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 6
	return style


func _input_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.020, 0.060, 0.66)
	style.border_color = Color(1.0, 0.0, 0.5, 0.72 if focused else 0.38)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.45, 0.75, 0.56)
	style.border_color = Color(0.0, 0.85, 1.0, 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


func _style_send_button(button: Button) -> void:
	var normal := HomeTheme.make_button_style(Color(0.12, 0.03, 0.10, 0.58), Color(1.0, 0.0, 0.5, 0.72), 7)
	var hover := HomeTheme.make_button_style(Color(0.20, 0.05, 0.16, 0.76), Color(1.0, 0.0, 0.5, 1.0), 7)
	normal.shadow_color = Color(1.0, 0.0, 0.5, 0.16)
	normal.shadow_size = 6
	hover.shadow_color = Color(1.0, 0.0, 0.5, 0.34)
	hover.shadow_size = 10
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 11)


func _bold_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["sans-serif", "Segoe UI", "Arial"])
	font.font_weight = 700
	return font


func _short_time() -> String:
	var t := Time.get_time_dict_from_system()
	return "%02d:%02d" % [int(t.hour), int(t.minute)]


func _time_text(time_data: Dictionary, offset_seconds: int) -> String:
	var total := int(time_data.hour) * 3600 + int(time_data.minute) * 60 + int(time_data.second) + offset_seconds
	total = posmod(total, 24 * 3600)
	var hour := total / 3600
	var minute := (total / 60) % 60
	var second := total % 60
	return "%02d:%02d:%02d" % [hour, minute, second]
