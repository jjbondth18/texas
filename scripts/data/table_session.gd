extends RefCounted
class_name TableSession

const MODE_QUICK_PLAY := "quick_play"
const MODE_TRAINING := "training"
const MODE_FRIENDS_ROOM := "friends_room"

var mode := MODE_QUICK_PLAY
var buy_in := 20000
var starting_chips := 20000
var current_table_chips := 20000
var small_blind := 25
var big_blind := 50
var max_hands := 10
var current_hand_index := 0
var session_start_chips := 20000
var session_end_chips := 20000
var session_profit := 0
var hands_played := 0
var hands_won := 0
var biggest_pot := 0
var best_hand_desc := "-"
var is_session_over := false
var end_reason := ""
var last_winner := "-"
var last_win_amount := 0

func configure_from_context(context: Dictionary) -> void:
	mode = String(context.get("mode", MODE_QUICK_PLAY))
	buy_in = int(context.get("buy_in", buy_in))
	starting_chips = int(context.get("starting_chips", buy_in))
	current_table_chips = int(context.get("current_table_chips", starting_chips))
	small_blind = int(context.get("small_blind", small_blind))
	big_blind = int(context.get("big_blind", big_blind))
	max_hands = int(context.get("max_hands", 10))
	session_start_chips = int(context.get("session_start_chips", starting_chips))
	session_end_chips = int(context.get("session_end_chips", current_table_chips))
	session_profit = int(context.get("session_profit", session_end_chips - session_start_chips))
	hands_played = int(context.get("hands_played", 0))
	hands_won = int(context.get("hands_won", 0))
	biggest_pot = int(context.get("biggest_pot", 0))
	best_hand_desc = String(context.get("best_hand_desc", "-"))
	is_session_over = bool(context.get("is_session_over", false))
	current_hand_index = int(context.get("current_hand_index", hands_played))
	end_reason = String(context.get("end_reason", ""))
	last_winner = String(context.get("last_winner", "-"))
	last_win_amount = int(context.get("last_win_amount", 0))

func can_start_next_hand() -> bool:
	if is_session_over:
		return false
	if current_table_chips <= 0:
		return false
	if max_hands > 0 and current_hand_index >= max_hands:
		return false
	return true

func begin_next_hand() -> int:
	if not can_start_next_hand():
		is_session_over = true
		return current_hand_index
	current_hand_index += 1
	return current_hand_index

func record_hand_result(settlement: Dictionary, local_seat_id: int, local_chips: int) -> void:
	var pot_before: int = int(settlement.get("pot_before_settlement", 0))
	var desc: String = String(settlement.get("hand_description", settlement.get("hand_rank", "-")))
	hands_played += 1
	current_table_chips = local_chips
	session_end_chips = local_chips
	session_profit = session_end_chips - session_start_chips
	if Array(settlement.get("winner_seats", [])).has(local_seat_id):
		hands_won += 1
	var winner_names: Array = Array(settlement.get("winner_names", []))
	last_winner = String(winner_names[0]) if not winner_names.is_empty() else "-"
	last_win_amount = int(settlement.get("win_amount", 0))
	if pot_before > biggest_pot:
		biggest_pot = pot_before
	if desc != "":
		best_hand_desc = desc
	if current_table_chips <= 0:
		is_session_over = true
		end_reason = "Out of chips"
	if max_hands > 0 and hands_played >= max_hands:
		is_session_over = true
		if end_reason == "":
			end_reason = "Hands completed"

func hand_count_text() -> String:
	if max_hands <= 0 or max_hands >= 999:
		return "%d / unlimited" % max(current_hand_index, hands_played)
	return "%d / %d" % [max(current_hand_index, hands_played), max_hands]

func to_dict() -> Dictionary:
	return {
		"mode": mode,
		"buy_in": buy_in,
		"starting_chips": starting_chips,
		"current_table_chips": current_table_chips,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"max_hands": max_hands,
		"current_hand_index": current_hand_index,
		"session_start_chips": session_start_chips,
		"session_end_chips": session_end_chips,
		"session_profit": session_profit,
		"hands_played": hands_played,
		"hands_won": hands_won,
		"biggest_pot": biggest_pot,
		"best_hand_desc": best_hand_desc,
		"is_session_over": is_session_over,
		"end_reason": end_reason,
		"last_winner": last_winner,
		"last_win_amount": last_win_amount,
	}

static func from_context(context: Dictionary) -> TableSession:
	var session := TableSession.new()
	session.configure_from_context(Dictionary(context.get("table_session", context)))
	return session
