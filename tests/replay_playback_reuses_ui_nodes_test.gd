extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_setup_replay_visual_shell()") != -1)
	assert(source.find("_setup_equity_table_panel()") != -1)
	assert(source.find("_equity_rendered_mode == _equity_mode and not _equity_cells.is_empty()") != -1)
	assert(source.find("_set_bottom_hole_cards") != -1)
	assert(source.find("_community_board.set_cards") != -1)
