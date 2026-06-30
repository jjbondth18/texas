extends RefCounted

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func run() -> void:
	PublicTableRegistryScript.reset()
	var table := PublicTableRegistryScript.quick_join_public_table({"player_id": "quick_local"}, {
		"buy_in": 5000,
		"small_blind": 25,
		"big_blind": 50,
		"hand_count": 10,
		"max_players": 6,
	})
	assert(not table.is_empty())
	assert(String(table.get("table_type", "")) == "public_chip")
	assert(bool(table.get("is_ai_warmup", false)) == true)
	assert(String(table.get("status", "")) == "ai_warmup")
	assert(int(table.get("current_players", 0)) == 1)
	assert(Array(table.get("warmup_ai_player_ids", [])).size() >= 1)
	assert(String(table.get("join_result", "seated")) == "seated")
