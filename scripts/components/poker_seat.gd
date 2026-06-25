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
	_name_label = _make_label(18, Color.WHITE)
	_chips_label = _make_label(15, Color(1.0, 0.86, 0.42))
	_bet_label = _make_label(14, Color(0.68, 0.95, 1.0))
	_status_label = _make_label(13, Color(0.72, 0.76, 0.9))
	_markers_label = _make_label(13, Color(1.0, 0.4, 0.78))
	_cards_root = HBoxContainer.new()
	_cards_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_root.add_theme_constant_override("separation", 6)
	add_child(_cards_root)
	for i in range(2):
		var card = CardViewScene.instantiate()
		card.custom_minimum_size = Vector2(38, 52)
		_cards_root.add_child(card)
	_layout_children()
	set_seat_data({})

func set_seat_data(data: Dictionary) -> void:
	seat_data = data.duplicate(true)
	if _name_label == null:
		return
	_name_label.text = String(seat_data.get("player_name", "Empty Seat"))
	_chips_label.text = "CHIPS %s" % int(seat_data.get("chips", 0))
	_bet_label.text = "BET %s" % int(seat_data.get("current_bet", 0))
	_status_label.text = String(seat_data.get("status", "empty")).to_upper()
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
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _layout_children() -> void:
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_name_label.offset_top = 8
	_name_label.offset_bottom = 30
	_markers_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_markers_label.offset_top = 30
	_markers_label.offset_bottom = 48
	_cards_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_cards_root.offset_top = 48
	_cards_root.offset_bottom = 100
	_chips_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_chips_label.offset_top = -26
	_chips_label.offset_bottom = -8
	_bet_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bet_label.offset_top = -48
	_bet_label.offset_bottom = -28
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_label.offset_top = -68
	_status_label.offset_bottom = -50

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var is_turn := bool(seat_data.get("is_turn", false))
	var folded := String(seat_data.get("status", "")) == "folded"
	var empty := String(seat_data.get("status", "")) == "empty"
	var fill := Color(0.03, 0.04, 0.09, 0.72)
	if folded:
		fill = Color(0.03, 0.03, 0.04, 0.5)
	if empty:
		fill = Color(0.02, 0.02, 0.03, 0.35)
	draw_rect(rect, fill, true)
	draw_rect(rect, Color(0.95, 0.22, 0.78, 0.95) if is_turn else Color(0.46, 0.58, 0.78, 0.45), false, 2.0 if is_turn else 1.0)
