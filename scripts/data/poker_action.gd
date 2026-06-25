extends RefCounted
class_name PokerAction

const FOLD := "fold"
const CHECK := "check"
const CALL := "call"
const RAISE := "raise"
const BET := "bet"
const ALL_IN := "all_in"

var id := ""
var label := ""
var enabled := true
var amount := 0
var min_amount := 0
var max_amount := 0

func _init(action_id: String = "", action_label: String = "", is_enabled: bool = true) -> void:
	id = action_id
	label = action_label
	enabled = is_enabled

func to_dict() -> Dictionary:
	var data := {
		"id": id,
		"label": label,
		"enabled": enabled,
	}
	if amount > 0:
		data["amount"] = amount
	if min_amount > 0:
		data["min"] = min_amount
	if max_amount > 0:
		data["max"] = max_amount
	return data

static func from_dict(data: Dictionary):
	var action = load("res://scripts/data/poker_action.gd").new(
		String(data.get("id", "")),
		String(data.get("label", "")),
		bool(data.get("enabled", true))
	)
	action.amount = int(data.get("amount", 0))
	action.min_amount = int(data.get("min", 0))
	action.max_amount = int(data.get("max", 0))
	return action
