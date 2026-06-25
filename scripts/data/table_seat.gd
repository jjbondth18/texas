extends RefCounted
class_name TableSeat

var seat_index := 0
var player_id := ""
var occupied := false
var is_dealer := false
var is_small_blind := false
var is_big_blind := false

func _init(index: int = 0, seated_player_id: String = "", has_player: bool = false) -> void:
	seat_index = index
	player_id = seated_player_id
	occupied = has_player

func to_dict() -> Dictionary:
	return {
		"seat_index": seat_index,
		"player_id": player_id,
		"occupied": occupied,
		"is_dealer": is_dealer,
		"is_small_blind": is_small_blind,
		"is_big_blind": is_big_blind,
	}

static func from_dict(data: Dictionary):
	var seat = load("res://scripts/data/table_seat.gd").new(
		int(data.get("seat_index", 0)),
		String(data.get("player_id", "")),
		bool(data.get("occupied", false))
	)
	seat.is_dealer = bool(data.get("is_dealer", false))
	seat.is_small_blind = bool(data.get("is_small_blind", false))
	seat.is_big_blind = bool(data.get("is_big_blind", false))
	return seat
