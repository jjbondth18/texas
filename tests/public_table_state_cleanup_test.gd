extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _init() -> void:
	_test_browser_list_filters_dirty_tables()
	_test_disconnected_players_are_not_counted()
	_test_clean_create_initializes_waiting_table()
	print("Public table state cleanup test passed.")
	quit(0)


func _test_browser_list_filters_dirty_tables() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "dirty_hand_over",
		"table_type": "public_chip",
		"status": "hand_over",
		"hand_state": "hand_over",
		"current_turn_seat": -1,
		"current_players": 2,
		"max_players": 6,
	})
	PublicTableRegistryScript.add_mock_table({
		"table_id": "private_room",
		"table_type": "private_room",
		"status": "waiting",
		"current_players": 2,
		"max_players": 6,
	})
	PublicTableRegistryScript.add_mock_table({
		"table_id": "clean_waiting",
		"table_type": "public_chip",
		"status": "waiting",
		"hand_state": "waiting",
		"current_players": 1,
		"max_players": 6,
	})
	var tables := PublicTableRegistryScript.list_public_tables()
	_require(tables.size() == 1, "only clean public chip waiting table should be listed")
	_require(String(tables[0].get("table_id", "")) == "clean_waiting", "dirty hand_over table must be filtered")


func _test_disconnected_players_are_not_counted() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "disconnected_only",
		"table_type": "public_chip",
		"status": "playing",
		"hand_state": "playing",
		"current_turn_seat": 2,
		"max_players": 6,
		"seats": [
			{"seat_id": 2, "player_id": "bot_1", "status": "playing", "occupied": true, "connected": false, "disconnected": true},
		],
	})
	_require(PublicTableRegistryScript.list_public_tables().is_empty(), "disconnected-only playing table must be hidden and cleaned")

	PublicTableRegistryScript.add_mock_table({
		"table_id": "connected_one",
		"table_type": "public_chip",
		"status": "waiting",
		"hand_state": "waiting",
		"max_players": 6,
		"seats": [
			{"seat_id": 1, "player_id": "bot_old", "status": "playing", "occupied": true, "connected": false, "disconnected": true},
			{"seat_id": 5, "player_id": "local_player", "status": "sitting", "occupied": true, "connected": true},
		],
	})
	var tables := PublicTableRegistryScript.list_public_tables()
	_require(tables.size() == 1, "connected waiting table must remain listed")
	_require(int(tables[0].get("current_players", 0)) == 1, "disconnected bot must not count as current player")


func _test_clean_create_initializes_waiting_table() -> void:
	PublicTableRegistryScript.reset()
	var table := PublicTableRegistryScript.create_public_table({
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
		"max_players": 6,
	})
	_require(String(table.get("table_type", "")) == "public_chip", "created table must be public_chip")
	_require(String(table.get("status", "")) == "waiting", "created table must start waiting")
	_require(String(table.get("hand_state", "")) == "waiting", "created table hand_state must start waiting")
	_require(int(table.get("pot", -1)) == 0, "created table pot must be zero")
	_require(Array(table.get("community_cards", [])).is_empty(), "created table must not inherit community cards")
	_require(int(table.get("current_turn_seat", 0)) == -1, "created table must not inherit a turn")


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
