extends Control
class_name PokerSeat

const CardViewScene := preload("res://scenes/components/card_view.tscn")

var seat_data := {}
var _name_label: Label
var _chips_label: Label
var _bet_label: Label
var _status_label: Label
var _markers_label: Label
var _cards_root: HBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(220, 126)
	_name_label = _make_label(15, Color.WHITE)
	_chips_label = _make_label(13, Color(1.0, 0.86, 0.42))
	_bet_label = _make_label(12, Color(0.68, 0.95, 1.0))
	_status_label = _make_label(12, Color(0.72, 0.76, 0.9))
	_markers_label = _make_label(11, Color(1.0, 0.4, 0.78))
	_cards_root = HBoxContainer.new()
	_cards_root.alignment = BoxContainer.ALIGNMENT_BEGIN
	_cards_root.add_theme_constant_override("separation", 6)
	add_child(_cards_root)
	for i in range(2):
		var card = CardViewScene.instantiate()
		card.custom_minimum_size = Vector2(38, 52)
		_cards_root.add_child(card)
	_layout_children()
	set_seat_data({})

func _process(_delta: float) -> void:
	var is_turn := bool(seat_data.get("is_turn", false))
	var empty := String(seat_data.get("status", "")) == "empty"
	if is_turn and not empty:
		queue_redraw()

func set_seat_data(data: Dictionary) -> void:
	seat_data = data.duplicate(true)
	if _name_label == null:
		return
	_name_label.text = String(seat_data.get("player_name", "Empty Seat"))
	
	var empty := String(seat_data.get("status", "")) == "empty"
	var is_local := bool(seat_data.get("is_local", false))
	
	_chips_label.visible = not empty
	_chips_label.text = "CHIPS %s" % int(seat_data.get("chips", 0))
	_bet_label.visible = not empty and int(seat_data.get("current_bet", 0)) > 0
	_bet_label.text = "BET %s" % int(seat_data.get("current_bet", 0))
	_status_label.visible = not empty and String(seat_data.get("status", "")) != "playing"
	_status_label.text = String(seat_data.get("status", "empty")).to_upper()
	_cards_root.visible = not empty and not is_local
	
	var markers: Array[String] = []
	if bool(seat_data.get("is_dealer", false)):
		markers.append("D")
	if bool(seat_data.get("is_small_blind", false)):
		markers.append("SB")
	if bool(seat_data.get("is_big_blind", false)):
		markers.append("BB")
	if bool(seat_data.get("is_local", false)):
		markers.append("YOU")
	_markers_label.text = " ".join(markers)
	
	var cards := Array(seat_data.get("cards", []))
	for i in range(_cards_root.get_child_count()):
		var card = _cards_root.get_child(i)
		if i < cards.size():
			card.visible = true
			card.set_card(Dictionary(cards[i]))
		else:
			card.visible = false
			
	queue_redraw()

func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _layout_children() -> void:
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_name_label.offset_left = 68
	_name_label.offset_right = -8
	_name_label.offset_top = 8
	_name_label.offset_bottom = 26
	
	_markers_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_markers_label.offset_left = 68
	_markers_label.offset_right = -8
	_markers_label.offset_top = 26
	_markers_label.offset_bottom = 42
	
	_cards_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_cards_root.offset_left = 68
	_cards_root.offset_right = -8
	_cards_root.offset_top = 44
	_cards_root.offset_bottom = 96
	
	_chips_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_chips_label.offset_left = 42
	_chips_label.offset_right = -8
	_chips_label.offset_top = -24
	_chips_label.offset_bottom = -6
	
	_bet_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bet_label.offset_left = 68
	_bet_label.offset_right = -8
	_bet_label.offset_top = -42
	_bet_label.offset_bottom = -24
	
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_label.offset_left = 68
	_status_label.offset_right = -8
	_status_label.offset_top = -60
	_status_label.offset_bottom = -42

func _draw() -> void:
	var is_turn := bool(seat_data.get("is_turn", false))
	var folded := String(seat_data.get("status", "")) == "folded"
	var empty := String(seat_data.get("status", "")) == "empty"
	var is_local := bool(seat_data.get("is_local", false))

	# Frosted dark-glass background style
	var bg_color := Color(0.015, 0.01, 0.025, 0.65)
	var border_color := Color(0.62, 0.36, 1.0, 0.24)
	
	if is_local:
		border_color = Color(0.0, 0.75, 1.0, 0.45)
	
	if empty:
		bg_color = Color(0.01, 0.008, 0.012, 0.30)
		border_color = Color(0.2, 0.24, 0.38, 0.12)
	elif folded:
		bg_color = Color(0.005, 0.005, 0.008, 0.50)
		border_color = Color(0.1, 0.1, 0.12, 0.15)
		
	if is_turn and not empty:
		border_color = Color(1.0, 0.0, 0.5, 1.0)
		
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2 if is_turn else 1)
	style.set_corner_radius_all(14)
	
	if is_turn and not empty:
		var pulse := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
		style.shadow_color = Color(1.0, 0.0, 0.5, 0.2 + pulse * 0.35)
		style.shadow_size = int(6 + pulse * 8)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3

	style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	
	# Draw player avatar circle
	var avatar_center := Vector2(34, 42)
	var avatar_color := Color(0.18, 0.15, 0.28, 0.8)
	var avatar_border := Color(0.62, 0.36, 1.0, 0.45)
	
	if empty:
		avatar_color = Color(0.1, 0.1, 0.12, 0.4)
		avatar_border = Color(0.2, 0.24, 0.38, 0.2)
	elif folded:
		avatar_color = Color(0.05, 0.05, 0.07, 0.5)
		avatar_border = Color(0.15, 0.15, 0.18, 0.15)
	elif is_local:
		avatar_color = Color(0.08, 0.18, 0.28, 0.8)
		avatar_border = Color(0.0, 0.75, 1.0, 0.60)
		
	draw_circle(avatar_center, 22, avatar_color)
	draw_arc(avatar_center, 22, 0, TAU, 32, avatar_border, 1.5, true)
	
	if not empty:
		draw_circle(avatar_center, 14, Color(avatar_border.r, avatar_border.g, avatar_border.b, 0.25))
		
		# Draw gold micro-chip icon
		var chip_center := Vector2(28, size.y - 15)
		draw_circle(chip_center, 6.5, Color(1.0, 0.84, 0.0, 0.95))
		draw_circle(chip_center, 4, Color(0.9, 0.45, 0.0, 0.95))
		draw_circle(chip_center, 1.5, Color(1.0, 1.0, 1.0, 0.95))

	if folded:
		var overlay := StyleBoxFlat.new()
		overlay.bg_color = Color(0.0, 0.0, 0.0, 0.55)
		overlay.set_corner_radius_all(14)
		overlay.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
