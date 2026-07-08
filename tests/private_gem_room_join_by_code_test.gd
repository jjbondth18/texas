extends SceneTree


func _init() -> void:
	var protocol_source: String = FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(protocol_source.find("create_private_table") != -1, "Protocol must keep private table create command.")
	_require(server_source.find("type: \"private_table_joined\"") != -1, "Server must return private_table_joined for room-code joins.")
	_require(server_source.find("tableType: tableConfig.tableType ?? \"private_chip\"") != -1, "Private room create must preserve private_gem table type from config.")
	print("Private Gem room join by code test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
