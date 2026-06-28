extends RefCounted
class_name TableSeat

const EMPTY := "empty"
const SITTING := "sitting"
const PLAYING := "playing"
const FOLDED := "folded"
const ALL_IN := "all_in"
const OUT := "out"

var seat_index := 0
var seat_id := 0
var player_id := ""
var player_name := ""
var chips := 0
var current_bet := 0
var hole_cards: Array[Dictionary] = []
var status := EMPTY
var occupied := false
var is_dealer := false
var is_small_blind := false
var is_big_blind := false
var is_local := false

func _init(index: int = 0, seated_player_id: String = "", has_player: bool = false) -> void:
	seat_index = index
	seat_id = index
	player_id = seated_player_id
	occupied = has_player
	status = SITTING if has_player else EMPTY

func to_dict() -> Dictionary:
	return {
		"seat_index": seat_index,
		"seat_id": seat_id,
		"player_id": player_id,
		"player_name": player_name,
		"chips": chips,
		"current_bet": current_bet,
		"hole_cards": hole_cards.duplicate(true),
		"status": status,
		"occupied": occupied,
		"is_dealer": is_dealer,
		"is_small_blind": is_small_blind,
		"is_big_blind": is_big_blind,
		"is_local": is_local,
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
	seat.seat_id = int(data.get("seat_id", seat.seat_index))
	seat.player_name = String(data.get("player_name", ""))
	seat.chips = int(data.get("chips", 0))
	seat.current_bet = int(data.get("current_bet", 0))
	seat.hole_cards = Array(data.get("hole_cards", [])).duplicate(true)
	seat.status = String(data.get("status", SITTING if seat.occupied else EMPTY))
	seat.is_local = bool(data.get("is_local", false))
	return seat
