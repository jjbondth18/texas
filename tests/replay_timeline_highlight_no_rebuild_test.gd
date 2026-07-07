extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/screens/replay_poker_table_screen.gd")
	assert(source.find("var _timeline_action_lines: Array = []") != -1)
	assert(source.find("func _build_timeline_cache() -> void:") != -1)
	assert(source.find("func _update_timeline_highlight(_current_step_index: int) -> void:") != -1)
	assert(source.find("if not _timeline_built:") != -1)
	assert(source.find("_log_panel.set_info(_timeline_action_lines, _timeline_event_lines)") != -1)
