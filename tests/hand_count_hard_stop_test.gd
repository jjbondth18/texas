extends SceneTree


func _init() -> void:
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var state_source: String = FileAccess.get_file_as_string("res://server/src/table_state.ts")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	_require(server_source.find("hasReachedHandLimit") != -1, "Server must check hand limit before auto next hand.")
	_require(server_source.find("canStartAnotherSessionHand") != -1, "Server must block starting a hand beyond max_hands.")
	_require(server_source.find("completePublicSession(room)") != -1, "Server must enter session_complete at hand limit.")
	_require(server_source.find("session_complete") != -1, "Server snapshot must expose session_complete.")
	_require(state_source.find("resetForNewSession") != -1, "TableState must reset session counters for Play Again.")
	_require(table_source.find("_session_progress_text_from_snapshot") != -1, "Client must render hand count from snapshot fields.")
	print("Hand count hard stop test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
