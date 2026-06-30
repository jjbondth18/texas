extends RefCounted
class_name PublicTableRegistry

const TABLE_TYPE_PUBLIC_CHIP := "public_chip"
const STATUS_WAITING := "waiting"
const STATUS_WAITING_FOR_PLAYERS := "waiting_for_players"
const STATUS_AI_WARMUP := "ai_warmup"
const STATUS_OPEN := "open"
const STATUS_PLAYING := "playing"
const STATUS_FULL := "full"
const STATUS_CLOSED := "closed"
const STATUS_DIRTY := "dirty"
const STATUS_PAUSED := "paused"
const STATUS_HAND_OVER := "hand_over"
const STATUS_SHOWDOWN_REVEAL := "showdown_reveal"

static var _tables: Dictionary = {}
static var _next_table_number := 1

static func reset() -> void:
	_tables.clear()
	_next_table_number = 1

static func list_public_tables() -> Array[Dictionary]:
	var public_tables: Array[Dictionary] = []
	var stale_table_ids: Array[String] = []
	for table_id in _tables.keys():
		var table: Dictionary = _normalized_public_table(Dictionary(_tables[table_id]))
		if not _is_public_chip_table(table):
			continue
		if not _is_clean_joinable_public_table(table, false):
			if _should_close_dirty_table(table):
				stale_table_ids.append(String(table.get("table_id", table_id)))
			continue
		_tables[table_id] = table
		public_tables.append(_public_table_snapshot(table))
	for stale_id in stale_table_ids:
		_tables.erase(stale_id)
	return public_tables

static func create_public_table(config: Dictionary = {}) -> Dictionary:
	var normalized_config: Dictionary = _normalized_public_table_config(config)
	var table_id: String = String(config.get("table_id", "pub_chip_%03d" % _next_table_number))
	if not config.has("table_id"):
		_next_table_number += 1
	var small_blind: int = int(normalized_config.get("small_blind", 25))
	var big_blind: int = int(normalized_config.get("big_blind", 50))
	var buy_in: int = int(normalized_config.get("buy_in", 20000))
	var max_players: int = int(normalized_config.get("max_players", 9))
	var player_ids: Array[String] = []
	for player_id in Array(normalized_config.get("player_ids", [])):
		player_ids.append(String(player_id))
	var real_player_ids: Array[String] = []
	for player_id in Array(normalized_config.get("real_player_ids", player_ids)):
		real_player_ids.append(String(player_id))
	var table := {
		"table_id": table_id,
		"table_name": String(normalized_config.get("table_name", "Public Chip %03d" % max(_next_table_number - 1, 1))),
		"table_type": TABLE_TYPE_PUBLIC_CHIP,
		"currency": "chip",
		"status": STATUS_WAITING_FOR_PLAYERS,
		"hand_state": STATUS_WAITING_FOR_PLAYERS,
		"betting_round": "waiting",
		"small_blind": small_blind,
		"big_blind": big_blind,
		"blinds": {
			"small": small_blind,
			"big": big_blind,
		},
		"buy_in": buy_in,
		"buy_in_min": buy_in,
		"buy_in_max": buy_in,
		"hand_count": int(normalized_config.get("hand_count", normalized_config.get("max_hands", 10))),
		"max_players": max_players,
		"current_players": min(max(real_player_ids.size(), int(normalized_config.get("current_players", player_ids.size()))), max_players),
		"created_by": String(normalized_config.get("created_by", "local_mock")),
		"allow_quick_join": bool(normalized_config.get("allow_quick_join", true)),
		"allow_mid_hand_join": false,
		"pot": 0,
		"side_pots": [],
		"community_cards": [],
		"current_turn_seat": -1,
		"table_log": [],
		"players": [],
		"seats": [],
		"hand_number": 0,
		"player_ids": player_ids,
		"real_player_ids": real_player_ids,
		"pending_real_joiners": [],
		"warmup_ai_player_ids": [],
		"is_ai_warmup": false,
		"host_in_local_warmup": false,
		"waiting_for_real_players": true,
	}
	_update_public_table_status(table)
	_tables[table_id] = table
	return _public_table_snapshot(table)

static func add_mock_table(table: Dictionary) -> void:
	var normalized: Dictionary = _normalized_public_table(table)
	_tables[String(normalized.get("table_id", ""))] = normalized

static func join_public_table(table_id: String, player: Dictionary) -> Dictionary:
	if not _tables.has(table_id):
		return {}
	var table: Dictionary = _normalized_public_table(Dictionary(_tables[table_id]))
	if not _is_clean_joinable_public_table(table, false):
		if _should_close_dirty_table(table):
			_tables.erase(table_id)
		else:
			_tables[table_id] = table
		return {}
	var player_id: String = _player_id(player)
	var player_ids: Array = Array(table.get("player_ids", [])).duplicate()
	if not player_ids.has(player_id):
		player_ids.append(player_id)
		table["player_ids"] = player_ids
	var real_player_ids: Array = Array(table.get("real_player_ids", player_ids)).duplicate()
	if not real_player_ids.has(player_id):
		real_player_ids.append(player_id)
	table["real_player_ids"] = real_player_ids
	table["current_players"] = min(real_player_ids.size(), int(table.get("max_players", 9)))
	if bool(table.get("host_in_local_warmup", false)) and real_player_ids.size() >= 2:
		table["host_in_local_warmup"] = false
	_update_public_table_status(table)
	_tables[table_id] = table
	return _public_table_snapshot(table)

static func start_ai_warmup(table_id: String, ai_count: int = 3) -> Dictionary:
	if not _tables.has(table_id):
		return {}
	var table: Dictionary = _normalized_public_table(Dictionary(_tables[table_id]))
	if not _is_public_chip_table(table):
		return {}
	table["is_ai_warmup"] = false
	table["host_in_local_warmup"] = true
	table["waiting_for_real_players"] = true
	table["warmup_ai_player_ids"] = []
	table["status"] = STATUS_WAITING_FOR_PLAYERS
	table["hand_state"] = STATUS_WAITING_FOR_PLAYERS
	var log: Array = Array(table.get("table_log", [])).duplicate()
	log.append("Host started local AI warm-up. Public room remains open for real players.")
	table["table_log"] = log
	_tables[table_id] = table
	return _public_table_snapshot(table)

static func settle_pending_real_joiners(table_id: String) -> Dictionary:
	if not _tables.has(table_id):
		return {}
	var table: Dictionary = _normalized_public_table(Dictionary(_tables[table_id]))
	var player_ids: Array = Array(table.get("player_ids", [])).duplicate()
	var real_player_ids: Array = Array(table.get("real_player_ids", player_ids)).duplicate()
	for joiner_item in Array(table.get("pending_real_joiners", [])):
		var joiner_id: String = _player_id(Dictionary(joiner_item))
		if joiner_id == "":
			continue
		if not player_ids.has(joiner_id):
			player_ids.append(joiner_id)
		if not real_player_ids.has(joiner_id):
			real_player_ids.append(joiner_id)
	table["player_ids"] = player_ids
	table["real_player_ids"] = real_player_ids
	table["pending_real_joiners"] = []
	table["warmup_ai_player_ids"] = []
	table["is_ai_warmup"] = false
	table["host_in_local_warmup"] = false
	table["waiting_for_real_players"] = real_player_ids.size() < 2
	table["current_players"] = min(real_player_ids.size(), int(table.get("max_players", 9)))
	table["status"] = STATUS_OPEN if real_player_ids.size() >= 2 else STATUS_WAITING_FOR_PLAYERS
	table["hand_state"] = table["status"]
	_tables[table_id] = table
	return _public_table_snapshot(table)

static func leave_public_table(table_id: String, player_id: String) -> void:
	if not _tables.has(table_id):
		return
	var table: Dictionary = Dictionary(_tables[table_id]).duplicate(true)
	if String(table.get("table_type", "")) != TABLE_TYPE_PUBLIC_CHIP:
		return
	var player_ids: Array = Array(table.get("player_ids", [])).duplicate()
	player_ids.erase(player_id)
	table["player_ids"] = player_ids
	var real_player_ids: Array = Array(table.get("real_player_ids", player_ids)).duplicate()
	real_player_ids.erase(player_id)
	table["real_player_ids"] = real_player_ids
	table["current_players"] = min(real_player_ids.size(), int(table.get("max_players", 9)))
	_update_public_table_status(table)
	_tables[table_id] = table

static func quick_join_public_table(player: Dictionary, preferred_config: Dictionary = {}) -> Dictionary:
	var has_preference: bool = _has_quick_join_preference(preferred_config)
	var clean_config: Dictionary = _normalized_public_table_config(preferred_config)
	var table_id: String = _best_quick_join_table_id(true, clean_config if has_preference else {})
	var created_new_table := false
	if table_id == "":
		table_id = _best_quick_join_table_id(false, clean_config if has_preference else {})
	if table_id == "" and not has_preference:
		table_id = _best_quick_join_table_id(true)
	if table_id == "" and not has_preference:
		table_id = _best_quick_join_table_id(false)
	if table_id == "":
		var created: Dictionary = create_public_table(clean_config)
		table_id = String(created.get("table_id", ""))
		created_new_table = true
	var joined: Dictionary = join_public_table(table_id, player)
	if created_new_table and not joined.is_empty():
		return start_ai_warmup(table_id)
	return joined

static func seed_mock_public_tables() -> void:
	if not list_public_tables().is_empty():
		return
	create_public_table({
		"table_id": "pub_chip_neon_001",
		"table_name": "Neon Public 25/50",
		"small_blind": 25,
		"big_blind": 50,
		"buy_in": 5000,
		"hand_count": 10,
		"current_players": 3,
		"created_by": "mock_registry",
	})
	create_public_table({
		"table_id": "pub_chip_synth_002",
		"table_name": "Synth Public 50/100",
		"small_blind": 50,
		"big_blind": 100,
		"buy_in": 10000,
		"hand_count": 20,
		"current_players": 5,
		"created_by": "mock_registry",
	})

static func _best_quick_join_table_id(waiting_only: bool, preferred_config: Dictionary = {}) -> String:
	var best_id := ""
	var best_players := -1
	for table_id in _tables.keys():
		var table: Dictionary = _normalized_public_table(Dictionary(_tables[table_id]))
		if not _is_clean_joinable_public_table(table, true):
			continue
		if waiting_only and String(table.get("status", "")) not in [STATUS_WAITING, STATUS_OPEN]:
			continue
		if not _table_matches_preferred_config(table, preferred_config):
			continue
		var current_players: int = int(table.get("current_players", 0))
		if current_players > best_players:
			best_players = current_players
			best_id = String(table.get("table_id", table_id))
	return best_id

static func _has_quick_join_preference(preferred_config: Dictionary) -> bool:
	return preferred_config.has("buy_in") or preferred_config.has("small_blind") or preferred_config.has("big_blind") or preferred_config.has("hand_count") or preferred_config.has("max_hands")

static func _normalized_public_table_config(config: Dictionary) -> Dictionary:
	var result: Dictionary = config.duplicate(true)
	var blinds_value = result.get("blinds", {})
	if blinds_value is Dictionary:
		var blinds_dict: Dictionary = Dictionary(blinds_value)
		if not result.has("small_blind") and blinds_dict.has("small"):
			result["small_blind"] = int(blinds_dict.get("small", 25))
		if not result.has("big_blind") and blinds_dict.has("big"):
			result["big_blind"] = int(blinds_dict.get("big", 50))
	elif blinds_value is String:
		var pieces: PackedStringArray = String(blinds_value).replace(" ", "").split("/")
		if pieces.size() >= 2:
			if not result.has("small_blind") and String(pieces[0]).is_valid_int():
				result["small_blind"] = int(String(pieces[0]))
			if not result.has("big_blind") and String(pieces[1]).is_valid_int():
				result["big_blind"] = int(String(pieces[1]))
	result["table_type"] = TABLE_TYPE_PUBLIC_CHIP
	result["currency"] = "chip"
	result["buy_in"] = int(result.get("buy_in", 20000))
	result["small_blind"] = int(result.get("small_blind", 25))
	result["big_blind"] = int(result.get("big_blind", 50))
	result["hand_count"] = int(result.get("hand_count", result.get("max_hands", 10)))
	result["max_players"] = int(result.get("max_players", 9))
	result["allow_quick_join"] = bool(result.get("allow_quick_join", true))
	return result

static func _normalized_public_table(table: Dictionary) -> Dictionary:
	var normalized: Dictionary = _normalized_public_table_config(table)
	normalized["table_id"] = String(table.get("table_id", table.get("room_id", "")))
	normalized["room_id"] = String(table.get("room_id", normalized.get("table_id", "")))
	normalized["table_name"] = String(table.get("table_name", table.get("name", normalized.get("table_id", "Public Table"))))
	normalized["table_type"] = String(table.get("table_type", normalized.get("table_type", "")))
	normalized["currency"] = String(table.get("currency", normalized.get("currency", "chip")))
	normalized["status"] = String(table.get("status", table.get("hand_state", STATUS_WAITING)))
	normalized["hand_state"] = String(table.get("hand_state", table.get("phase", normalized.get("status", STATUS_WAITING))))
	normalized["betting_round"] = String(table.get("betting_round", table.get("round", normalized.get("hand_state", STATUS_WAITING))))
	normalized["pot"] = int(table.get("pot", 0))
	normalized["side_pots"] = Array(table.get("side_pots", [])).duplicate(true)
	normalized["community_cards"] = Array(table.get("community_cards", [])).duplicate(true)
	normalized["current_turn_seat"] = int(table.get("current_turn_seat", table.get("turn_seat_index", -1)))
	normalized["table_log"] = Array(table.get("table_log", table.get("log", []))).duplicate(true)
	normalized["players"] = Array(table.get("players", [])).duplicate(true)
	normalized["seats"] = Array(table.get("seats", [])).duplicate(true)
	normalized["player_ids"] = Array(table.get("player_ids", [])).duplicate()
	normalized["real_player_ids"] = Array(table.get("real_player_ids", normalized.get("player_ids", []))).duplicate()
	normalized["pending_real_joiners"] = Array(table.get("pending_real_joiners", [])).duplicate(true)
	normalized["warmup_ai_player_ids"] = Array(table.get("warmup_ai_player_ids", [])).duplicate()
	normalized["is_ai_warmup"] = bool(table.get("is_ai_warmup", false))
	normalized["host_in_local_warmup"] = bool(table.get("host_in_local_warmup", false))
	normalized["waiting_for_real_players"] = bool(table.get("waiting_for_real_players", false))
	normalized["join_result"] = String(table.get("join_result", "seated"))
	normalized["created_by"] = String(table.get("created_by", "local_mock"))
	normalized["allow_mid_hand_join"] = bool(table.get("allow_mid_hand_join", false))
	normalized["hand_number"] = int(table.get("hand_number", table.get("hand_id", 0)))
	normalized["current_players"] = _real_player_count(normalized)
	return normalized

static func _is_public_chip_table(table: Dictionary) -> bool:
	return String(table.get("table_type", "")) == TABLE_TYPE_PUBLIC_CHIP and String(table.get("currency", "chip")) == "chip"

static func _is_clean_joinable_public_table(table: Dictionary, quick_join: bool) -> bool:
	if not _is_public_chip_table(table):
		return false
	if quick_join and not bool(table.get("allow_quick_join", true)):
		return false
	var status: String = String(table.get("status", ""))
	var hand_state: String = String(table.get("hand_state", status))
	var current_turn: int = int(table.get("current_turn_seat", -1))
	if quick_join and bool(table.get("is_ai_warmup", false)):
		return false
	if status in [STATUS_CLOSED, STATUS_DIRTY, STATUS_PAUSED, STATUS_FULL, STATUS_HAND_OVER, STATUS_SHOWDOWN_REVEAL, "showdown", "finished"]:
		return false
	if hand_state in [STATUS_CLOSED, STATUS_DIRTY, STATUS_PAUSED, STATUS_HAND_OVER, STATUS_SHOWDOWN_REVEAL, "showdown", "finished"]:
		return false
	if status not in [STATUS_WAITING, STATUS_WAITING_FOR_PLAYERS, STATUS_OPEN, STATUS_AI_WARMUP]:
		return false
	if hand_state not in [STATUS_WAITING, STATUS_WAITING_FOR_PLAYERS, STATUS_OPEN, STATUS_AI_WARMUP, "idle", "pre_hand"]:
		return false
	if current_turn == -1 and hand_state not in [STATUS_WAITING, STATUS_WAITING_FOR_PLAYERS, STATUS_OPEN, STATUS_AI_WARMUP, "idle", "pre_hand"]:
		return false
	if int(table.get("current_players", 0)) >= int(table.get("max_players", 9)):
		return false
	var has_player_records: bool = not Array(table.get("players", [])).is_empty() or not Array(table.get("seats", [])).is_empty()
	if _connected_player_count(table) <= 0 and has_player_records:
		return false
	return true

static func _should_close_dirty_table(table: Dictionary) -> bool:
	var status: String = String(table.get("status", ""))
	var hand_state: String = String(table.get("hand_state", status))
	var has_player_records: bool = not Array(table.get("players", [])).is_empty() or not Array(table.get("seats", [])).is_empty()
	return status in [STATUS_CLOSED, STATUS_DIRTY, STATUS_HAND_OVER, STATUS_SHOWDOWN_REVEAL] or hand_state in [STATUS_HAND_OVER, STATUS_SHOWDOWN_REVEAL, STATUS_CLOSED, STATUS_DIRTY] or (_connected_player_count(table) <= 0 and (status in [STATUS_PLAYING, STATUS_HAND_OVER] or has_player_records))

static func _connected_player_count(table: Dictionary) -> int:
	var counted := {}
	var count := 0
	for player_item in Array(table.get("players", [])):
		var player: Dictionary = Dictionary(player_item)
		if not _is_connected_occupied_player(player):
			continue
		var player_id: String = String(player.get("player_id", player.get("id", "player_%d" % count)))
		if counted.has(player_id):
			continue
		counted[player_id] = true
		count += 1
	for seat_item in Array(table.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item)
		if not _is_connected_occupied_player(seat):
			continue
		var seat_player_id: String = String(seat.get("player_id", seat.get("id", "seat_%s" % String(seat.get("seat_id", count)))))
		if counted.has(seat_player_id):
			continue
		counted[seat_player_id] = true
		count += 1
	var player_ids: Array = Array(table.get("player_ids", []))
	if count == 0 and not player_ids.is_empty():
		for player_id_item in player_ids:
			var listed_id: String = String(player_id_item)
			if listed_id == "" or counted.has(listed_id):
				continue
			counted[listed_id] = true
			count += 1
	if count == 0 and Array(table.get("players", [])).is_empty() and Array(table.get("seats", [])).is_empty() and player_ids.is_empty():
		count = max(int(table.get("current_players", 0)), 0)
	return min(count, int(table.get("max_players", 9)))

static func _real_player_count(table: Dictionary) -> int:
	var real_player_ids: Array = Array(table.get("real_player_ids", []))
	if not real_player_ids.is_empty():
		return min(real_player_ids.size(), int(table.get("max_players", 9)))
	return _connected_player_count(table)

static func _is_connected_occupied_player(data: Dictionary) -> bool:
	var status: String = String(data.get("status", ""))
	if data.has("status") and status in ["empty", "left", "out", "disconnected"]:
		return false
	if bool(data.get("disconnected", false)):
		return false
	if data.has("connected") and not bool(data.get("connected", true)):
		return false
	if data.has("occupied") and not bool(data.get("occupied", true)):
		return false
	if bool(data.get("warmup_ai", false)):
		return false
	return String(data.get("player_id", data.get("id", "player"))) != ""

static func _table_matches_preferred_config(table: Dictionary, preferred_config: Dictionary) -> bool:
	if preferred_config.is_empty():
		return true
	if preferred_config.has("buy_in") and int(table.get("buy_in", 0)) != int(preferred_config.get("buy_in", 0)):
		return false
	if preferred_config.has("small_blind") and int(table.get("small_blind", 0)) != int(preferred_config.get("small_blind", 0)):
		return false
	if preferred_config.has("big_blind") and int(table.get("big_blind", 0)) != int(preferred_config.get("big_blind", 0)):
		return false
	var preferred_hands: int = int(preferred_config.get("hand_count", preferred_config.get("max_hands", int(table.get("hand_count", 10)))))
	var table_hands: int = int(table.get("hand_count", table.get("max_hands", preferred_hands)))
	if _normalized_hand_count(preferred_hands) != _normalized_hand_count(table_hands):
		return false
	return true

static func _normalized_hand_count(value: int) -> int:
	return 999 if value <= 0 or value >= 999 else value

static func _update_public_table_status(table: Dictionary) -> void:
	if bool(table.get("is_ai_warmup", false)):
		table["status"] = STATUS_AI_WARMUP
		table["hand_state"] = STATUS_AI_WARMUP
		return
	var current_players: int = _real_player_count(table)
	var max_players: int = int(table.get("max_players", 9))
	table["current_players"] = current_players
	if current_players >= max_players:
		table["status"] = STATUS_FULL
	elif current_players < 2:
		table["status"] = STATUS_WAITING_FOR_PLAYERS
		table["hand_state"] = STATUS_WAITING_FOR_PLAYERS
	elif String(table.get("status", STATUS_WAITING)) in [STATUS_FULL, STATUS_WAITING_FOR_PLAYERS]:
		table["status"] = STATUS_OPEN
		table["hand_state"] = STATUS_OPEN

static func _public_table_snapshot(table: Dictionary) -> Dictionary:
	var snapshot := table.duplicate(true)
	snapshot.erase("player_ids")
	return snapshot

static func _player_id(player: Dictionary) -> String:
	return String(player.get("player_id", player.get("id", "local_player")))
