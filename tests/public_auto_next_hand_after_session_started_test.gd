extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/smoke_test.ts")

	_require(server_source.find("officialHandStarted") != -1, "Room must track official session started.")
	_require(server_source.find("private scheduleHandResultTransition(room: Room): void") != -1, "Hand result transition timer required.")
	_require(server_source.find("this.startOfficialPublicHand(room, \"auto_next_hand\")") != -1, "Server should auto-start next hand after result window.")
	_require(smoke_source.find("snapshot.hand_id === finalSnapshot.hand_id + 1 && snapshot.phase === \"preflop\", 9000") != -1, "Smoke should verify auto next hand.")
	print("Public auto next hand after session started test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
