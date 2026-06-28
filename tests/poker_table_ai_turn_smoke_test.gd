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
	await create_timer(1.35).timeout

	var snapshot: Dictionary = Dictionary(screen.get("snapshot"))
	var local_seat: int = int(snapshot.get("local_seat_index", 5))
	var turn_seat: int = int(snapshot.get("turn_seat_index", -1))
	var history: Array = Array(snapshot.get("hand_history", []))
	_assert(turn_seat == local_seat, "AI should act until local player's turn")
	_assert(_history_has_ai_action(history), "AI action should be written to table log")

	print("Poker table AI turn smoke test passed.")
	quit(0)


func _history_has_ai_action(history: Array) -> bool:
	for item in history:
		var text: String = String(item)
		if text.find("Seat 4") != -1 and (text.find("calls") != -1 or text.find("folds") != -1 or text.find("raises") != -1 or text.find("bets") != -1 or text.find("all-in") != -1):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
