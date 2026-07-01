extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/seat_player_card.gd")
	_assert(source.find("const BET_MARKER_ANCHORS_BY_SEAT :=") != -1, "BetMarker anchors must be a seat-index contract.")
	_assert(source.find("const SEAT_PANEL_ORIGINS_BY_SEAT :=") != -1, "BetMarker must be mapped from stable seat panel origins.")
	for seat_id in range(1, 10):
		_assert(source.find("%d: Vector2" % seat_id) != -1, "BetMarker anchor missing for seat %d." % seat_id)
	_assert(source.find("return _bet_marker_offset(card_pos)") != -1, "BetMarker position must use a fixed seat anchor.")
	_assert(source.find("BET_MARKER_ANCHORS_BY_SEAT[_seat_id]") != -1, "BetMarker offset must be selected by seat_id.")
	_assert(source.find("PlayerStatus") == -1, "SeatPlayerCard BetMarker must not depend on PlayerStatus.")
	print("Bet marker anchor contract test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
