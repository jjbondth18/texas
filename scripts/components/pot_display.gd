extends Control
class_name PotDisplay

var _title: Label
var _amount: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_title = Label.new()
	_title.text = "TOTAL POT"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", Color(0.68, 0.58, 1.0))
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 8
	_title.offset_bottom = 26
	add_child(_title)

	_amount = Label.new()
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount.add_theme_font_size_override("font_size", 24)
	_amount.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_amount.set_anchors_preset(Control.PRESET_FULL_RECT)
	_amount.offset_top = 26
	_amount.offset_bottom = -8
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
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.008, 0.006, 0.015, 0.65)
	style.border_color = Color(0.62, 0.36, 1.0, 0.45) # Violet neon border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.62, 0.36, 1.0, 0.15)
	style.shadow_size = 6
	style.draw(get_canvas_item(), rect)

