extends RefCounted
class_name TableSession

const DealerLibraryScript := preload("res://scripts/data/dealer_library.gd")

const MODE_QUICK_PLAY := "quick_play"
const MODE_TRAINING := "training"
const MODE_FRIENDS_ROOM := "friends_room"
const TABLE_TYPE_PUBLIC_CHIP := "public_chip"
const TABLE_TYPE_PRIVATE_ROOM := "private_room"
const TABLE_TYPE_TRAINING_AI := "training_ai"
const SEAT_ACTIVE := "active"
const SEAT_FOLDED := "folded"
const SEAT_LEFT := "left"
const SEAT_DISCONNECTED := "disconnected"
const SEAT_SIT_OUT := "sit_out"
const TABLE_WAITING := "waiting"
const TABLE_WAITING_FOR_PLAYERS := "waiting_for_players"
const TABLE_READY_TO_START := "ready_to_start"
const TABLE_AI_WARMUP := "ai_warmup"
const TABLE_PLAYING := "playing"
const TABLE_PAUSED := "paused"
const TABLE_CLOSED := "closed"
const HOST_LEFT_MOCK_MESSAGE := "Host left. Table closed safely. Account balances were not changed."
const DEFAULT_DEALER_ID := "dealer_01_dog"
const DEFAULT_ACTION_TIME_SECONDS := 60

var mode := MODE_QUICK_PLAY
var table_type := MODE_QUICK_PLAY
var uses_practice_chips := false
var affects_account_balance := true
var buy_in_deducted_from_wallet := false
var waiting_for_real_players := false
var is_ai_warmup := false
var pending_real_joiners: Array[Dictionary] = []
var warmup_ai_player_ids: Array[String] = []
var buy_in := 20000
var starting_chips := 20000
var current_table_chips := 20000
var small_blind := 25
var big_blind := 50
var max_hands := 10
var action_time_seconds := DEFAULT_ACTION_TIME_SECONDS
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
var min_active_players := 2
var status := TABLE_PLAYING
var pending_cash_out := 0
var pending_refund := 0
var last_auto_action := ""
var host_left_message := ""
var selected_dealer_id := DEFAULT_DEALER_ID

func configure_from_context(context: Dictionary) -> void:
	mode = String(context.get("mode", MODE_QUICK_PLAY))
	table_type = String(context.get("table_type", "training_ai" if mode == MODE_TRAINING else mode))
	uses_practice_chips = bool(context.get("uses_practice_chips", mode == MODE_TRAINING))
	affects_account_balance = bool(context.get("affects_account_balance", mode != MODE_TRAINING))
	buy_in_deducted_from_wallet = bool(context.get("buy_in_deducted_from_wallet", false))
	waiting_for_real_players = bool(context.get("waiting_for_real_players", false))
	is_ai_warmup = bool(context.get("is_ai_warmup", false))
	pending_real_joiners = []
	for joiner in Array(context.get("pending_real_joiners", [])):
		pending_real_joiners.append(Dictionary(joiner).duplicate(true))
	warmup_ai_player_ids = []
	for ai_id in Array(context.get("warmup_ai_player_ids", [])):
		warmup_ai_player_ids.append(String(ai_id))
	buy_in = int(context.get("buy_in", buy_in))
	starting_chips = int(context.get("starting_chips", buy_in))
	current_table_chips = int(context.get("current_table_chips", starting_chips))
	small_blind = int(context.get("small_blind", small_blind))
	big_blind = int(context.get("big_blind", big_blind))
	max_hands = int(context.get("max_hands", 10))
	action_time_seconds = DEFAULT_ACTION_TIME_SECONDS
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
	min_active_players = int(context.get("min_active_players", min_active_players))
	status = String(context.get("status", status))
	pending_cash_out = int(context.get("pending_cash_out", 0))
	pending_refund = int(context.get("pending_refund", 0))
	last_auto_action = String(context.get("last_auto_action", ""))
	host_left_message = String(context.get("host_left_message", ""))
	selected_dealer_id = _normalized_dealer_id(String(context.get("selected_dealer_id", DEFAULT_DEALER_ID)))

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

func apply_player_leave_during_hand(seat: Dictionary, disconnect: bool = false) -> Dictionary:
	var result := seat.duplicate(true)
	var committed: int = int(result.get("committed_this_hand", result.get("current_bet", 0)))
	var table_stack: int = int(result.get("table_stack", result.get("chips", 0)))
	var cash_out: int = max(table_stack, 0)
	result["committed_this_hand"] = max(committed, 0)
	result["folded"] = true
	result["in_hand"] = false
	result["next_hand_eligible"] = false
	result["status"] = SEAT_DISCONNECTED if disconnect else SEAT_LEFT
	result["left"] = not disconnect
	result["disconnected"] = disconnect
	result["pending_cash_out"] = 0
	result["pending_refund"] = 0
	if uses_practice_chips or mode == MODE_TRAINING or table_type == TABLE_TYPE_TRAINING_AI:
		result["practice_stack_discarded"] = cash_out
	elif table_type == TABLE_TYPE_PRIVATE_ROOM or mode == MODE_FRIENDS_ROOM:
		result["pending_refund"] = cash_out
		pending_refund += cash_out
	else:
		result["pending_cash_out"] = cash_out
		pending_cash_out += cash_out
	return result

func apply_timeout(seat: Dictionary, check_available: bool) -> Dictionary:
	var result := seat.duplicate(true)
	var timeout_count: int = int(result.get("timeout_count", 0)) + 1
	result["timeout_count"] = timeout_count
	if check_available:
		result["auto_action"] = "check"
		result["last_action"] = "Auto-check"
		result["folded"] = bool(result.get("folded", false))
	else:
		result["auto_action"] = "fold"
		result["last_action"] = "Auto-fold"
		result["folded"] = true
		result["in_hand"] = false
		result["status"] = SEAT_FOLDED
	last_auto_action = String(result.get("last_action", ""))
	if timeout_count >= 2:
		result = mark_sit_out(result)
	return result

func mark_sit_out(seat: Dictionary) -> Dictionary:
	var result := seat.duplicate(true)
	result["status"] = SEAT_SIT_OUT
	result["sit_out"] = true
	result["in_hand"] = false
	result["next_hand_eligible"] = false
	result["post_blinds"] = false
	result["deal_in_next_hand"] = false
	return result

func should_deal_next_hand(seat: Dictionary) -> bool:
	if not bool(seat.get("occupied", true)):
		return false
	if bool(seat.get("sit_out", false)):
		return false
	if bool(seat.has("next_hand_eligible")) and not bool(seat.get("next_hand_eligible", true)):
		return false
	var seat_status := String(seat.get("status", SEAT_ACTIVE))
	if [SEAT_LEFT, SEAT_DISCONNECTED, SEAT_SIT_OUT, "empty", "out"].has(seat_status):
		return false
	return int(seat.get("chips", seat.get("table_stack", 0))) > 0

func active_player_count(seats: Array) -> int:
	var count := 0
	for seat in seats:
		if should_deal_next_hand(Dictionary(seat)):
			count += 1
	return count

func refresh_table_status_for_active_players(seats: Array) -> String:
	if status == TABLE_CLOSED:
		return status
	status = TABLE_PLAYING if active_player_count(seats) >= min_active_players else TABLE_PAUSED
	return status

func apply_host_leave_mock() -> Dictionary:
	status = TABLE_CLOSED
	is_session_over = true
	end_reason = HOST_LEFT_MOCK_MESSAGE
	host_left_message = HOST_LEFT_MOCK_MESSAGE
	return {
		"status": status,
		"message": HOST_LEFT_MOCK_MESSAGE,
		"affects_account_balance": false,
	}

func can_change_dealer_cosmetic(seats: Array) -> bool:
	if mode == MODE_TRAINING or table_type == TABLE_TYPE_TRAINING_AI:
		return true
	return human_player_count(seats) <= 1

func select_dealer_cosmetic(dealer_id: String, seats: Array) -> bool:
	if not can_change_dealer_cosmetic(seats):
		return false
	selected_dealer_id = _normalized_dealer_id(dealer_id)
	return true

func human_player_count(seats: Array) -> int:
	var count := 0
	for seat_item in seats:
		var seat := Dictionary(seat_item)
		if not bool(seat.get("occupied", false)):
			continue
		var status_text := String(seat.get("status", ""))
		if status_text in ["", "empty", "left", "out"]:
			continue
		if _is_ai_seat(seat):
			continue
		count += 1
	return count

func _is_ai_seat(seat: Dictionary) -> bool:
	if bool(seat.get("is_ai", false)) or bool(seat.get("is_bot", false)):
		return true
	var player_id := String(seat.get("player_id", "")).to_lower()
	var player_name := String(seat.get("player_name", seat.get("name", ""))).to_lower()
	return player_id.begins_with("ai_") or player_id.begins_with("bot_") or player_name.begins_with("ai ")

func _normalized_dealer_id(dealer_id: String) -> String:
	return DealerLibraryScript.normalize_dealer_id(dealer_id)

func hand_count_text() -> String:
	if max_hands <= 0 or max_hands >= 999:
		return "%d / Unlimited" % max(current_hand_index, hands_played)
	return "%d / %d" % [max(current_hand_index, hands_played), max_hands]

func to_dict() -> Dictionary:
	return {
		"mode": mode,
		"table_type": table_type,
		"uses_practice_chips": uses_practice_chips,
		"affects_account_balance": affects_account_balance,
		"buy_in_deducted_from_wallet": buy_in_deducted_from_wallet,
		"waiting_for_real_players": waiting_for_real_players,
		"is_ai_warmup": is_ai_warmup,
		"pending_real_joiners": pending_real_joiners.duplicate(true),
		"warmup_ai_player_ids": warmup_ai_player_ids.duplicate(),
		"buy_in": buy_in,
		"starting_chips": starting_chips,
		"current_table_chips": current_table_chips,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"max_hands": max_hands,
		"action_time_seconds": action_time_seconds,
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
		"min_active_players": min_active_players,
		"status": status,
		"pending_cash_out": pending_cash_out,
		"pending_refund": pending_refund,
		"last_auto_action": last_auto_action,
		"host_left_message": host_left_message,
		"selected_dealer_id": selected_dealer_id,
	}

static func from_context(context: Dictionary) -> TableSession:
	var session := TableSession.new()
	session.configure_from_context(Dictionary(context.get("table_session", context)))
	return session
