extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({"table_id": "full_match", "buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10, "current_players": 6, "max_players": 6})
	PublicTableRegistryScript.add_mock_table({"table_id": "closed_match", "table_type": "public_chip", "currency": "chip", "buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10, "status": "closed", "hand_state": "closed"})
	var joined: Dictionary = backend.quick_join_public_table(PlayerProfileScript.default_profile(), {"buy_in": 10000, "small_blind": 50, "big_blind": 100, "hand_count": 10, "max_players": 6})
	_require(str(joined.get("table_id", "")) not in ["full_match", "closed_match"], "Quick must skip full and closed tables.")
	PublicTableRegistryScript.reset()
	print("Quick does not join full or closed table test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
