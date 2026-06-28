extends BackendService
class_name LocalMockBackend

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")
const TableSeatScript := preload("res://scripts/data/table_seat.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

var _current_context: Dictionary = {}

func create_quick_play_table(profile: Dictionary, setup_config: Dictionary = {}) -> Dictionary:
	_current_context = quick_join_public_table(profile, setup_config)
	return _current_context.duplicate(true)

func create_training_table(profile: Dictionary) -> Dictionary:
	_current_context = _build_table_context("training", "mock_training_table_001", "", profile, true, true, 7, {})
	return _current_context.duplicate(true)

func list_public_tables() -> Array[Dictionary]:
	PublicTableRegistryScript.seed_mock_public_tables()
	return PublicTableRegistryScript.list_public_tables()

func create_public_table(config: Dictionary = {}) -> Dictionary:
	var table := PublicTableRegistryScript.create_public_table(config)
	return table

func join_public_table(table_id: String, player: Dictionary) -> Dictionary:
	var table := PublicTableRegistryScript.join_public_table(table_id, player)
	if table.is_empty():
		return {}
	_current_context = _build_public_table_context(table, player)
	return _current_context.duplicate(true)

func leave_public_table(table_id: String, player_id: String) -> void:
	PublicTableRegistryScript.leave_public_table(table_id, player_id)

func quick_join_public_table(player: Dictionary, preferred_config: Dictionary = {}) -> Dictionary:
	var table := PublicTableRegistryScript.quick_join_public_table(player, _public_table_config_from_setup(preferred_config, player))
	if table.is_empty():
		return {}
	_current_context = _build_public_table_context(table, player)
	return _current_context.duplicate(true)

func create_friends_room(profile: Dictionary) -> Dictionary:
	var room_id := "FR-%04d" % (1000 + (Time.get_ticks_msec() % 9000))
	_current_context = _build_table_context("friends_room", "mock_friends_table_%s" % room_id, room_id, profile, false, true, 3, {})
	_current_context["table_type"] = "private_room"
	_current_context["room_state"] = "waiting"
	_current_context["ready_seats"] = [5]
	return _current_context.duplicate(true)

func join_room(room_id: String, profile: Dictionary) -> Dictionary:
	_current_context = _build_table_context("friends_room", "mock_friends_table_%s" % room_id, room_id, profile, false, true, 3, {})
	_current_context["table_type"] = "private_room"
	return _current_context.duplicate(true)

func leave_room() -> void:
	_current_context = {}

func get_current_table_context() -> Dictionary:
	return _current_context.duplicate(true)

func _build_table_context(mode: String, table_id: String, room_id: String, profile: Dictionary, training: bool, debug_tools: bool, ai_count: int, setup_config: Dictionary = {}) -> Dictionary:
	var normalized_profile: Dictionary = PlayerProfileScript.normalized_dict(profile)
	var buy_in: int = PlayerProfileScript.table_buy_in(normalized_profile)
	if training:
		buy_in = PlayerProfileScript.DEFAULT_TABLE_BUY_IN
	else:
		buy_in = int(setup_config.get("buy_in", buy_in))
	var small_blind: int = int(setup_config.get("small_blind", 25))
	var big_blind: int = int(setup_config.get("big_blind", 50))
	var max_hands: int = 999 if training else int(setup_config.get("max_hands", 10))
	var buy_in_deducted: bool = bool(setup_config.get("buy_in_deducted_from_wallet", false))
	return {
		"mode": mode,
		"backend_type": "local_mock",
		"local_player_profile": normalized_profile,
		"table_id": table_id,
		"room_id": room_id,
		"seats": _build_mock_seats(normalized_profile, buy_in, ai_count),
		"buy_in": buy_in,
		"small_blind": small_blind,
		"big_blind": big_blind,
		"is_training": training,
		"table_type": "training_ai" if training else mode,
		"uses_practice_chips": training,
		"affects_account_balance": not training,
		"buy_in_deducted_from_wallet": buy_in_deducted,
		"allow_debug_tools": debug_tools,
		"ai_player_count": ai_count,
		"max_hands": max_hands,
		"table_session": {
			"mode": mode,
			"table_type": "training_ai" if training else mode,
			"uses_practice_chips": training,
			"affects_account_balance": not training,
			"buy_in_deducted_from_wallet": buy_in_deducted,
			"buy_in": buy_in,
			"starting_chips": buy_in,
			"current_table_chips": buy_in,
			"small_blind": small_blind,
			"big_blind": big_blind,
			"max_hands": max_hands,
			"current_hand_index": 0,
			"session_start_chips": buy_in,
			"session_end_chips": buy_in,
			"session_profit": 0,
			"hands_played": 0,
			"hands_won": 0,
			"biggest_pot": 0,
			"best_hand_desc": "-",
			"is_session_over": false,
		},
	}

func _build_public_table_context(table: Dictionary, profile: Dictionary) -> Dictionary:
	var setup_config := {
		"buy_in": int(table.get("buy_in", PlayerProfileScript.DEFAULT_TABLE_BUY_IN)),
		"small_blind": int(table.get("small_blind", 25)),
		"big_blind": int(table.get("big_blind", 50)),
		"max_hands": int(table.get("hand_count", 10)),
	}
	var context := _build_table_context("quick_play", String(table.get("table_id", "mock_public_table")), "", profile, false, false, 7, setup_config)
	context["table_name"] = String(table.get("table_name", "Public Chip Table"))
	context["table_type"] = PublicTableRegistryScript.TABLE_TYPE_PUBLIC_CHIP
	context["public_table"] = table.duplicate(true)
	context["allow_quick_join"] = bool(table.get("allow_quick_join", true))
	context["table_session"]["table_type"] = PublicTableRegistryScript.TABLE_TYPE_PUBLIC_CHIP
	return context

func _public_table_config_from_setup(setup_config: Dictionary, player: Dictionary) -> Dictionary:
	var buy_in: int = int(setup_config.get("buy_in", PlayerProfileScript.DEFAULT_TABLE_BUY_IN))
	var small_blind: int = int(setup_config.get("small_blind", 25))
	var big_blind: int = int(setup_config.get("big_blind", 50))
	var hand_count: int = int(setup_config.get("max_hands", setup_config.get("hand_count", 10)))
	return {
		"table_name": "Public Chip %d/%d" % [small_blind, big_blind],
		"small_blind": small_blind,
		"big_blind": big_blind,
		"buy_in": buy_in,
		"hand_count": hand_count,
		"max_players": int(setup_config.get("max_players", 9)),
		"created_by": String(player.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID)),
		"allow_quick_join": true,
	}

func _build_mock_seats(profile: Dictionary, buy_in: int, ai_count: int) -> Array[Dictionary]:
	var seats: Array[Dictionary] = []
	var occupied_ai := 0
	for seat_id in range(1, 10):
		var is_local := seat_id == 5
		var has_player := is_local
		if not is_local and seat_id != 8 and occupied_ai < ai_count:
			has_player = true
			occupied_ai += 1
		var avatar_id := PlayerProfileScript.get_avatar_id(profile) if is_local else AvatarLibraryScript.avatar_id_for_seat(seat_id, false)
		seats.append({
			"seat_id": seat_id,
			"seat_index": seat_id,
			"player_id": String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID)) if is_local else ("ai_player_%03d" % seat_id),
			"player_name": PlayerProfileScript.get_player_name(profile) if is_local else ("AI Seat %d" % seat_id),
			"avatar_id": avatar_id if has_player else "",
			"chips": buy_in if is_local else 12000 + seat_id * 850,
			"current_bet": 0,
			"hole_cards": [],
			"status": TableSeatScript.SITTING if has_player else TableSeatScript.EMPTY,
			"occupied": has_player,
			"last_action": "",
			"last_action_amount": 0,
			"last_action_seq": 0,
			"is_dealer": false,
			"is_small_blind": false,
			"is_big_blind": false,
			"is_local": is_local,
		})
	return seats
