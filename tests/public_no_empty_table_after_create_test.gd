extends SceneTree

func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var action_bar_source: String = FileAccess.get_file_as_string("res://scripts/components/action_bar.gd")

	_require(table_source.find("_server_joining_local_player_placeholder") != -1, "Unconfirmed table should render a Joining table placeholder instead of broken local data.")
	_require(table_source.find("snapshot has no occupied seats") != -1, "Client should log empty snapshots explicitly.")
	_require(action_bar_source.find("initials_label.text = display_name.substr(0, 1).to_upper()") != -1, "Bottom panel initials should follow display name instead of stale L.")
	print("Public no empty table after create test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
