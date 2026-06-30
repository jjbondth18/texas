extends RefCounted

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func run() -> void:
	PublicTableRegistryScript.reset()
	var table := PublicTableRegistryScript.create_public_table({
		"table_id": "warmup_create_waiting",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"max_players": 6,
	})
	assert(String(table.get("status", "")) == "waiting_for_players")
	assert(bool(table.get("is_ai_warmup", false)) == false)
	assert(Array(table.get("warmup_ai_player_ids", [])).is_empty())

	var joined := PublicTableRegistryScript.join_public_table("warmup_create_waiting", {"player_id": "creator"})
	assert(int(joined.get("current_players", 0)) == 1)
	assert(String(joined.get("status", "")) == "waiting_for_players")
	assert(bool(joined.get("is_ai_warmup", false)) == false)
	assert(Array(joined.get("warmup_ai_player_ids", [])).is_empty())

	var warmup := PublicTableRegistryScript.start_ai_warmup("warmup_create_waiting", 3)
	assert(bool(warmup.get("is_ai_warmup", false)) == true)
	assert(String(warmup.get("status", "")) == "ai_warmup")
	assert(Array(warmup.get("warmup_ai_player_ids", [])).size() == 3)
	assert(int(warmup.get("current_players", 0)) == 1)

	var listed := PublicTableRegistryScript.list_public_tables()
	assert(listed.size() == 1)
	assert(int(Dictionary(listed[0]).get("current_players", 0)) == 1)
	assert(bool(Dictionary(listed[0]).get("is_ai_warmup", false)) == true)
