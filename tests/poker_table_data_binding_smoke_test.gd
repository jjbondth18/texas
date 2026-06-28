extends SceneTree

const PokerTableScene := preload("res://scenes/screens/poker_table_screen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen = PokerTableScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen.call("_start_test_hand")
	await process_frame

	var snapshot: Dictionary = Dictionary(screen.get("snapshot"))
	var seats: Array = Array(snapshot.get("seats", []))
	var local_player: Dictionary = Dictionary(snapshot.get("local_player", {}))
	var sb_found: bool = false
	var bb_found: bool = false

	_assert(int(snapshot.get("pot", 0)) == 75, "pot must bind to 75 after blinds")
	_assert(Array(local_player.get("cards", [])).size() == 2, "local hole cards must bind")
	_assert(Array(snapshot.get("hand_history", [])).size() > 0, "table log must bind")
	for seat in seats:
		var data: Dictionary = Dictionary(seat)
		if bool(data.get("is_small_blind", false)):
			sb_found = true
		if bool(data.get("is_big_blind", false)):
			bb_found = true
	_assert(sb_found, "SB badge data must be present")
	_assert(bb_found, "BB badge data must be present")

	print("Poker table data binding smoke test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
