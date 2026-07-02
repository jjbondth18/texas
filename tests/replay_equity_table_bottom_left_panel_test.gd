extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_setup_equity_table_panel") != -1)
	assert(source.find("IdentityZone") != -1)
	assert(source.find("identity_zone.visible = false") != -1)
	assert(source.find("_equity_table_panel.position = Vector2(0, 0)") != -1)
	assert(source.find("_equity_table_panel.size = Vector2(785, 368)") != -1)
