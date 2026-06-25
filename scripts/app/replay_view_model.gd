extends RefCounted
class_name ReplayViewModel

const ReplayRecordScript := preload("res://scripts/data/replay_record.gd")
const ReplayAnalysisStateScript := preload("res://scripts/data/replay_analysis_state.gd")

var summary := {
	"total_replays": 42,
	"free_replay_limit": 5,
	"analysis_unlocked": false,
}

var filters: Array[Dictionary] = [
	{"id": "all", "label": "All"},
	{"id": "wins", "label": "Wins"},
	{"id": "losses", "label": "Losses"},
	{"id": "big_pots", "label": "Big Pots"},
	{"id": "favorites", "label": "Favorites"},
]

var records: Array = []
var selected_replay

func _init(replay_records: Array = [], replay_analysis = null) -> void:
	records = replay_records.duplicate()
	if records.is_empty():
		records = [ReplayRecordScript.mock_default()]
	selected_replay = replay_analysis if replay_analysis != null else ReplayAnalysisStateScript.mock_default()

func to_dict() -> Dictionary:
	var record_data: Array[Dictionary] = []
	for record in records:
		record_data.append(record.to_dict())
	return {
		"summary": summary.duplicate(true),
		"filters": filters.duplicate(true),
		"records": record_data,
		"selected_replay": selected_replay.to_dict(),
	}
