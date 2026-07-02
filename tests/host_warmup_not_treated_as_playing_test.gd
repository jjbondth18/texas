extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "host_warmup_state_room",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "host_player"})
	var warmup: Dictionary = PublicTableRegistryScript.start_ai_warmup(str(created.get("table_id", "")), 3)
	_require(str(warmup.get("status", "")) == "waiting_for_players", "Host local warm-up must not change public status to playing.")
	_require(str(warmup.get("hand_state", "")) == "waiting_for_players", "Host local warm-up must not change public hand_state to playing.")
	_require(not bool(warmup.get("is_ai_warmup", true)), "Host local warm-up must not mark the public room as server AI warm-up.")

	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("room.hostInLocalWarmup !== \"\"") != -1, "Server state calculation must handle host local warm-up explicitly.")
	_require(server_source.find("if (room.isAiWarmup && room.hostInLocalWarmup === \"\") return false;") != -1, "Server Quick filter must not reject host-warming rooms as AI warm-up.")

	PublicTableRegistryScript.reset()
	print("Host warmup not treated as playing test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
