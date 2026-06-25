extends RefCounted
class_name DailyBonusState

var current_day := 1
var days: Array[Dictionary] = []

func _init(active_day: int = 1, bonus_days: Array[Dictionary] = []) -> void:
	current_day = active_day
	days = bonus_days.duplicate(true)

func to_dict() -> Dictionary:
	return {
		"current_day": current_day,
		"days": days.duplicate(true),
	}

static func from_dict(data: Dictionary):
	return load("res://scripts/data/daily_bonus_state.gd").new(
		int(data.get("current_day", 1)),
		Array(data.get("days", []))
	)
