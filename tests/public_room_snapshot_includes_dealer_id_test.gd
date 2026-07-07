extends SceneTree

func _init() -> void:
	var protocol_source: String = FileAccess.get_file_as_string("res://server/src/protocol.ts")
	var room_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(protocol_source.find("dealer_id?: string") != -1, "protocol snapshots should include dealer_id")
	_require(room_source.find("dealer_id: room.dealerId") != -1, "table snapshots should expose dealer_id")
	_require(room_source.find("table_info: this.tableSnapshot(room)") != -1, "broadcast should include table_info")
	print("Public room snapshot dealer id test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
