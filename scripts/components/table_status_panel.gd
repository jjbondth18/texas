extends Control
class_name TableStatusPanel

var _text: RichTextLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text = RichTextLabel.new()
	_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_text.bbcode_enabled = true
	_text.fit_content = true
	add_child(_text)

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
		"Mock local",
		"",
		"[b]SETTINGS[/b]",
		"Esc: close table",
		"1-5: load phase",
		"R: reset mock hand",
	]
	_text.text = "\n".join(lines)
