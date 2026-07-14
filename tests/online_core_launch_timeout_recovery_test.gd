extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")

	_assert_contains(home_source, "const TABLE_LAUNCH_TIMEOUT_SECONDS := 12", "Home launch timeout constant is 12 seconds")
	_assert_contains(home_source, "_begin_server_table_launch_request", "Home has unified launch request state")
	_assert_contains(home_source, "_table_launch_request_id", "Home stores launch request id")
	_assert_contains(home_source, "_update_table_launch_timeout()", "Home checks launch timeout in process")
	_assert_contains(home_source, "Connection timed out. Please try again.", "Home timeout message is explicit")
	_assert_contains(home_source, "if request_id != \"\" and request_id != _table_launch_request_id:", "Home drops stale server errors")
	_assert_contains(home_source, "not _is_current_table_launch_request(request_id, \"table_joined\")", "Home drops stale table joined responses")
	_assert_contains(home_source, "not _is_current_table_launch_request(request_id, \"table_created\")", "Home drops stale table created responses")
	_assert_contains(home_source, "_cancel_table_launch_request(\"Connection lost. Please try again.\")", "Home cancels launch on websocket disconnect")
	_assert_contains(home_source, "TableLaunchContext.clear_table_session()", "Home clears launch context on launch failure")
	_assert_contains(home_source, "_profile_ws_client.quick_join_table(quick_config, request_id)", "Quick sends request id")
	_assert_contains(home_source, "_profile_ws_client.join_table(room_id, request_id)", "Browser join sends request id")
	_assert_contains(home_source, "_profile_ws_client.create_table(", "Browser create remains wired")
	_assert_contains(home_source, "_profile_ws_client.create_private_table(_private_room_server_config_from_values(), request_id)", "Friends create sends request id")
	_assert_contains(home_source, "_profile_ws_client.join_private_table(room_code, request_id)", "Friends join sends request id")

	_assert_contains(protocol_source, "static func quick_join_table(config: Dictionary = {}, request_id: String = \"\")", "Protocol quick supports request id")
	_assert_contains(protocol_source, "static func create_table(table_name: String = \"\", config: Dictionary = {}, request_id: String = \"\")", "Protocol create supports request id")
	_assert_contains(protocol_source, "static func join_table(room_id: String, request_id: String = \"\")", "Protocol join supports request id")
	_assert_contains(protocol_source, "static func create_private_table(config: Dictionary = {}, request_id: String = \"\")", "Protocol private create supports request id")
	_assert_contains(protocol_source, "static func join_private_table(room_code: String, request_id: String = \"\")", "Protocol private join supports request id")

	_assert_contains(ws_source, "signal table_created(room_id: String, table_info: Dictionary, request_id: String)", "Ws table_created carries request id")
	_assert_contains(ws_source, "signal table_joined(room_id: String, table_info: Dictionary, request_id: String)", "Ws table_joined carries request id")
	_assert_contains(ws_source, "signal server_error(message: String, request_id: String)", "Ws server_error carries request id")
	_assert_contains(ws_source, "server_error.emit(str(message.get(\"error_code\", message.get(\"error\", \"Unknown server error\"))), str(message.get(\"request_id\", \"\")))", "Ws error emits request id")

	_assert_contains(table_source, "const TABLE_BOOT_TIMEOUT_SECONDS := 15", "Poker table boot timeout is 15 seconds")
	_assert_contains(table_source, "_update_server_boot_timeout()", "Poker table checks boot timeout")
	_assert_contains(table_source, "_send_server_message(_poker_ws_client.cash_out(), \"cash_out after boot timeout\")", "Boot timeout requests cash_out if sit_down may have happened")
	_assert_contains(table_source, "_mark_server_boot_complete(\"reconnected_to_table\")", "Reconnect cancels boot timeout")
	_assert_contains(table_source, "_mark_server_boot_complete(\"sit_down accepted\")", "Sit down ack cancels boot timeout")
	_assert_contains(table_source, "_mark_server_boot_complete(\"table snapshot\")", "Table snapshot cancels boot timeout")
	_assert_contains(table_source, "_server_sit_down_requested = false", "Reconnect branch avoids duplicate sit_down")

	print("ONLINE_CORE_LAUNCH_TIMEOUT_RECOVERY_TEST_OK")
	quit(0)

func _assert_contains(source: String, needle: String, message: String) -> void:
	if source.find(needle) == -1:
		push_error("%s: missing '%s'" % [message, needle])
		quit(1)
