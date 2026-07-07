extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("_equity_table_panel.size = Vector2(740, 368)") != -1)
	assert(source.find("margin.add_theme_constant_override(\"margin_left\", 18)") != -1)
	assert(source.find("margin.add_theme_constant_override(\"margin_right\", 18)") != -1)
	assert(source.find("{\"key\": \"seat\", \"label\": \"Seat\", \"width\": 48}") != -1)
	assert(source.find("{\"key\": \"player\", \"label\": \"Player\", \"width\": 140}") != -1)
	assert(source.find("{\"key\": \"preflop\", \"label\": \"Preflop\", \"width\": 90}") != -1)
	assert(source.find("{\"key\": \"flop\", \"label\": \"Flop\", \"width\": 84}") != -1)
	assert(source.find("{\"key\": \"final\", \"label\": \"Final\", \"width\": 88}") != -1)
	assert(source.find("cell.custom_minimum_size = Vector2(width, 30 if not is_header else 32)") != -1)
	assert(source.find("HomeTheme.make_font_settings(label, 13 if not is_header else 14") != -1)
	assert(source.find("scroll.custom_minimum_size = Vector2(704, 136)") != -1)
	assert(source.find("vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO") != -1)
	assert(source.find("return name.substr(0, 10) + \"...\" if name.length() > 13 else name") != -1)
