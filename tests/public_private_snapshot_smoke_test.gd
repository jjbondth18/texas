extends SceneTree

const HandLifecycle := preload("res://scripts/core/hand_lifecycle.gd")

func _init() -> void:
	var state := HandLifecycle.start_new_hand({"seats": _seats(), "dealer_seat": 0}, 31)
	var public := HandLifecycle.build_public_snapshot(state)
	var private := HandLifecycle.build_private_snapshot(state, "player_001")
	_assert(_visible_card_count(public, "player_002") == 0, "public snapshot must hide opponent cards")
	_assert(_visible_card_count(private, "player_001") == 2, "private snapshot must show own cards")
	_assert(_visible_card_count(private, "player_002") == 0, "private snapshot must hide other players")
	print("Public/private snapshot smoke test passed.")
	quit(0)

func _seats() -> Array[Dictionary]:
	return [
		{"seat_index": 1, "player_id": "player_001", "chips": 10000, "status": "active"},
		{"seat_index": 2, "player_id": "player_002", "chips": 10000, "status": "active"},
	]

func _visible_card_count(snapshot: Dictionary, player_id: String) -> int:
	for seat in Array(snapshot["seats"]):
		var data := Dictionary(seat)
		if String(data["player_id"]) == player_id:
			var count := 0
			for card in Array(data["cards"]):
				if bool(Dictionary(card).get("face_up", false)):
					count += 1
			return count
	return -1

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
