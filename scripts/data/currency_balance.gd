extends RefCounted
class_name CurrencyBalance

var chips := 0
var gems := 0

func _init(initial_chips: int = 0, initial_gems: int = 0) -> void:
	chips = initial_chips
	gems = initial_gems

func to_dict() -> Dictionary:
	return {
		"chips": chips,
		"gems": gems,
	}

static func from_dict(data: Dictionary):
	return load("res://scripts/data/currency_balance.gd").new(
		int(data.get("chips", 0)),
		int(data.get("gems", 0))
	)
