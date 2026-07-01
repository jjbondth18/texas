extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/components/seat_player_card.gd")
	_require(source.find("TABLE_POT_CENTER_DESIGN") != -1, "BetMarker contract should document the table pot center.")
	_require(source.find("SEAT_PANEL_ORIGINS_BY_SEAT") != -1, "BetMarker must anchor from fixed seat panel origins.")
	_require(source.find("BET_MARKER_ANCHORS_BY_SEAT") != -1, "BetMarker must use a fixed seat-index anchor table.")
	_require(source.find("design_anchor - seat_origin - position") != -1, "BetMarker position must be converted from fixed design anchors, not dynamic UI nodes.")
	_require(source.find("PlayerStatus") == -1, "BetMarker must not depend on PlayerStatus panel position.")
	for seat_id in range(1, 10):
		_require(source.find("%d: Vector2" % seat_id) != -1, "Missing fixed BetMarker anchor for seat %d." % seat_id)
	print("Bet marker center anchor contract test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
