extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "quick_host_warmup_room",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "dev_player_1"})
	PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)
	var joined: Dictionary = backend.quick_join_public_table({"player_id": "dev_player_2"}, {
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	_require(str(joined.get("table_id", "")) == "quick_host_warmup_room", "Quick must choose the existing host warm-up room.")
	_require(not bool(joined.get("host_in_local_warmup", true)), "Quick join must interrupt host warm-up.")
	_require(int(joined.get("current_players", 0)) == 2, "Quick join must return two real players.")

	PublicTableRegistryScript.reset()
	print("Quick matches host warmup room test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
