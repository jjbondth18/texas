extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "gem_table",
		"table_type": "public_gem",
		"currency": "gems",
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 10,
		"current_players": 3,
	})
	var joined: Dictionary = LocalMockBackendScript.new().quick_join_public_table(PlayerProfileScript.default_profile(), {
		"table_type": "public_chip",
		"currency": "chips",
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 10,
	})
	_require(str(joined.get("table_id", "")) != "gem_table", "Quick Chip must not match a public gem table.")
	_require(str(joined.get("table_type", "")) == "public_chip", "Quick Chip fallback must create a public_chip table.")
	PublicTableRegistryScript.reset()
	print("Quick Chip does not match gem table test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
