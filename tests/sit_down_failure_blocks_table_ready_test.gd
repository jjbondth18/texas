extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(source.find("Failed to sit down at table.") != -1)
	assert(source.find("_server_sit_down_failed = true") != -1)
	assert(source.find("_server_local_seat_index = -1") != -1)
	assert(source.find("Cannot start hand: waiting for seat confirmation.") != -1)
	assert(source.find("Waiting for seat confirmation...") != -1)
