extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "browser_host_warmup_room",
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 5,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "dev_player_1"})
	PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)
	var tables: Array[Dictionary] = PublicTableRegistryScript.list_public_tables()
	_require(tables.size() == 1, "Browser-visible list must include host warm-up room.")
	var room: Dictionary = tables[0]
	_require(str(room.get("table_id", "")) == "browser_host_warmup_room", "Browser must receive the host warm-up room id.")
	_require(bool(room.get("host_in_local_warmup", false)), "Browser room must expose host_in_local_warmup.")
	_require(not bool(room.get("is_ai_warmup", true)), "Browser room must not be marked as an AI shadow table.")

	PublicTableRegistryScript.reset()
	print("Browser receives host warmup room test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
