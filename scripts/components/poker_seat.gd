extends Control
class_name PokerSeat

const SeatPlayerCardScene := preload("res://scenes/components/seat_player_card.tscn")

var seat_data: Dictionary = {}
var _seat_card: SeatPlayerCard


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(180, 110)
	_seat_card = SeatPlayerCardScene.instantiate() as SeatPlayerCard
	_seat_card.name = "SeatPlayerCard"
	_seat_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_seat_card)
	_layout_card()
	set_seat_data({})


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _seat_card != null:
		_layout_card()


func set_seat_data(data: Dictionary) -> void:
	seat_data = data.duplicate(true)
	if _seat_card == null:
		return

	var status: String = String(seat_data.get("status", "empty"))
	var player_name: String = String(seat_data.get("player_name", "Empty Seat"))
	var is_empty: bool = status == "empty"
	var card_data: Dictionary = {
		"player_name": "EMPTY" if is_empty else player_name,
		"chips": int(seat_data.get("chips", 0)),
		"avatar_texture": seat_data.get("avatar_texture", null),
		"is_empty": is_empty,
		"is_dealer": bool(seat_data.get("is_dealer", false)),
		"is_small_blind": bool(seat_data.get("is_small_blind", false)),
		"is_big_blind": bool(seat_data.get("is_big_blind", false)),
		"is_active_turn": bool(seat_data.get("is_turn", false)),
		"is_local_player": bool(seat_data.get("is_local", false)),
		"current_bet": int(seat_data.get("current_bet", 0)),
		"seat_id": int(seat_data.get("seat_id", seat_data.get("seat_index", 0))),
		"visual_position": int(seat_data.get("visual_position", seat_data.get("seat_index", 0))),
		"last_action": String(seat_data.get("last_action", "")),
		"status": String(seat_data.get("raw_status", seat_data.get("status", ""))),
		"cards": Array(seat_data.get("cards", [])).duplicate(true),
	}
	_seat_card.set_card_data(card_data)


func show_action_toast(action_label: String, amount: int = 0) -> void:
	if _seat_card != null and _seat_card.has_method("show_action_toast"):
		_seat_card.call("show_action_toast", action_label, amount)


func _layout_card() -> void:
	var card_size: Vector2 = Vector2(324.0, 194.0)
	_seat_card.size = card_size
	_seat_card.position = (size - card_size) * 0.5
