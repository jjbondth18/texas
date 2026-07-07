extends SceneTree

func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	_require(source.find("dealerId: string") != -1, "Room should store a stable dealerId")
	_require(source.find("dealerId: normalizeDealerId(options.dealerId || randomDealerId())") != -1, "room creation should assign a dealer id")
	_require(source.find("const DEALER_IDS") != -1, "server should whitelist dealer ids")
	print("Room create dealer id test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
