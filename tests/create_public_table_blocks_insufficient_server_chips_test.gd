extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(source.find("func _confirm_public_table_setup") != -1)
	assert(source.find("if not _can_afford_public_buy_in(buy_in):") != -1)
	assert(source.find("_show_toast(\"Not enough chips for this buy-in.\")") != -1)
	assert(source.find("_profile_ws_client.create_table") != -1)
	assert(source.find("return\n\t_hide_table_creation_setup_panels()") != -1)
