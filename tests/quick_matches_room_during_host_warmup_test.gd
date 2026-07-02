extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "warmup_quick_match",
		"buy_in": 20000,
		"small_blind": 100,
		"big_blind": 200,
		"hand_count": 20,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "host_player"})
	PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)

	var joined: Dictionary = backend.quick_join_public_table({"player_id": "joiner_player", "display_name": "Joiner"}, {
		"buy_in": 20000,
		"small_blind": 100,
		"big_blind": 200,
		"hand_count": 20,
	})
	_require(str(joined.get("table_id", "")) == "warmup_quick_match", "Quick must match the host-warming public room instead of creating a new table.")
	_require(int(joined.get("current_players", 0)) == 2, "Quick join must count host and joiner as real players.")
	_require(not bool(joined.get("host_in_local_warmup", true)), "Real join must interrupt host local warm-up.")
	_require(str(joined.get("status", "")) in ["waiting_ready", "ready_to_start"], "Interrupted room must return to ready/waiting state.")

	PublicTableRegistryScript.reset()
	print("Quick matches room during host warmup test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
