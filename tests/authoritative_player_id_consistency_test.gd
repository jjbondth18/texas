extends RefCounted

func run() -> void:
	var client_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(client_source.find("server_player_id") != -1)
	assert(client_source.find("is_authenticated_hello") != -1)
	assert(table_source.find("_server_local_identity_id") != -1)
	assert(table_source.find("send_hello(_server_local_player_name, _server_local_identity_id") != -1)
	assert(table_source.find("func _server_local_seat_from_snapshot") != -1)
	assert(table_source.find("String(seat.get(\"player_id\", \"\")) == _server_local_player_id") != -1)
	assert(table_source.find("if is_server_snapshot:") != -1)
	assert(table_source.find("seat[\"player_id\"] = _server_local_player_id") != -1)
