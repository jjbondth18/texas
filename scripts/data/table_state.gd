extends RefCounted
class_name TableState

const WAITING := "waiting"
const HAND_STARTING := "hand_starting"
const PREFLOP := "preflop"
const FLOP := "flop"
const TURN := "turn"
const RIVER := "river"
const SHOWDOWN := "showdown"
const HAND_OVER := "hand_over"

var table_id := ""
var table_name := ""
var blinds_text := ""
var pot := 0
var phase := WAITING
var hand_data: Dictionary = {}
var community_cards: Array[Dictionary] = []
var seats: Array[Dictionary] = []
var local_player: Dictionary = {}
var available_actions: Array[Dictionary] = []
var table_log: Array[String] = []

func _init(id_value: String = "", name_value: String = "") -> void:
	table_id = id_value
	table_name = name_value

func to_dict() -> Dictionary:
	return {
		"table_id": table_id,
		"table_name": table_name,
		"blinds_text": blinds_text,
		"pot": pot,
		"phase": phase,
		"hand_data": hand_data.duplicate(true),
		"community_cards": community_cards.duplicate(true),
		"seats": seats.duplicate(true),
		"local_player": local_player.duplicate(true),
		"available_actions": available_actions.duplicate(true),
		"table_log": table_log.duplicate(),
	}

static func from_dict(data: Dictionary):
	var state = load("res://scripts/data/table_state.gd").new(
		String(data.get("table_id", "")),
		String(data.get("table_name", ""))
	)
	state.blinds_text = String(data.get("blinds_text", ""))
	state.pot = int(data.get("pot", 0))
	state.phase = String(data.get("phase", WAITING))
	state.hand_data = Dictionary(data.get("hand_data", {})).duplicate(true)
	state.community_cards = Array(data.get("community_cards", [])).duplicate(true)
	state.seats = Array(data.get("seats", [])).duplicate(true)
	state.local_player = Dictionary(data.get("local_player", {})).duplicate(true)
	state.available_actions = Array(data.get("available_actions", [])).duplicate(true)
	state.table_log = Array(data.get("table_log", [])).duplicate()
	return state
