extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({"table_id": "playing_match", "table_type": "public_chip", "currency": "chip", "buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10, "status": "playing", "hand_state": "preflop", "current_players": 3, "max_players": 6})
	var joined: Dictionary = backend.quick_join_public_table(PlayerProfileScript.default_profile(), {"buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10})
	_require(str(joined.get("table_id", "")) != "playing_match", "Quick must not join a playing table.")
	_require(str(joined.get("status", "")) in ["waiting_for_players", "waiting_ready", "ready_to_start"], "Quick no-match fallback must create a waiting table.")
	PublicTableRegistryScript.reset()
	print("Quick does not join playing table test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
