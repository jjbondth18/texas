extends RefCounted
class_name ReplayAnalysisState

var replay_id := ""
var street_actions: Array[Dictionary] = []
var equity_timeline: Array[Dictionary] = []
var premium_required := true

func _init(data: Dictionary = {}) -> void:
	replay_id = str(data.get("replay_id", ""))
	street_actions = []
	for action in Array(data.get("street_actions", [])):
		street_actions.append(Dictionary(action))
	equity_timeline = []
	for item in Array(data.get("equity_timeline", [])):
		equity_timeline.append(Dictionary(item))
	premium_required = bool(data.get("premium_required", true))

func to_dict() -> Dictionary:
	return {
		"replay_id": replay_id,
		"street_actions": street_actions.duplicate(true),
		"equity_timeline": equity_timeline.duplicate(true),
		"premium_required": premium_required,
	}

static func mock_default():
	return load("res://scripts/data/replay_analysis_state.gd").new({
		"replay_id": "replay_001",
		"street_actions": [],
		"equity_timeline": [
			{"step": 0, "street": "preflop", "hero_equity": 0.64},
			{"step": 1, "street": "flop", "hero_equity": 0.78},
			{"step": 2, "street": "turn", "hero_equity": 0.31},
			{"step": 3, "street": "river", "hero_equity": 0.0},
		],
		"premium_required": true,
	})
