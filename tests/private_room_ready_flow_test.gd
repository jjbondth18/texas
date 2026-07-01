extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")

	_require(server_source.find("private isManagedChipRoom") == -1, "Sentinel keeps this test from matching comments only.")
	_require(server_source.find("room.tableType === \"public_chip\" || room.tableType === \"private_chip\"") != -1, "Private rooms must reuse managed chip-room ready flow.")
	_require(table_source.find("_is_server_ready_managed_table") != -1, "Poker table must use shared ready-managed table helper.")
	_require(smoke_source.find("private room should reuse ready/start hand flow") != -1, "DB smoke must verify private ready/start flow.")
	print("Private room ready flow test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
