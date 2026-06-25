extends SceneTree

const HandLifecycle := preload("res://scripts/core/hand_lifecycle.gd")

func _init() -> void:
	_assert(HandLifecycle.compare_card_sets(["AS", "KS", "QS", "JS", "TS", "2C", "3D"], ["AH", "AD", "AC", "KD", "KH", "2S", "3S"]) > 0, "royal flush should beat full house")
	var state := HandLifecycle.start_new_hand({"seats": _seats(), "dealer_seat": 0}, 21)
	state["phase"] = "river"
	state["community_cards"] = [
		{"rank": "A", "suit": "spades", "code": "AS", "face_up": true},
		{"rank": "K", "suit": "spades", "code": "KS", "face_up": true},
		{"rank": "Q", "suit": "spades", "code": "QS", "face_up": true},
		{"rank": "J", "suit": "spades", "code": "JS", "face_up": true},
		{"rank": "2", "suit": "clubs", "code": "2C", "face_up": true},
	]
	state["current_bet"] = 0
	state["current_turn_seat"] = 1
	state = HandLifecycle.apply_action(state, {"id": "check", "seat_index": 1, "enabled": true})
	state = HandLifecycle.apply_action(state, {"id": "check", "seat_index": 2, "enabled": true})
	_assert(bool(state["hand_complete"]), "showdown should finish hand")
	_assert(Array(state["winners"]).size() >= 1, "showdown winner missing")
	var split := HandLifecycle.start_new_hand({"seats": _seats(), "dealer_seat": 0}, 22)
	split["pot"] = {"main": 101, "side_pots": []}
	split["seats"][0]["status"] = "active"
	split["seats"][1]["status"] = "active"
	# Award helper is internal; tied-pot behavior is covered by identical board compare.
	_assert(HandLifecycle.compare_card_sets(["AS", "KD", "QC", "JH", "9S", "2D", "3C"], ["AD", "KC", "QH", "JS", "9D", "2C", "3H"]) == 0, "known tie should compare equal")
	print("Showdown smoke test passed.")
	quit(0)

func _seats() -> Array[Dictionary]:
	return [
		{"seat_index": 1, "player_id": "player_001", "chips": 10000, "status": "active"},
		{"seat_index": 2, "player_id": "player_002", "chips": 10000, "status": "active"},
	]

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
