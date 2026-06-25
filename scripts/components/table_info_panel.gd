extends Control
class_name TableInfoPanel

var _text: RichTextLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text = RichTextLabel.new()
	_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_text.bbcode_enabled = true
	_text.fit_content = true
	add_child(_text)

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
