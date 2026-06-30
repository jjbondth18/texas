extends RefCounted

func run() -> void:
	var table_source := FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	assert(table_source.find("func _begin_local_public_warmup()") != -1)
	assert(table_source.find("_local_public_warmup_active = true") != -1)
	assert(table_source.find("Local warm-up started.") != -1)
	assert(table_source.find("This does not affect your wallet.") != -1)
	assert(table_source.find("server_authoritative and not _local_public_warmup_active") != -1)
	var docs := FileAccess.get_file_as_string("res://docs/public_table_ai_warmup.md")
	assert(docs.find("separate local practice table") != -1)
