extends RefCounted
class_name TablePlayer

var player_id := ""
var display_name := ""
var chips := 0
var seat_index := -1
var is_local := false
var is_active := false
var cards: Array[Dictionary] = []

func _init(id_value: String = "", name_value: String = "", chip_count: int = 0, seat: int = -1) -> void:
	player_id = id_value
	display_name = name_value
	chips = chip_count
	seat_index = seat

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"display_name": display_name,
		"chips": chips,
		"seat_index": seat_index,
		"is_local": is_local,
		"is_active": is_active,
		"cards": cards.duplicate(true),
	}

static func from_dict(data: Dictionary):
	var player = load("res://scripts/data/table_player.gd").new(
		String(data.get("player_id", "")),
		String(data.get("display_name", "")),
		int(data.get("chips", 0)),
		int(data.get("seat_index", -1))
	)
	player.is_local = bool(data.get("is_local", false))
	player.is_active = bool(data.get("is_active", false))
	player.cards = Array(data.get("cards", [])).duplicate(true)
	return player
