extends Control
class_name PokerSeat

const CardViewScene := preload("res://scenes/components/card_view.tscn")

var seat_data := {}
var _name_label: Label
var _chips_label: Label
var _bet_label: Label
var _status_label: Label
var _role_label: Label
var _cards_root: HBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(120, 90)
	
	_name_label = _make_label(12, Color.WHITE)
	_name_label.name = "PlayerName"
	
	_chips_label = _make_label(11, Color(1.0, 0.86, 0.42))
	_chips_label.name = "ChipsCount"
	
	_bet_label = _make_label(11, Color(0.68, 0.95, 1.0))
	_bet_label.name = "BetAmount"
	
	_status_label = _make_label(10, Color(0.72, 0.76, 0.9))
	_status_label.name = "PlayerStatus"
	
	_role_label = _make_label(9, Color.WHITE)
	_role_label.name = "RoleBadgeText"
	_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_cards_root = HBoxContainer.new()
	_cards_root.name = "HoleCards"
	_cards_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_root.add_theme_constant_override("separation", 2)
	_cards_root.modulate.a = 0.4
	add_child(_cards_root)
	
	for i in range(2):
		var card = CardViewScene.instantiate()
		card.set_as_mini_back(true)
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
		
	_layout_children()
		
	var empty := String(seat_data.get("status", "")) == "empty"
	var is_local := bool(seat_data.get("is_local", false))
	
	_name_label.text = String(seat_data.get("player_name", "Empty Seat")) if not empty else "EMPTY"
	
	_chips_label.visible = not empty
	_chips_label.text = "%d" % int(seat_data.get("chips", 0))
	
	_bet_label.visible = not empty and int(seat_data.get("current_bet", 0)) > 0
	_bet_label.text = "BET %d" % int(seat_data.get("current_bet", 0))
	
	_status_label.visible = not empty and String(seat_data.get("status", "")) not in ["playing", "active"]
	_status_label.text = String(seat_data.get("status", "")).to_upper()
	
	_cards_root.visible = not empty and not is_local
	
	# Role label setup
	if empty:
		_role_label.visible = false
	else:
		if bool(seat_data.get("is_dealer", false)):
			_role_label.text = "D"
			_role_label.visible = true
		elif bool(seat_data.get("is_small_blind", false)):
			_role_label.text = "SB"
			_role_label.visible = true
		elif bool(seat_data.get("is_big_blind", false)):
			_role_label.text = "BB"
			_role_label.visible = true
		else:
			_role_label.visible = false
			
	var cards := Array(seat_data.get("cards", []))
	for i in range(_cards_root.get_child_count()):
		var card = _cards_root.get_child(i)
		if i < cards.size():
			card.visible = true
			card.set_card(Dictionary(cards[i]))
			card.set_as_mini_back(true)
		else:
			card.visible = false
			
	queue_redraw()

func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _layout_children() -> void:
	var center_x := size.x * 0.5
	_cards_root.position = Vector2(center_x - 25, 2)
	_cards_root.size = Vector2(50, 30)

	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(center_x - 60, 60)
	_name_label.size = Vector2(120, 18)

	_chips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chips_label.position = Vector2(center_x - 60, 78)
	_chips_label.size = Vector2(120, 16)

	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.position = Vector2(center_x - 60, 42)
	_status_label.size = Vector2(120, 16)

	_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bet_label.position = Vector2(center_x - 60, 102)
	_bet_label.size = Vector2(120, 16)

	# Role badge centered on the top-right of the avatar
	var avatar_center := Vector2(center_x, 32)
	var badge_center := avatar_center + Vector2(16, 16)
	_role_label.position = badge_center - Vector2(9, 9)
	_role_label.size = Vector2(18, 18)

func _draw() -> void:
	var is_turn := bool(seat_data.get("is_turn", false))
	var folded := String(seat_data.get("status", "")) == "folded"
	var empty := String(seat_data.get("status", "")) == "empty"
	var is_local := bool(seat_data.get("is_local", false))

	# Frosted dark-glass background style for name/chips pill only!
	var bg_color := Color(0.008, 0.006, 0.015, 0.65)
	var border_color := Color(0.62, 0.36, 1.0, 0.24)
	
	if is_local:
		border_color = Color(0.0, 0.75, 1.0, 0.45)
	
	if empty:
		bg_color = Color(0.005, 0.004, 0.008, 0.30)
		border_color = Color(0.2, 0.24, 0.38, 0.12)
	elif folded:
		bg_color = Color(0.002, 0.002, 0.004, 0.50)
		border_color = Color(0.1, 0.1, 0.12, 0.15)
		
	if is_turn and not empty:
		border_color = Color(1.0, 0.0, 0.5, 1.0)
		
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2 if is_turn else 1)
	style.set_corner_radius_all(6) # Pill rounded corners
	
	if is_turn and not empty:
		var pulse := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
		style.shadow_color = Color(1.0, 0.0, 0.5, 0.2 + pulse * 0.35)
		style.shadow_size = int(6 + pulse * 8)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

	# Draw the pill behind the name and chips text only!
	var center_x := size.x * 0.5
	var pill_rect := Rect2(center_x - 60, 58, 120, 44)
	var avatar_center := Vector2(center_x, 32)
		
	style.draw(get_canvas_item(), pill_rect)
	
	# Draw player avatar circle
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
		
	if is_turn and not empty:
		avatar_border = Color(1.0, 0.0, 0.5, 1.0)
		
	draw_circle(avatar_center, 24, avatar_color)
	
	# Breathing neon outline ring on active turn
	if is_turn and not empty:
		var pulse := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
		var outer_border := Color(1.0, 0.0, 0.5, 0.7 + pulse * 0.3)
		draw_arc(avatar_center, 25.5, 0, TAU, 32, outer_border, 2.0, true)
	else:
		draw_arc(avatar_center, 24, 0, TAU, 32, avatar_border, 1.0, true)
	
	if not empty:
		draw_circle(avatar_center, 14, Color(avatar_border.r, avatar_border.g, avatar_border.b, 0.25))
		
		# Draw gold micro-chip icon next to the chip count
		var chip_center := Vector2(center_x - 40, 86)
		draw_circle(chip_center, 4.5, Color(1.0, 0.84, 0.0, 0.95))
		draw_circle(chip_center, 2.5, Color(0.9, 0.45, 0.0, 0.95))
		draw_circle(chip_center, 1.0, Color(1.0, 1.0, 1.0, 0.95))

	# Draw role badge (D, SB, BB) circle background
	if _role_label.visible and not empty:
		var badge_center := avatar_center + Vector2(16, 16)
		var badge_color := Color(1, 0.84, 0.0) if _role_label.text == "D" else Color(1.0, 0.0, 0.5)
		var badge_border := Color(1, 1, 1, 0.8)
		draw_circle(badge_center, 9, badge_color)
		draw_arc(badge_center, 9, 0, TAU, 16, badge_border, 1.0, true)

	if folded:
		var overlay := StyleBoxFlat.new()
		overlay.bg_color = Color(0.0, 0.0, 0.0, 0.55)
		overlay.set_corner_radius_all(6)
		overlay.draw(get_canvas_item(), pill_rect)
