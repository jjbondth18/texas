extends SceneTree

const HomeScene := preload("res://scenes/screens/home_lobby_screen.tscn")
const LocalMockBackendScript := preload("res://scripts/services/local_mock_backend.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")

func _initialize() -> void:
	var profile := PlayerProfileScript.default_profile()
	var backend := LocalMockBackendScript.new()

	PublicTableRegistryScript.reset()
	var created_context := backend.quick_join_public_table(profile, {"buy_in": 5000})
	_require(String(created_context.get("table_type", "")) == "public_chip", "quick_join must create a public chip table context")
	var tables := PublicTableRegistryScript.list_public_tables()
	_require(tables.size() == 1, "quick_join must create a table when none exists")
	_require(int(tables[0].get("current_players", 0)) == 1, "created quick_join table must include the local player")

	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "waiting_one",
		"current_players": 1,
	})
	var joined_existing := backend.quick_join_public_table(profile, {})
	_require(String(joined_existing.get("table_id", "")) == "waiting_one", "quick_join must join an existing waiting public table")

	PublicTableRegistryScript.reset()
	PublicTableRegistryScript.create_public_table({
		"table_id": "waiting_small",
		"current_players": 1,
	})
	PublicTableRegistryScript.create_public_table({
		"table_id": "waiting_busy",
		"current_players": 4,
	})
	var joined_busy := backend.quick_join_public_table(profile, {})
	_require(String(joined_busy.get("table_id", "")) == "waiting_busy", "quick_join must prefer the most populated non-full waiting table")

	PublicTableRegistryScript.reset()
	backend.create_friends_room(profile)
	for table in PublicTableRegistryScript.list_public_tables():
		_require(String(table.get("table_type", "")) == "public_chip", "private rooms must not be returned by list_public_tables")
	_require(PublicTableRegistryScript.list_public_tables().is_empty(), "private room creation must not register a public table")

	PublicTableRegistryScript.reset()
	backend.create_training_table(profile)
	_require(PublicTableRegistryScript.list_public_tables().is_empty(), "training table creation must not register a public table")

	PublicTableRegistryScript.reset()
	var home := HomeScene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame
	PublicTableRegistryScript.reset()
	home.call("_show_quick_play_setup")
	home.call("_select_quick_play_mode", "gem")
	home.call("_start_quick_play_from_setup")
	_require(PublicTableRegistryScript.list_public_tables().is_empty(), "Gem Match placeholder must not create a public table")

	home.queue_free()
	PublicTableRegistryScript.reset()
	print("Public table registry smoke test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
