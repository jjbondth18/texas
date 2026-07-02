extends RefCounted
class_name ReplayService

const ReplayRecordScript := preload("res://scripts/data/replay_record.gd")
const ReplayViewModelScript := preload("res://scripts/app/replay_view_model.gd")
const ReplayRepositoryScript := preload("res://scripts/replay/replay_repository.gd")

func get_replay_view_model() -> Dictionary:
	var records: Array = []
	for entry_item in ReplayRepositoryScript.load_index_entries():
		var entry: Dictionary = Dictionary(entry_item)
		records.append(ReplayRecordScript.new({
			"replay_id": str(entry.get("hand_id", "")),
			"file_path": str(entry.get("file_path", "")),
			"played_at": str(entry.get("ended_at", "")),
			"mode": _mode_label(str(entry.get("mode", ""))),
			"table_name": str(entry.get("summary", "")),
			"result": str(entry.get("player_result", "")),
			"net_chips": int(entry.get("profit", 0)),
			"hero_cards": [],
			"final_board": [],
			"biggest_pot": 0,
			"analysis_available": false,
			"analysis_locked": false,
			"favorite": false,
		}))
	return ReplayViewModelScript.new(records, null, false).to_dict()

func load_replay_record(file_path: String) -> Dictionary:
	return ReplayRepositoryScript.load_hand_record(file_path)

func _mode_label(mode: String) -> String:
	match mode:
		"public":
			return "Public Table"
		"private":
			return "Private Room"
		"training":
			return "Training"
		"local_warmup":
			return "Local Warm-up"
	return "Table"
