extends Control
class_name PotDisplay

var _title: Label
var _amount: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = Label.new()
	_title.text = "POT"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", Color(0.65, 0.76, 1.0))
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_bottom = 24
	add_child(_title)

	_amount = Label.new()
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount.add_theme_font_size_override("font_size", 28)
	_amount.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_amount.set_anchors_preset(Control.PRESET_FULL_RECT)
	_amount.offset_top = 22
	add_child(_amount)
	set_pot({"main": 0, "side_pots": []})

func set_pot(pot_data) -> void:
	var main := 0
	if pot_data is Dictionary:
		main = int(Dictionary(pot_data).get("main", 0))
	else:
		main = int(pot_data)
	if _amount:
		_amount.text = "%s" % main
