extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("No equity data.") != -1)
	assert(source.find('return "not_recorded"') != -1)
	assert(source.find('return "Not Recorded"') != -1)
	assert(source.find("_objective_value_label") != -1)
	assert(source.find("_can_rebuild_objective") != -1)
	assert(source.find('str(action.get("street", "")).strip_edges() == ""') != -1)
	assert(source.find("players.is_empty()") != -1)
	assert(source.find("hole_cards.size() != 2") != -1)
