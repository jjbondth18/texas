extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({"table_id": "different_stakes", "buy_in": 5000, "small_blind": 25, "big_blind": 50, "hand_count": 10})
	var joined: Dictionary = backend.quick_join_public_table(PlayerProfileScript.default_profile(), {"buy_in": 20000, "small_blind": 100, "big_blind": 200, "hand_count": 20})
	_require(not joined.is_empty(), "Quick must create a table when no exact match exists.")
	_require(str(joined.get("table_id", "")) != "different_stakes", "Quick must not join a mismatched table.")
	_require(int(joined.get("buy_in", 0)) == 20000, "Quick-created table must use selected buy-in.")
	_require(int(joined.get("small_blind", 0)) == 100 and int(joined.get("big_blind", 0)) == 200, "Quick-created table must use selected blinds.")
	PublicTableRegistryScript.reset()
	print("Quick creates table when no match test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
