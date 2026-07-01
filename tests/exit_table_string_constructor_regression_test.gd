extends SceneTree


func _init() -> void:
	var ws_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(ws_source.find("String(") == -1)
	assert(table_source.find("func _return_home()") != -1)
	assert(table_source.find("_server_leave_return_pending") != -1)
	print("Exit table String constructor regression test passed.")
	quit()
