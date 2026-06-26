extends Control
class_name CommunityBoard

const CardViewScene := preload("res://scenes/components/card_view.tscn")

var _cards_root: HBoxContainer
var _slots: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_root = HBoxContainer.new()
	_cards_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cards_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_root.add_theme_constant_override("separation", 14)
	add_child(_cards_root)
	for i in range(5):
		var card = CardViewScene.instantiate()
		card.custom_minimum_size = Vector2(96, 136)
		_cards_root.add_child(card)
		_slots.append(card)
	set_cards([])

func set_cards(cards: Array) -> void:
	for i in range(_slots.size()):
		var card = _slots[i]
		if i < cards.size():
			card.visible = true
			card.set_card(Dictionary(cards[i]))
		else:
			card.visible = true
			card.set_card({"rank": "", "suit": "", "face_up": false})
			card.modulate = Color.WHITE
		if i < cards.size():
			card.modulate = Color.WHITE
