extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "chip_table",
		"table_type": "public_chip",
		"currency": "chips",
		"buy_in": 50,
		"small_blind": 2,
		"big_blind": 5,
		"hand_count": 10,
		"current_players": 3,
	})
	var joined: Dictionary = LocalMockBackendScript.new().quick_join_public_table(PlayerProfileScript.default_profile(), {
		"table_type": "public_gem",
		"currency": "gems",
		"buy_in": 50,
		"small_blind": 2,
		"big_blind": 5,
		"hand_count": 10,
	})
	_require(str(joined.get("table_id", "")) != "chip_table", "Quick Gem must not match a public chip table.")
	_require(str(joined.get("table_type", "")) == "public_gem", "Quick Gem fallback must create a public_gem table.")
	PublicTableRegistryScript.reset()
	print("Quick Gem does not match chip table test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
