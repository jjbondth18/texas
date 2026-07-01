extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _init() -> void:
	_test_quick_config_is_complete()
	_test_quick_creates_clean_table_when_no_match()
	_test_quick_skips_dirty_and_disconnected_tables()
	print("Quick join valid config test passed.")
	quit(0)


func _test_quick_config_is_complete() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("\"table_type\": \"public_chip\""), "Quick config must include table_type")
	_require(source.contains("\"currency\": \"chip\""), "Quick config must include currency")
	_require(source.contains("\"hand_count\": _normalized_hand_count_for_context(_selected_quick_max_hands)"), "Quick config must include hand_count")
	_require(source.contains("\"small_blind\": _selected_quick_small_blind"), "Quick config must include small_blind")
	_require(source.contains("\"big_blind\": _selected_quick_big_blind"), "Quick config must include big_blind")
	_require(source.contains("\"allow_quick_join\": true"), "Quick config must allow quick join")


func _test_quick_creates_clean_table_when_no_match() -> void:
	PublicTableRegistryScript.reset()
	var backend := LocalMockBackendScript.new()
	var profile := PlayerProfileScript.default_profile()
	var context := backend.quick_join_public_table(profile, {
		"table_type": "public_chip",
		"currency": "chip",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
		"max_players": 6,
		"allow_quick_join": true,
	})
	_require(not context.is_empty(), "quick join must create a table instead of returning invalid_table_config")
	_require(String(context.get("table_type", "")) == "public_chip", "quick-created context must be public_chip")
	_require(String(context.get("hand_state", "")) in ["waiting_for_players", "waiting_ready", "ready_to_start"], "quick-created context must be a waiting public table")
	var listed := PublicTableRegistryScript.list_public_tables()
	_require(listed.size() == 1, "quick-created clean table must be listed")
	_require(int(listed[0].get("pot", -1)) == 0, "quick-created table must have clean pot")
	_require(Array(listed[0].get("community_cards", [])).is_empty(), "quick-created table must have no old board")


func _test_quick_skips_dirty_and_disconnected_tables() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "old_hand_over",
		"table_type": "public_chip",
		"status": "hand_over",
		"hand_state": "hand_over",
		"current_turn_seat": -1,
		"current_players": 2,
		"max_players": 6,
		"allow_quick_join": true,
	})
	PublicTableRegistryScript.add_mock_table({
		"table_id": "disconnected_only",
		"table_type": "public_chip",
		"status": "playing",
		"hand_state": "playing",
		"current_turn_seat": 3,
		"max_players": 6,
		"allow_quick_join": true,
		"seats": [
			{"seat_id": 3, "player_id": "bot_3", "status": "playing", "occupied": true, "connected": false, "disconnected": true},
		],
	})
	var backend := LocalMockBackendScript.new()
	var context := backend.quick_join_public_table(PlayerProfileScript.default_profile(), {"buy_in": 5000})
	_require(not context.is_empty(), "quick join must recover by creating a clean table")
	_require(String(context.get("table_id", "")) not in ["old_hand_over", "disconnected_only"], "quick join must not join dirty or disconnected-only tables")


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
