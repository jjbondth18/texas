extends SceneTree

const MockTableSimulation := preload("res://scripts/demo/mock_table_simulation.gd")


func _init() -> void:
	var waiting: Dictionary = MockTableSimulation.reset_table()
	_assert(String(waiting.get("phase", "")) == "waiting", "table must reset to waiting")
	_assert(Array(waiting.get("seats", [])).size() == 9, "waiting snapshot must contain seats")
	_assert(String(waiting.get("room_state", "")) == "waiting", "room state must be waiting")

	var hand: Dictionary = MockTableSimulation.start_test_hand(waiting, 321)
	_assert(String(hand.get("phase", "")) in ["preflop", "flop", "turn", "river", "showdown", "finished"], "hand must start")
	_assert(int(hand.get("pot", 0)) >= 75, "blinds must create pot")
	_assert(Array(Dictionary(hand.get("local_player", {})).get("cards", [])).size() == 2, "local player must receive hole cards")
	_assert(String(hand.get("room_state", "")) in ["in_hand", "showdown", "hand_over"], "room state must enter hand")

	var advanced: Dictionary = MockTableSimulation.advance_stage(hand)
	_assert(String(advanced.get("phase", "")) in ["flop", "turn", "river", "showdown", "finished"], "advance must move hand forward")

	var showdown: Dictionary = MockTableSimulation.force_showdown(advanced)
	_assert(String(showdown.get("phase", "")) in ["showdown", "finished"], "force showdown must reach showdown/finished")
	_assert(Array(showdown.get("community_cards", [])).size() == 5, "showdown must have five board cards")
	_assert(Array(showdown.get("winners", [])).size() >= 1, "showdown must produce a winner")
	_assert(int(showdown.get("pot", 0)) == 0, "pot must be awarded at hand end")
	_assert(Array(showdown.get("hand_history", [])).size() > 0, "table log history must be populated")

	print("Poker hand flow v1 smoke test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
