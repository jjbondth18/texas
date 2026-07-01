extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({"table_id": "one_player", "buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10, "current_players": 1, "created_at": "2026-01-01T00:00:00Z"})
	PublicTableRegistryScript.create_public_table({"table_id": "three_players", "buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10, "current_players": 3, "created_at": "2026-01-02T00:00:00Z"})
	var joined: Dictionary = backend.quick_join_public_table(PlayerProfileScript.default_profile(), {"buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10})
	_require(str(joined.get("table_id", "")) == "three_players", "Quick must prefer the most populated matching waiting table.")
	PublicTableRegistryScript.reset()
	print("Quick prefers most populated table test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
