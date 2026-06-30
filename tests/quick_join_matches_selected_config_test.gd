extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _init() -> void:
	var backend := LocalMockBackendScript.new()
	var profile := PlayerProfileScript.default_profile()
	var selected_config := {
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"max_hands": 20,
	}

	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "wrong_stakes",
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 10,
		"current_players": 5,
	})
	PublicTableRegistryScript.create_public_table({
		"table_id": "matching_stakes",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 20,
		"current_players": 2,
	})
	var joined_match := backend.quick_join_public_table(profile, selected_config)
	_require(String(joined_match.get("table_id", "")) == "matching_stakes", "Quick join must prefer a public table matching selected config")

	PublicTableRegistryScript.reset()
	var created_context := backend.quick_join_public_table(profile, selected_config)
	_require(String(created_context.get("table_type", "")) == "public_chip", "Quick join fallback must create a public chip table")
	_require(int(created_context.get("buy_in", 0)) == 10000, "Quick-created table must use selected buy-in")
	_require(int(created_context.get("small_blind", 0)) == 50, "Quick-created table must use selected small blind")
	_require(int(created_context.get("big_blind", 0)) == 100, "Quick-created table must use selected big blind")
	_require(int(created_context.get("max_hands", 0)) == 20, "Quick-created table must use selected hand count")

	PublicTableRegistryScript.reset()
	print("Quick join matches selected config test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
