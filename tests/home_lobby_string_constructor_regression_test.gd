extends SceneTree


func _init() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var connected_start: int = source.find("func _connected_room_player_count")
	assert(connected_start != -1)
	var connected_end: int = source.find("func _is_connected_room_player", connected_start)
	assert(connected_end != -1)
	var connected_body: String = source.substr(connected_start, connected_end - connected_start)
	assert(connected_body.find("String(") == -1)
	assert(source.find("String(") == -1)
	assert(connected_body.find("str(seat.get(\"player_id\"") != -1)
	print("Home lobby String constructor regression test passed.")
	quit()
