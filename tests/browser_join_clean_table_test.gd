extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _init() -> void:
	_test_browser_join_source_guards()
	_test_join_clean_waiting_table_succeeds()
	_test_join_hand_over_table_fails()
	_test_disconnected_bot_not_reused_or_counted()
	print("Browser join clean table test passed.")
	quit(0)


func _test_browser_join_source_guards() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var join_body := _function_body(source, "func _join_public_chip_table_after_wallet_check")
	_require(source.contains("_is_joinable_room_browser_table"), "Browser must filter and validate joinable tables")
	_require(source.contains("This table is no longer available."), "Browser join must show table unavailable message")
	_require(join_body.find("_local_backend.join_public_table(room_id, _player_profile)") < join_body.find("service.deduct_table_buy_in(buy_in)"), "Browser join must validate backend join before deducting wallet chips")
	_require(source.contains("not _is_joinable_room_browser_table(table_info)"), "Browser join must reject stale table info")


func _test_join_clean_waiting_table_succeeds() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "clean_waiting_join",
		"status": "waiting",
		"hand_state": "waiting",
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 10,
		"max_players": 6,
	})
	var backend := LocalMockBackendScript.new()
	var context := backend.join_public_table("clean_waiting_join", PlayerProfileScript.default_profile())
	_require(not context.is_empty(), "joining a clean waiting public table must succeed")
	_require(String(context.get("hand_state", "")) == "waiting", "joined context must not start in hand_over")
	_require(int(context.get("current_turn_seat", 0)) == -1, "joined clean context must not inherit stale current turn")


func _test_join_hand_over_table_fails() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "stale_hand_over",
		"table_type": "public_chip",
		"status": "hand_over",
		"hand_state": "hand_over",
		"current_turn_seat": -1,
		"current_players": 2,
		"max_players": 6,
	})
	var backend := LocalMockBackendScript.new()
	var context := backend.join_public_table("stale_hand_over", PlayerProfileScript.default_profile())
	_require(context.is_empty(), "joining a hand_over table must fail with unavailable table")


func _test_disconnected_bot_not_reused_or_counted() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "waiting_with_dead_bot",
		"table_type": "public_chip",
		"status": "waiting",
		"hand_state": "waiting",
		"max_players": 6,
		"seats": [
			{"seat_id": 2, "player_id": "dead_bot", "status": "playing", "occupied": true, "connected": false, "disconnected": true},
		],
	})
	var listed := PublicTableRegistryScript.list_public_tables()
	_require(listed.is_empty(), "disconnected-only waiting table must be hidden from browser players")
	var backend := LocalMockBackendScript.new()
	var context := backend.join_public_table("waiting_with_dead_bot", PlayerProfileScript.default_profile())
	_require(context.is_empty(), "Browser join must not reuse disconnected-only table")


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next_func := source.find("\nfunc ", start + signature.length())
	if next_func < 0:
		return source.substr(start)
	return source.substr(start, next_func - start)
