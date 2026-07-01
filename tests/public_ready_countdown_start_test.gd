extends SceneTree

func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var smoke_source: String = FileAccess.get_file_as_string("res://server/src/smoke_test.ts")

	_require(server_source.find("const READY_COUNTDOWN_MS = 3000") != -1, "Ready countdown should be 3 seconds.")
	_require(server_source.find("private scheduleReadyCountdown(room: Room): void") != -1, "Server must schedule ready countdown.")
	_require(server_source.find("All players ready. Starting in 3...") != -1, "Countdown log message should be explicit.")
	_require(server_source.find("private handleReadyCountdown(roomId: string, token: number): void") != -1, "Countdown completion handler required.")
	_require(server_source.find("this.startOfficialPublicHand(room, \"ready_countdown\")") != -1, "Countdown should auto-start official hand.")
	_require(smoke_source.find("await waitForSnapshot((snapshot) => snapshot.phase === \"preflop\", 5000)") != -1, "Smoke should wait for auto countdown start.")
	print("Public ready countdown start test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
