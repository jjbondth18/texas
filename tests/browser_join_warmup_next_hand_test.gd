extends RefCounted

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func run() -> void:
	PublicTableRegistryScript.reset()
	var created := PublicTableRegistryScript.create_public_table({
		"table_id": "pending_join_warmup",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"max_players": 6,
	})
	PublicTableRegistryScript.join_public_table(String(created.get("table_id", "")), {"player_id": "creator"})
	PublicTableRegistryScript.start_ai_warmup(String(created.get("table_id", "")), 3)

	var pending := PublicTableRegistryScript.join_public_table("pending_join_warmup", {
		"player_id": "real_joiner",
		"player_name": "Real Joiner",
	})
	assert(String(pending.get("join_result", "seated")) == "seated")
	assert(Array(pending.get("pending_real_joiners", [])).is_empty())
	assert(int(pending.get("current_players", 0)) == 2)
	assert(Array(pending.get("warmup_ai_player_ids", [])).is_empty())
	assert(bool(pending.get("host_in_local_warmup", true)) == false)

	var seated := PublicTableRegistryScript.settle_pending_real_joiners("pending_join_warmup")
	assert(bool(seated.get("is_ai_warmup", true)) == false)
	assert(Array(seated.get("warmup_ai_player_ids", [])).is_empty())
	assert(Array(seated.get("pending_real_joiners", [])).is_empty())
	assert(int(seated.get("current_players", 0)) == 2)
	assert(String(seated.get("status", "")) == "ready_to_start")
