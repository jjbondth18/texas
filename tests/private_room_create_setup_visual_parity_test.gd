extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(source.contains("CREATE PRIVATE ROOM"), "Private setup must title as CREATE PRIVATE ROOM")
	_require(source.contains("_add_table_setup_mode_switch(column, public_table, selected_mode)"), "Private setup must use the shared tab row")
	_require(source.contains("_add_table_setup_profile_row(column)"), "Private setup must use the shared player info row")
	_require(source.contains("Private casual room. Not listed in public tables."), "Private setup must use private casual subtitle")
	_require(source.contains("Gem private rooms are reserved for future private match support."), "Private Gem must show future support copy")
	_require(source.contains("_private_room_setup_mode = \"gem\""), "Private Gem tab must be selectable")
	_require(source.contains("if _private_room_setup_mode == \"gem\""), "Private Gem create must be guarded")
	print("Private room create setup visual parity test passed.")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
