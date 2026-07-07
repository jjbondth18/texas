extends RefCounted

func run() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/replay/replay_equity_table.gd")
	assert(source.find("static func _perceived_rows(record: Dictionary, players: Array) -> Array:") != -1)
	assert(source.find("for player_item in players:") != -1)
	assert(source.find("\"preflop\": _perceived_player_equity_label(record, players") != -1)
	assert(source.find("\"river\": _perceived_player_equity_label(record, players") != -1)
	assert(source.find("\"final\": _final_label(player, winner_seats, fold_phase_by_seat)") != -1)
