extends SceneTree

func _init() -> void:
	var home_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_context_source: String = FileAccess.get_file_as_string("res://scripts/app/table_launch_context.gd")
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var server_source: String = FileAccess.get_file_as_string("res://server/src/room_manager.ts")

	var created_body: String = _function_body(home_source, "func _on_server_table_created")
	var joined_body: String = _function_body(home_source, "func _on_server_table_joined")
	var open_body: String = _function_body(home_source, "func _open_server_table")
	var context_body: String = _function_body(home_source, "func _server_table_context")

	_require(created_body.find("_open_server_table(room_id, table_info, 5)") != -1, "Browser create should request objective creator seat 5.")
	_require(joined_body.find("_open_server_table(room_id, table_info, -1)") != -1, "Browser join should request server auto-seat, not fixed seat 0.")
	_require(open_body.find("requested_seat_index: int") != -1, "Server table open path must carry a requested seat index.")
	_require(context_body.find("\"requested_seat_index\": requested_seat_index") != -1, "Launch context must include requested_seat_index.")

	_require(table_context_source.find("static var requested_seat_index") != -1, "TableLaunchContext must persist requested_seat_index.")
	_require(table_context_source.find("\"requested_seat_index\": requested_seat_index") != -1, "TableLaunchContext snapshot must expose requested_seat_index.")
	_require(table_source.find("_server_requested_seat_index = int(TableLaunchContext.requested_seat_index)") != -1, "Poker table should use launch context requested seat.")
	_require(table_source.find("_poker_ws_client.sit_down(_server_requested_seat_index") != -1, "Poker table should send requested seat to server.")

	_require(server_source.find("firstAvailablePublicSeat(room)") != -1, "Server must auto-pick objective public seat for seat_index -1.")
	_require(server_source.find("const PUBLIC_SEAT_JOIN_ORDER = [5, 8, 2, 6, 4, 9, 1, 7, 3]") != -1, "Server must keep objective public seat order.")
	_require(server_source.find("return seatIndex;") != -1, "Server sitDownWithWallet must return the accepted seat.")
	_require(server_source.find("seat_index: acceptedSeatIndex") != -1, "sit_down_result must report the accepted seat index.")

	print("Browser join available seat test passed.")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start: int = source.find(signature)
	if start < 0:
		return ""
	var next_func: int = source.find("\nfunc ", start + signature.length())
	if next_func < 0:
		return source.substr(start)
	return source.substr(start, next_func - start)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
