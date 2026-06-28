extends RefCounted
class_name PublicTableRegistry

const TABLE_TYPE_PUBLIC_CHIP := "public_chip"
const STATUS_WAITING := "waiting"
const STATUS_PLAYING := "playing"
const STATUS_FULL := "full"

static var _tables: Dictionary = {}
static var _next_table_number := 1

static func reset() -> void:
	_tables.clear()
	_next_table_number = 1

static func list_public_tables() -> Array[Dictionary]:
	var public_tables: Array[Dictionary] = []
	for table_id in _tables.keys():
		var table: Dictionary = Dictionary(_tables[table_id])
		if String(table.get("table_type", "")) != TABLE_TYPE_PUBLIC_CHIP:
			continue
		public_tables.append(_public_table_snapshot(table))
	return public_tables

static func create_public_table(config: Dictionary = {}) -> Dictionary:
	var table_id := String(config.get("table_id", "pub_chip_%03d" % _next_table_number))
	if not config.has("table_id"):
		_next_table_number += 1
	var small_blind: int = int(config.get("small_blind", 25))
	var big_blind: int = int(config.get("big_blind", 50))
	var buy_in: int = int(config.get("buy_in", 20000))
	var max_players: int = int(config.get("max_players", 9))
	var player_ids: Array[String] = []
	for player_id in Array(config.get("player_ids", [])):
		player_ids.append(String(player_id))
	var table := {
		"table_id": table_id,
		"table_name": String(config.get("table_name", "Public Chip %03d" % max(_next_table_number - 1, 1))),
		"table_type": TABLE_TYPE_PUBLIC_CHIP,
		"status": String(config.get("status", STATUS_WAITING)),
		"small_blind": small_blind,
		"big_blind": big_blind,
		"blinds": {
			"small": small_blind,
			"big": big_blind,
		},
		"buy_in": buy_in,
		"buy_in_min": buy_in,
		"buy_in_max": buy_in,
		"hand_count": int(config.get("hand_count", config.get("max_hands", 10))),
		"max_players": max_players,
		"current_players": min(int(config.get("current_players", player_ids.size())), max_players),
		"created_by": String(config.get("created_by", "local_mock")),
		"allow_quick_join": bool(config.get("allow_quick_join", true)),
		"player_ids": player_ids,
	}
	_update_public_table_status(table)
	_tables[table_id] = table
	return _public_table_snapshot(table)

static func add_mock_table(table: Dictionary) -> void:
	_tables[String(table.get("table_id", ""))] = table.duplicate(true)

static func join_public_table(table_id: String, player: Dictionary) -> Dictionary:
	if not _tables.has(table_id):
		return {}
	var table: Dictionary = Dictionary(_tables[table_id]).duplicate(true)
	if String(table.get("table_type", "")) != TABLE_TYPE_PUBLIC_CHIP:
		return {}
	if int(table.get("current_players", 0)) >= int(table.get("max_players", 9)):
		table["status"] = STATUS_FULL
		_tables[table_id] = table
		return {}
	var player_id := _player_id(player)
	var player_ids: Array = Array(table.get("player_ids", [])).duplicate()
	if not player_ids.has(player_id):
		player_ids.append(player_id)
		table["player_ids"] = player_ids
		table["current_players"] = min(int(table.get("current_players", 0)) + 1, int(table.get("max_players", 9)))
	_update_public_table_status(table)
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
	table["current_players"] = min(player_ids.size(), int(table.get("max_players", 9)))
	_update_public_table_status(table)
	_tables[table_id] = table

static func quick_join_public_table(player: Dictionary, preferred_config: Dictionary = {}) -> Dictionary:
	var table_id := _best_quick_join_table_id(true)
	if table_id == "":
		table_id = _best_quick_join_table_id(false)
	if table_id == "":
		var created := create_public_table(preferred_config)
		table_id = String(created.get("table_id", ""))
	return join_public_table(table_id, player)

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

static func _best_quick_join_table_id(waiting_only: bool) -> String:
	var best_id := ""
	var best_players := -1
	for table_id in _tables.keys():
		var table: Dictionary = Dictionary(_tables[table_id])
		if String(table.get("table_type", "")) != TABLE_TYPE_PUBLIC_CHIP:
			continue
		if not bool(table.get("allow_quick_join", true)):
			continue
		if int(table.get("current_players", 0)) >= int(table.get("max_players", 9)):
			continue
		if waiting_only and String(table.get("status", "")) != STATUS_WAITING:
			continue
		var current_players: int = int(table.get("current_players", 0))
		if current_players > best_players:
			best_players = current_players
			best_id = String(table.get("table_id", table_id))
	return best_id

static func _update_public_table_status(table: Dictionary) -> void:
	var current_players: int = int(table.get("current_players", 0))
	var max_players: int = int(table.get("max_players", 9))
	if current_players >= max_players:
		table["status"] = STATUS_FULL
	elif String(table.get("status", STATUS_WAITING)) == STATUS_FULL:
		table["status"] = STATUS_WAITING

static func _public_table_snapshot(table: Dictionary) -> Dictionary:
	var snapshot := table.duplicate(true)
	snapshot.erase("player_ids")
	return snapshot

static func _player_id(player: Dictionary) -> String:
	return String(player.get("player_id", player.get("id", "local_player")))
