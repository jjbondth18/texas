extends RefCounted

const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func run() -> void:
	PublicTableRegistryScript.reset()
	var backend = LocalMockBackendScript.new()
	var profile: Dictionary = {
		"player_id": "local_creator",
		"player_name": "Luna0581",
		"total_chips": 10530,
		"avatar_id": "dealer_01_dog",
	}
	var table: Dictionary = backend.create_public_table({
		"table_id": "browser_create_seats_creator",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"max_players": 6,
	})
	var context: Dictionary = backend.join_public_table(String(table.get("table_id", "")), profile)
	assert(not context.is_empty())
	assert(bool(context.get("waiting_for_real_players", false)) == true)
	assert(bool(context.get("is_ai_warmup", false)) == false)
	assert(int(Dictionary(context.get("public_table", {})).get("current_players", 0)) == 1)

	var creator_seat: Dictionary = {}
	for seat_item in Array(context.get("seats", [])):
		var seat: Dictionary = Dictionary(seat_item)
		if bool(seat.get("is_local", false)):
			creator_seat = seat
			break
	assert(not creator_seat.is_empty())
	assert(String(creator_seat.get("player_id", "")) == "local_creator")
	assert(String(creator_seat.get("player_name", "")) == "Luna0581")
	assert(bool(creator_seat.get("connected", false)) == true)
	assert(bool(creator_seat.get("is_ai", true)) == false)
	assert(bool(creator_seat.get("occupied", false)) == true)
	assert(int(creator_seat.get("table_stack", 0)) == 10000)
	assert(String(creator_seat.get("status", "")) != "empty")
