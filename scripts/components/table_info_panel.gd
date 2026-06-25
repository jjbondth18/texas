extends PanelContainer
class_name TableInfoPanel

var _text: RichTextLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 暗玻璃背景 StyleBoxFlat
	var style := HomeTheme.make_panel_style(
		Color(0.008, 0.006, 0.015, 0.76),
		Color(0.62, 0.36, 1.0, 0.24),
		12,
		1
	)
	add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_text)

func set_info(history: Array, messages: Array) -> void:
	if _text == null:
		return
	var lines := ["[b]TABLE INFO[/b]", "", "[b]HAND HISTORY[/b]"]
	for item in history:
		lines.append("• %s" % String(item))
	lines.append("")
	lines.append("[b]SYSTEM MESSAGES[/b]")
	for item in messages:
		lines.append("• %s" % String(item))
	lines.append("")
	lines.append("[b]NOTIFICATIONS[/b]\n• Mock table only")
	_text.text = "\n".join(lines)
