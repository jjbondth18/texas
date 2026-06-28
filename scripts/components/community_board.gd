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
		card.custom_minimum_size = Vector2(88, 138)
		_cards_root.add_child(card)
		_slots.append(card)
	set_cards([])

func set_cards(cards: Array) -> void:
	for i in range(_slots.size()):
		var card = _slots[i]
		if i < cards.size():
			var card_data: Dictionary = Dictionary(cards[i]).duplicate(true)
			card_data["face_up"] = true
			if not card.visible:
				card.visible = true
				card.modulate.a = 0.0
				var tween := create_tween()
				tween.tween_property(card, "modulate:a", 1.0, 0.25)
			card.set_card(card_data)
		else:
			card.visible = false
			card.modulate = Color.WHITE
