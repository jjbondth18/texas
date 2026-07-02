extends RefCounted

func run() -> void:
	var screen_source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	var helper_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(screen_source.find("ReplayEquityTableScroll") != -1)
	assert(screen_source.find("scroll.custom_minimum_size = Vector2(730, 132)") != -1)
	assert(screen_source.find("vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO") != -1)
	assert(screen_source.find("_equity_table_panel.size = Vector2(785, 368)") != -1)
	assert(helper_source.find("result.slice(0, min(9, result.size()))") != -1)
