extends SceneTree

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	var backend := LocalMockBackendScript.new()
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "browser_join_warmup_room",
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 5,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "host_player"})
	PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)

	var context: Dictionary = backend.join_public_table("browser_join_warmup_room", {"player_id": "dev_player_2", "display_name": "DevPlayer2"})
	_require(not context.is_empty(), "Browser join must be allowed while host is in local warm-up.")
	_require(not bool(context.get("host_in_local_warmup", true)), "Browser join must interrupt host local warm-up.")
	_require(not bool(context.get("is_ai_warmup", true)), "Joined public room must remain real-player-only.")
	_require(int(context.get("current_players", 0)) == 2, "Joined room must contain two real players.")
	_require(Array(context.get("warmup_ai_player_ids", [])).is_empty(), "Warm-up AI must not enter public server seats.")

	PublicTableRegistryScript.reset()
	print("Browser join interrupts host warmup test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
