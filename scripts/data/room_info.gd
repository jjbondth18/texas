extends RefCounted
class_name RoomInfo

var room_id := ""
var name := ""
var mode := ""
var players := 0
var max_players := 6
var small_blind := 0
var big_blind := 0
var buy_in_min := 0
var buy_in_max := 0
var status := "open"
var is_private := false

func _init(
	id_value: String = "",
	room_name: String = "",
	mode_id: String = "",
	player_count: int = 0,
	max_player_count: int = 6,
	sb: int = 0,
	bb: int = 0,
	min_buy_in: int = 0,
	max_buy_in: int = 0,
	room_status: String = "open",
	private_room: bool = false
) -> void:
	room_id = id_value
	name = room_name
	mode = mode_id
	players = player_count
	max_players = max_player_count
	small_blind = sb
	big_blind = bb
	buy_in_min = min_buy_in
	buy_in_max = max_buy_in
	status = room_status
	is_private = private_room

func to_dict() -> Dictionary:
	return {
		"room_id": room_id,
		"name": name,
		"mode": mode,
		"players": players,
		"max_players": max_players,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"buy_in_min": buy_in_min,
		"buy_in_max": buy_in_max,
		"status": status,
		"is_private": is_private,
	}

static func from_dict(data: Dictionary):
	return load("res://scripts/data/room_info.gd").new(
		String(data.get("room_id", "")),
		String(data.get("name", "")),
		String(data.get("mode", "")),
		int(data.get("players", 0)),
		int(data.get("max_players", 6)),
		int(data.get("small_blind", 0)),
		int(data.get("big_blind", 0)),
		int(data.get("buy_in_min", 0)),
		int(data.get("buy_in_max", 0)),
		String(data.get("status", "open")),
		bool(data.get("is_private", false))
	)
