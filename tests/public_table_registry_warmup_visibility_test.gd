extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.add_mock_table({
		"table_id": "server_ai_warmup_shadow",
		"table_type": "public_chip",
		"currency": "chip",
		"status": "ai_warmup",
		"hand_state": "ai_warmup",
		"is_ai_warmup": true,
		"host_in_local_warmup": false,
		"real_player_ids": ["host_player"],
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	var hidden_tables: Array[Dictionary] = PublicTableRegistryScript.list_public_tables()
	_require(hidden_tables.is_empty(), "Pure AI warm-up shadow tables must stay out of Browser list.")

	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "host_warming_visible",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "host_player"})
	PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)
	var visible_tables: Array[Dictionary] = PublicTableRegistryScript.list_public_tables()
	_require(visible_tables.size() == 1, "Host local warm-up public room must stay visible.")
	_require(str(Dictionary(visible_tables[0]).get("table_id", "")) == "host_warming_visible", "Visible room must be the host-warming public room.")

	PublicTableRegistryScript.reset()
	print("Public table registry warmup visibility test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
