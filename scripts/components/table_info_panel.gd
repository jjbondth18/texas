extends PanelContainer
class_name TableInfoPanel

@export_enum("Chat", "Log") var panel_mode: String = "Chat"

var _chat_text: RichTextLabel
var _log_text: RichTextLabel
var _chat_input: LineEdit

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Premium 0.6 opacity dark-glass background style
	var style := HomeTheme.make_panel_style(
		Color(0.008, 0.006, 0.015, 0.60), # 0.6 opacity
		Color(0.62, 0.36, 1.0, 0.30),    # Violet border
		12,
		1
	)
	add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	
	if panel_mode == "Chat":
		var chat_vbox := VBoxContainer.new()
		chat_vbox.name = "CHAT"
		chat_vbox.add_theme_constant_override("separation", 8)
		margin.add_child(chat_vbox)
		
		# Title label
		var title_label := Label.new()
		title_label.text = "TABLE CHAT"
		title_label.add_theme_font_size_override("font_size", 11)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5, 0.8))
		chat_vbox.add_child(title_label)
		
		_chat_text = RichTextLabel.new()
		_chat_text.bbcode_enabled = true
		_chat_text.fit_content = false # Scrollable
		_chat_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_chat_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chat_vbox.add_child(_chat_text)
		
		# Chat Input panel
		var input_hbox := HBoxContainer.new()
		input_hbox.add_theme_constant_override("separation", 8)
		chat_vbox.add_child(input_hbox)
		
		_chat_input = LineEdit.new()
		_chat_input.placeholder_text = "Type a message..."
		_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_chat_input.focus_mode = Control.FOCUS_CLICK
		
		var input_style := StyleBoxFlat.new()
		input_style.bg_color = Color(0.05, 0.03, 0.08, 0.6)
		input_style.border_color = Color(0.62, 0.36, 1.0, 0.3)
		input_style.set_border_width_all(1)
		input_style.set_corner_radius_all(6)
		_chat_input.add_theme_stylebox_override("normal", input_style)
		_chat_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.25))
		_chat_input.add_theme_color_override("font_color", Color.WHITE)
		_chat_input.add_theme_font_size_override("font_size", 12)
		input_hbox.add_child(_chat_input)
		
		var send_btn := Button.new()
		send_btn.text = "Send"
		send_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var send_style := HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 8)
		send_btn.add_theme_stylebox_override("normal", send_style)
		send_btn.add_theme_font_size_override("font_size", 11)
		input_hbox.add_child(send_btn)
		
		# Add text submission behavior to LineEdit
		var send_action = func() -> void:
			if _chat_input.text.strip_edges() != "":
				var formatted = "\n[color=#00c8ff]Luna0581 (YOU)[/color]: %s" % _chat_input.text
				_chat_text.text += formatted
				_chat_input.text = ""
		_chat_input.text_submitted.connect(func(_val): send_action.call())
		send_btn.pressed.connect(send_action)
		
		# Initialize mock chats
		_chat_text.text = (
			"[color=#ff0080]StealyHealy[/color]: Nice hand!\n" +
			"[color=#00ff80]DealerSniper[/color]: Good game guys.\n" +
			"[color=#00c8ff]Luna0581 (YOU)[/color]: Let's play!\n" +
			"[color=#ffdd70]guang-seong[/color]: Check check."
		)
		
	elif panel_mode == "Log":
		var log_vbox := VBoxContainer.new()
		log_vbox.name = "LOG"
		log_vbox.add_theme_constant_override("separation", 8)
		margin.add_child(log_vbox)
		
		# Title label
		var title_label := Label.new()
		title_label.text = "TABLE LOG"
		title_label.add_theme_font_size_override("font_size", 11)
		title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 0.8))
		log_vbox.add_child(title_label)
		
		_log_text = RichTextLabel.new()
		_log_text.bbcode_enabled = true
		_log_text.fit_content = false # Scrollable
		_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_log_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		log_vbox.add_child(_log_text)

func set_info(history: Array, messages: Array) -> void:
	if _log_text == null:
		return
	var lines := ["[color=#ff0080][b]HAND HISTORY[/b][/color]"]
	for item in history:
		lines.append("• %s" % String(item))
	lines.append("")
	lines.append("[color=#00ffff][b]SYSTEM MESSAGES[/b][/color]")
	for item in messages:
		lines.append("• %s" % String(item))
	_log_text.text = "\n".join(lines)

