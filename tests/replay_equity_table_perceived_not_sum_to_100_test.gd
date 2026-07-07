extends RefCounted

func run() -> void:
	var docs_source: String = FileAccess.get_file_as_string("res://docs/replay_record_architecture.md")
	var helper_source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(docs_source.find("Perceived rows are independent information sets") != -1)
	assert(docs_source.find("do not need to add up to 100%") != -1)
	assert(helper_source.find("target_seat") != -1)
	assert(helper_source.find("target_hole") != -1)
	assert(helper_source.find("target_seat, \",\".join(hero_hole)") != -1)
