extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	var profile := PlayerProfileScript.default_profile()
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "wrong_buy_in",
		"buy_in": 5000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
		"current_players": 4,
	})
	PublicTableRegistryScript.create_public_table({
		"table_id": "exact_match",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
		"current_players": 1,
	})
	var joined: Dictionary = backend.quick_join_public_table(profile, {
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	_require(str(joined.get("table_id", "")) == "exact_match", "Quick must join exact public chip table config.")
	PublicTableRegistryScript.reset()
	print("Quick matches public table by config test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
