extends RefCounted
class_name TableSnapshot

var room_id := ""
var phase := "waiting"
var hand_id := 0
var seats: Array = []
var community_cards: Array = []
var pot := 0
var side_pots: Array = []
var current_bet := 0
var min_raise_to := 0
var current_turn_seat := -1
var dealer_seat := -1
var small_blind_seat := -1
var big_blind_seat := -1
var small_blind := 0
var big_blind := 0
var winners: Array = []
var log: Array = []
var recent_actions: Array = []
var action_log: Array = []
var private_snapshot: Dictionary = {}

static func from_dict(data: Dictionary):
	var snapshot = load("res://scripts/state/table_snapshot.gd").new()
	snapshot.apply_table_snapshot(data)
	return snapshot

func apply_table_snapshot(data: Dictionary) -> void:
	room_id = String(data.get("room_id", room_id))
	phase = String(data.get("phase", phase))
	hand_id = int(data.get("hand_id", hand_id))
	seats = Array(data.get("seats", [])).duplicate(true)
	community_cards = Array(data.get("community_cards", [])).duplicate(true)
	pot = int(data.get("pot", pot))
	side_pots = Array(data.get("side_pots", [])).duplicate(true)
	current_bet = int(data.get("current_bet", current_bet))
	min_raise_to = int(data.get("min_raise_to", min_raise_to))
	current_turn_seat = int(data.get("current_turn_seat", current_turn_seat))
	dealer_seat = int(data.get("dealer_seat", dealer_seat))
	small_blind_seat = int(data.get("small_blind_seat", small_blind_seat))
	big_blind_seat = int(data.get("big_blind_seat", big_blind_seat))
	small_blind = int(data.get("small_blind", small_blind))
	big_blind = int(data.get("big_blind", big_blind))
	winners = Array(data.get("winners", [])).duplicate(true)
	log = Array(data.get("log", [])).duplicate()
	recent_actions = Array(data.get("recent_actions", data.get("action_log", []))).duplicate(true)
	action_log = Array(data.get("action_log", recent_actions)).duplicate(true)

func apply_private_snapshot(data: Dictionary) -> void:
	private_snapshot = data.duplicate(true)

func local_hole_cards() -> Array:
	return Array(private_snapshot.get("hole_cards", [])).duplicate(true)

func legal_actions() -> Array:
	return Array(private_snapshot.get("legal_actions", [])).duplicate(true)

func seat_for_player(player_id: String) -> Dictionary:
	for seat in seats:
		var data := Dictionary(seat)
		if String(data.get("player_id", "")) == player_id:
			return data.duplicate(true)
	return {}

func to_dict() -> Dictionary:
	return {
		"room_id": room_id,
		"phase": phase,
		"hand_id": hand_id,
		"seats": seats.duplicate(true),
		"community_cards": community_cards.duplicate(true),
		"pot": pot,
		"side_pots": side_pots.duplicate(true),
		"current_bet": current_bet,
		"min_raise_to": min_raise_to,
		"current_turn_seat": current_turn_seat,
		"dealer_seat": dealer_seat,
		"small_blind_seat": small_blind_seat,
		"big_blind_seat": big_blind_seat,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"winners": winners.duplicate(true),
		"log": log.duplicate(),
		"recent_actions": recent_actions.duplicate(true),
		"action_log": action_log.duplicate(true),
		"private_snapshot": private_snapshot.duplicate(true),
	}
