extends RefCounted
class_name TableLaunchContext

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

static var launch_mode := "quick_play"
static var mode := "quick_play"
static var backend_type := "local_mock"
static var table_id := "mock_table_001"
static var room_id := ""
static var is_training := false
static var table_type := "quick_play"
static var uses_practice_chips := false
static var affects_account_balance := true
static var buy_in_deducted_from_wallet := false
static var waiting_for_real_players := false
static var is_ai_warmup := false
static var pending_real_joiners: Array[Dictionary] = []
static var warmup_ai_player_ids: Array[String] = []
static var allow_debug_tools := false
static var ai_player_count := 0
static var max_hands := 10
static var buy_in := PlayerProfileScript.DEFAULT_TABLE_BUY_IN
static var small_blind := 25
static var big_blind := 50
static var seats: Array[Dictionary] = []
static var table_session: Dictionary = {}
static var player_profile: Dictionary = PlayerProfileScript.default_profile()

static func configure(mode: String = "quick_play", id: String = "mock_table_001", profile: Dictionary = {}, setup_config: Dictionary = {}) -> void:
	launch_mode = mode
	TableLaunchContext.mode = mode
	table_id = id
	is_training = mode == "training"
	table_type = "training_ai" if is_training else mode
	uses_practice_chips = is_training
	affects_account_balance = not is_training
	buy_in_deducted_from_wallet = bool(setup_config.get("buy_in_deducted_from_wallet", false))
	waiting_for_real_players = false
	is_ai_warmup = false
	pending_real_joiners.clear()
	warmup_ai_player_ids.clear()
	if not profile.is_empty():
		set_player_profile(profile)
	buy_in = PlayerProfileScript.table_buy_in(player_profile)
	if setup_config.has("buy_in"):
		buy_in = int(setup_config.get("buy_in", buy_in))
	backend_type = "local_mock"
	room_id = ""
	allow_debug_tools = is_training
	ai_player_count = 7 if mode in ["quick_play", "training"] else 0
	max_hands = 999 if is_training else int(setup_config.get("max_hands", 10))
	small_blind = int(setup_config.get("small_blind", 25))
	big_blind = int(setup_config.get("big_blind", 50))
	seats.clear()
	table_session = _default_table_session()

static func reset() -> void:
	configure("quick_play", "mock_table_001", PlayerProfileScript.default_profile())

static func clear_table_session() -> void:
	table_session = {}
	seats.clear()
	room_id = ""

static func set_player_profile(profile: Dictionary) -> void:
	player_profile = PlayerProfileScript.normalized_dict(profile)

static func get_player_profile() -> Dictionary:
	if player_profile.is_empty():
		player_profile = PlayerProfileScript.default_profile()
	return player_profile.duplicate(true)

static func configure_from_context(context: Dictionary) -> void:
	if context.is_empty():
		configure()
		return
	mode = String(context.get("mode", "quick_play"))
	launch_mode = mode
	backend_type = String(context.get("backend_type", "local_mock"))
	table_id = String(context.get("table_id", "mock_table_001"))
	room_id = String(context.get("room_id", ""))
	is_training = bool(context.get("is_training", mode == "training"))
	table_type = String(context.get("table_type", "training_ai" if is_training else mode))
	uses_practice_chips = bool(context.get("uses_practice_chips", is_training))
	affects_account_balance = bool(context.get("affects_account_balance", not is_training))
	buy_in_deducted_from_wallet = bool(context.get("buy_in_deducted_from_wallet", false))
	waiting_for_real_players = bool(context.get("waiting_for_real_players", false))
	is_ai_warmup = bool(context.get("is_ai_warmup", false))
	pending_real_joiners = []
	for joiner in Array(context.get("pending_real_joiners", [])):
		pending_real_joiners.append(Dictionary(joiner).duplicate(true))
	warmup_ai_player_ids = []
	for ai_id in Array(context.get("warmup_ai_player_ids", [])):
		warmup_ai_player_ids.append(String(ai_id))
	allow_debug_tools = bool(context.get("allow_debug_tools", is_training))
	ai_player_count = int(context.get("ai_player_count", 0))
	max_hands = int(context.get("max_hands", 10))
	buy_in = int(context.get("buy_in", PlayerProfileScript.DEFAULT_TABLE_BUY_IN))
	small_blind = int(context.get("small_blind", 25))
	big_blind = int(context.get("big_blind", 50))
	seats = []
	for seat in Array(context.get("seats", [])):
		seats.append(Dictionary(seat).duplicate(true))
	set_player_profile(Dictionary(context.get("local_player_profile", PlayerProfileScript.default_profile())))
	table_session = Dictionary(context.get("table_session", _default_table_session())).duplicate(true)

static func get_current_table_context() -> Dictionary:
	return {
		"mode": mode,
		"backend_type": backend_type,
		"local_player_profile": get_player_profile(),
		"table_id": table_id,
		"room_id": room_id,
		"seats": seats.duplicate(true),
		"buy_in": buy_in,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"is_training": is_training,
		"table_type": table_type,
		"uses_practice_chips": uses_practice_chips,
		"affects_account_balance": affects_account_balance,
		"buy_in_deducted_from_wallet": buy_in_deducted_from_wallet,
		"waiting_for_real_players": waiting_for_real_players,
		"is_ai_warmup": is_ai_warmup,
		"pending_real_joiners": pending_real_joiners.duplicate(true),
		"warmup_ai_player_ids": warmup_ai_player_ids.duplicate(),
		"allow_debug_tools": allow_debug_tools,
		"ai_player_count": ai_player_count,
		"max_hands": max_hands,
		"table_session": table_session.duplicate(true),
	}

static func has_seat_context() -> bool:
	return not seats.is_empty()

static func _default_table_session() -> Dictionary:
	var session_buy_in: int = buy_in
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
		"buy_in": session_buy_in,
		"starting_chips": session_buy_in,
		"current_table_chips": session_buy_in,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"max_hands": max_hands,
		"current_hand_index": 0,
		"session_start_chips": session_buy_in,
		"session_end_chips": session_buy_in,
		"session_profit": 0,
		"hands_played": 0,
		"hands_won": 0,
		"biggest_pot": 0,
		"best_hand_desc": "-",
		"is_session_over": false,
		"selected_dealer_id": "dealer_01_dog",
	}
