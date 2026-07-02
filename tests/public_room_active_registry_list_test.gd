extends SceneTree

const PublicTableRegistryScript := preload("res://scripts/services/public_table_registry.gd")


func _init() -> void:
	PublicTableRegistryScript.reset()
	var created: Dictionary = PublicTableRegistryScript.create_public_table({
		"table_id": "active_registry_room_1",
		"buy_in": 10000,
		"small_blind": 50,
		"big_blind": 100,
		"hand_count": 10,
	})
	PublicTableRegistryScript.join_public_table(str(created.get("table_id", "")), {"player_id": "dev_player_1"})
	var tables: Array[Dictionary] = PublicTableRegistryScript.list_public_tables()
	_require(tables.size() == 1, "Active public room registry must list the created room.")
	_require(str(tables[0].get("table_id", "")) == "active_registry_room_1", "Table list must return the active registry room.")

	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(server_source.find("this.rooms.values()") != -1, "Server table list must read active room_manager rooms.")
	_require(server_source.find("[TableList] total_rooms=") != -1, "Server table list must print active room diagnostics.")

	PublicTableRegistryScript.reset()
	print("Public room active registry list test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
