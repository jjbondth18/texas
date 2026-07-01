extends SceneTree


func _init() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var action_bar_source := FileAccess.get_file_as_string("res://scripts/components/action_bar.gd")
	var status_source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	var room_info_source := FileAccess.get_file_as_string("res://scripts/components/table_room_info_panel.gd")
	assert(table_source.find("func _sync_action_timer_from_snapshot") != -1)
	assert(table_source.find("func _update_action_timer_ui") != -1)
	assert(table_source.find("func _handle_local_action_timeout") != -1)
	assert(action_bar_source.find("func set_action_timer") != -1)
	assert(status_source.find("func set_action_timer") != -1)
	assert(room_info_source.find("func set_action_timer") != -1)
	assert(table_source.find("timed out. Auto-%s.") != -1)
	print("Action timer UI smoke test passed.")
	quit()
