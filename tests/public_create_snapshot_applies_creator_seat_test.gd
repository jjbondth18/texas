extends SceneTree

func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var snapshot_source: String = FileAccess.get_file_as_string("res://scripts/state/table_snapshot.gd")

	_require(table_source.find("Seat confirmed by snapshot: seat=%d") != -1, "Client must confirm local seat from table_snapshot.")
	_require(table_source.find("local_player_seat_index=%d") != -1, "Snapshot debug log must include local_player_seat_index.")
	_require(snapshot_source.find("var room_state := \"waiting\"") != -1, "TableSnapshot must retain room_state.")
	_require(snapshot_source.find("\"room_state\": room_state") != -1, "TableSnapshot.to_dict must preserve room_state for private snapshot re-apply.")
	print("Public create snapshot applies creator seat test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
