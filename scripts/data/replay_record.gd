extends RefCounted
class_name ReplayRecord

var replay_id := ""
var replay_type := ""
var price_gems := -1
var locked := true
var unlocked := false
var file_path := ""
var played_at := ""
var mode := ""
var dealer_id := ""
var table_name := ""
var result := ""
var net_chips := 0
var hero_cards: Array[Dictionary] = []
var final_board: Array[String] = []
var biggest_pot := 0
var analysis_available := false
var analysis_locked := true
var favorite := false

func _init(data: Dictionary = {}) -> void:
	replay_id = str(data.get("replay_id", ""))
	replay_type = str(data.get("replay_type", ""))
	price_gems = int(data.get("price_gems", -1))
	locked = bool(data.get("locked", true))
	unlocked = bool(data.get("unlocked", not locked))
	file_path = str(data.get("file_path", ""))
	played_at = str(data.get("played_at", ""))
	mode = str(data.get("mode", ""))
	dealer_id = str(data.get("dealer_id", ""))
	table_name = str(data.get("table_name", ""))
	result = str(data.get("result", ""))
	net_chips = int(data.get("net_chips", 0))
	hero_cards = []
	for card in Array(data.get("hero_cards", [])):
		hero_cards.append(Dictionary(card))
	final_board = []
	for card_code in Array(data.get("final_board", [])):
		final_board.append(str(card_code))
	biggest_pot = int(data.get("biggest_pot", 0))
	analysis_available = bool(data.get("analysis_available", false))
	analysis_locked = bool(data.get("analysis_locked", true))
	favorite = bool(data.get("favorite", false))

func to_dict() -> Dictionary:
	return {
		"replay_id": replay_id,
		"replay_type": replay_type,
		"price_gems": price_gems,
		"locked": locked,
		"unlocked": unlocked,
		"file_path": file_path,
		"played_at": played_at,
		"mode": mode,
		"dealer_id": dealer_id,
		"table_name": table_name,
		"result": result,
		"net_chips": net_chips,
		"hero_cards": hero_cards.duplicate(true),
		"final_board": final_board.duplicate(),
		"biggest_pot": biggest_pot,
		"analysis_available": analysis_available,
		"analysis_locked": analysis_locked,
		"favorite": favorite,
	}

static func mock_default():
	return load("res://scripts/data/replay_record.gd").new({
		"replay_id": "replay_001",
		"played_at": "2026-06-25 22:41",
		"mode": "Quick Play",
		"table_name": "Neon Table 01",
		"result": "win",
		"net_chips": 1250,
		"hero_cards": [
			{"code": "AS", "rank": "A", "suit": "spades"},
			{"code": "KS", "rank": "K", "suit": "spades"},
		],
		"final_board": ["QS", "JS", "2D", "7C", "TH"],
		"biggest_pot": 4200,
		"analysis_available": true,
		"analysis_locked": true,
		"favorite": false,
	})
