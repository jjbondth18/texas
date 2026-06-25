extends Control
class_name TableStatusPanel

signal exit_table_requested

var _text: RichTextLabel
var _exit_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_text = RichTextLabel.new()
	_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_text.offset_bottom = -58
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_exit_button = Button.new()
	_exit_button.text = "EXIT TABLE"
	_exit_button.anchor_left = 0.08
	_exit_button.anchor_right = 0.92
	_exit_button.anchor_top = 1.0
	_exit_button.anchor_bottom = 1.0
	_exit_button.offset_top = -52
	_exit_button.offset_bottom = -14
	_exit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_exit_button.pressed.connect(func() -> void:
		exit_table_requested.emit()
	)
	add_child(_exit_button)

func set_status(snapshot: Dictionary) -> void:
	var local := Dictionary(snapshot.get("local_player", {}))
	var seats := Array(snapshot.get("seats", []))
	var occupied := 0
	for seat in seats:
		if String(Dictionary(seat).get("status", "")) != "empty":
			occupied += 1
	var lines := [
		"[b]TABLE STATUS[/b]",
		"Name: %s" % String(snapshot.get("table_name", "")),
		"ID: %s" % String(snapshot.get("table_id", "")),
		"Phase: %s" % String(snapshot.get("phase", "")),
		"Blinds: %s" % String(snapshot.get("blinds_text", "")),
		"Players: %d / 9" % occupied,
		"Local Chips: %s" % int(local.get("chips", 0)),
		"",
		"[b]CONNECTION[/b]",
		String(snapshot.get("connection_status", "Mock local")),
		"",
		"[b]SETTINGS[/b]",
		"Esc: return home",
		"1-5: load phase",
		"R: reset mock hand",
	]
	_text.text = "\n".join(lines)
