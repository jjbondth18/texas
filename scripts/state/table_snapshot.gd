extends RefCounted
class_name TableSnapshot

var room_id := ""
var table_info: Dictionary = {}
var buy_in := 0
var phase := "waiting"
var hand_state := "waiting"
var table_state := "waiting"
var room_state := "waiting"
var hand_id := 0
var hand_count := 0
var max_hands := 0
var hands_played := 0
var current_hand_number := 0
var session_complete := false
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
var last_hand_results: Array = []
var log: Array = []
var recent_actions: Array = []
var action_log: Array = []
var private_snapshot: Dictionary = {}
var host_player_id := ""
var official_hand_started := false
var ready_count := 0
var ready_required_count := 0
var ready_countdown_deadline_at := ""
var hand_result_deadline_at := ""
var action_timeout_ms := 0
var action_deadline_at := ""
var dev_simulated_player_present := false

static func from_dict(data: Dictionary):
	var snapshot = load("res://scripts/state/table_snapshot.gd").new()
	snapshot.apply_table_snapshot(data)
	return snapshot

func apply_table_snapshot(data: Dictionary) -> void:
	room_id = String(data.get("room_id", room_id))
	table_info = Dictionary(data.get("table_info", table_info)).duplicate(true)
	buy_in = int(data.get("buy_in", table_info.get("buy_in", buy_in)))
	phase = String(data.get("phase", phase))
	hand_state = String(data.get("hand_state", data.get("phase", hand_state)))
	table_state = String(data.get("table_state", table_info.get("table_state", table_state)))
	room_state = String(data.get("room_state", table_info.get("room_state", room_state)))
	hand_id = int(data.get("hand_id", hand_id))
	hand_count = int(data.get("hand_count", table_info.get("hand_count", hand_count)))
	max_hands = int(data.get("max_hands", data.get("hand_count", table_info.get("max_hands", table_info.get("hand_count", max_hands)))))
	hands_played = int(data.get("hands_played", table_info.get("hands_played", hands_played)))
	current_hand_number = int(data.get("current_hand_number", table_info.get("current_hand_number", current_hand_number)))
	session_complete = bool(data.get("session_complete", table_info.get("session_complete", session_complete)))
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
	last_hand_results = Array(data.get("last_hand_results", [])).duplicate(true)
	log = Array(data.get("log", [])).duplicate()
	recent_actions = Array(data.get("recent_actions", data.get("action_log", []))).duplicate(true)
	action_log = Array(data.get("action_log", recent_actions)).duplicate(true)
	host_player_id = String(data.get("host_player_id", table_info.get("host_player_id", host_player_id)))
	official_hand_started = bool(data.get("official_hand_started", table_info.get("official_hand_started", official_hand_started)))
	ready_count = int(data.get("ready_count", table_info.get("ready_count", ready_count)))
	ready_required_count = int(data.get("ready_required_count", table_info.get("ready_required_count", ready_required_count)))
	ready_countdown_deadline_at = String(data.get("ready_countdown_deadline_at", table_info.get("ready_countdown_deadline_at", ready_countdown_deadline_at)))
	hand_result_deadline_at = String(data.get("hand_result_deadline_at", table_info.get("hand_result_deadline_at", hand_result_deadline_at)))
	action_timeout_ms = int(data.get("action_timeout_ms", table_info.get("action_timeout_ms", action_timeout_ms)))
	action_deadline_at = String(data.get("action_deadline_at", table_info.get("action_deadline_at", action_deadline_at)))
	dev_simulated_player_present = bool(data.get("dev_simulated_player_present", table_info.get("dev_simulated_player_present", dev_simulated_player_present)))

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
		"table_info": table_info.duplicate(true),
		"buy_in": buy_in,
		"phase": phase,
		"hand_state": hand_state,
		"table_state": table_state,
		"room_state": room_state,
		"hand_id": hand_id,
		"hand_count": hand_count,
		"max_hands": max_hands,
		"hands_played": hands_played,
		"current_hand_number": current_hand_number,
		"session_complete": session_complete,
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
		"last_hand_results": last_hand_results.duplicate(true),
		"log": log.duplicate(),
		"recent_actions": recent_actions.duplicate(true),
		"action_log": action_log.duplicate(true),
		"private_snapshot": private_snapshot.duplicate(true),
		"host_player_id": host_player_id,
		"official_hand_started": official_hand_started,
		"ready_count": ready_count,
		"ready_required_count": ready_required_count,
		"ready_countdown_deadline_at": ready_countdown_deadline_at,
		"hand_result_deadline_at": hand_result_deadline_at,
		"action_timeout_ms": action_timeout_ms,
		"action_deadline_at": action_deadline_at,
		"dev_simulated_player_present": dev_simulated_player_present,
	}
