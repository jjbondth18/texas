extends Control
class_name PotDisplay

const POT_CHIPS_TEXTURE := preload("res://assets/ui/chips/chips_scattered.png")

var _chip_stack: TextureRect
var _title: Label
var _amount: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_chip_stack = TextureRect.new()
	_chip_stack.texture = POT_CHIPS_TEXTURE
	_chip_stack.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chip_stack.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chip_stack.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_chip_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip_stack.modulate = Color(1.0, 1.0, 1.0, 0.92)
	add_child(_chip_stack)
	
	_title = Label.new()
	_title.text = "TOTAL POT"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 13)
	_title.add_theme_color_override("font_color", Color(0.68, 0.58, 1.0))
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 7
	_title.offset_bottom = 25
	add_child(_title)

	_amount = Label.new()
	_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount.add_theme_font_size_override("font_size", 25)
	_amount.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_amount.set_anchors_preset(Control.PRESET_FULL_RECT)
	_amount.offset_left = 66
	_amount.offset_top = 34
	_amount.offset_bottom = -4
	add_child(_amount)
	set_pot({"main": 0, "side_pots": []})
	_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _chip_stack != null:
		_layout()

func set_pot(pot_data) -> void:
	var main := 0
	if pot_data is Dictionary:
		main = int(Dictionary(pot_data).get("main", 0))
	else:
		main = int(pot_data)
	if _amount:
		_amount.text = _format_chips(main)
	if _chip_stack:
		_chip_stack.modulate = Color(1.0, 1.0, 1.0, 0.92 if main > 0 else 0.18)
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

func _layout() -> void:
	var chip_size := Vector2(82, 54)
	_chip_stack.position = Vector2(18, size.y * 0.5 - chip_size.y * 0.5 + 6)
	_chip_stack.size = chip_size

func _format_chips(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	var count: int = 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = text[i] + result
		count += 1
	return result
