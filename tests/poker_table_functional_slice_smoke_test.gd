extends SceneTree

const MockTableSimulation := preload("res://scripts/demo/mock_table_simulation.gd")

func _init() -> void:
	var preflop := MockTableSimulation.get_phase_snapshot("preflop")
	_assert(Array(preflop.get("seats", [])).size() == 9, "snapshot must have 9 seats")
	_assert(Dictionary(preflop.get("local_player", {})).get("seat_index") == 5, "local seat must be seat 5")
	_assert(MockTableSimulation.visual_position_for_seat_index(5, 5) == 5, "local visual position must be Seat 5")
	_assert(Array(preflop.get("community_cards", [])).size() == 0, "preflop must have 0 board cards")
	_assert(Array(MockTableSimulation.get_phase_snapshot("flop").get("community_cards", [])).size() == 3, "flop must have 3 cards")
	_assert(Array(MockTableSimulation.get_phase_snapshot("turn").get("community_cards", [])).size() == 4, "turn must have 4 cards")
	_assert(Array(MockTableSimulation.get_phase_snapshot("river").get("community_cards", [])).size() == 5, "river must have 5 cards")
	_assert(Array(MockTableSimulation.get_phase_snapshot("showdown").get("community_cards", [])).size() == 5, "showdown must have 5 cards")
	_assert(Array(Dictionary(preflop.get("local_player", {})).get("cards", [])).size() == 2, "local player must have 2 cards")
	_assert(_actions_are_valid(Array(preflop.get("available_actions", []))), "available action data invalid")

	var original_pot := int(preflop.get("pot", 0))
	var folded := MockTableSimulation.apply_mock_action(preflop, {"id": "fold", "player_id": "player_005", "enabled": true})
	_assert(_local_status(folded) == "folded", "fold must change local status")
	_assert(_local_status(preflop) != "folded", "input snapshot was mutated by fold")

	var called := MockTableSimulation.apply_mock_action(preflop, {"id": "call", "player_id": "player_005", "amount": 50, "enabled": true})
	_assert(int(called.get("pot", 0)) == original_pot + 50, "call must increase pot")
	var raised := MockTableSimulation.apply_mock_action(preflop, {"id": "raise", "player_id": "player_005", "amount": 150, "enabled": true})
	_assert(int(raised.get("pot", 0)) == original_pot + 150, "raise must increase pot")

	print("Poker table functional slice smoke test passed.")
	quit(0)

func _actions_are_valid(actions: Array) -> bool:
	if actions.is_empty():
		return false
	for item in actions:
		var action := Dictionary(item)
		if not action.has("id") or not action.has("label") or not action.has("enabled"):
			return false
	return true

func _local_status(snapshot: Dictionary) -> String:
	for seat in Array(snapshot.get("seats", [])):
		var data := Dictionary(seat)
		if bool(data.get("is_local", false)):
			return String(data.get("status", ""))
	return ""

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
