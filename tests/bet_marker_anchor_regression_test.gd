extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/seat_player_card.gd")
	assert(source.find("const BET_MARKER_OFFSETS") != -1)
	for seat_id in range(0, 10):
		assert(source.find("%d: Vector2" % seat_id) != -1)
	assert(source.find("return BET_MARKER_OFFSETS[_seat_id]") != -1)
	assert(source.find("func _bet_marker_position(card_pos: Vector2)") != -1)
	print("Bet marker anchor regression test passed.")
	quit()
