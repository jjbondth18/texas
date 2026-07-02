extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "warmup_listed_room",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "host_player"})
	var warmup: Dictionary = PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)
	_require(bool(warmup.get("host_in_local_warmup", false)), "Host warm-up flag must be set.")
	_require(not bool(warmup.get("is_ai_warmup", true)), "Server public room must not become an AI warm-up table.")

	var tables: Array[Dictionary] = PublicTableRegistryScript.list_public_tables()
	_require(tables.size() == 1, "Host-warming public room must stay visible in Browser list.")
	var listed: Dictionary = tables[0]
	_require(str(listed.get("table_id", "")) == "warmup_listed_room", "Browser list must include the host-warming room.")
	_require(bool(listed.get("host_in_local_warmup", false)), "Listed room must expose host_in_local_warmup.")
	_require(str(listed.get("status", "")) == "waiting_for_players", "Host-warming room must remain a waiting public room.")

	PublicTableRegistryScript.reset()
	print("Public room listed during host warmup test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
