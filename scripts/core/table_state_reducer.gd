extends RefCounted
class_name TableStateReducer

const BettingActionScript := preload("res://scripts/core/betting_action.gd")

static func apply_action(table_state: Dictionary, action: Dictionary) -> Dictionary:
	var next_state := table_state.duplicate(true)
	if not next_state.has("pot"):
		next_state["pot"] = 0
	if not next_state.has("action_history"):
		next_state["action_history"] = []
	if not _is_valid_action(action):
		next_state["last_error"] = "invalid_action_shape"
		return next_state
	var normalized := _normalize_action(action)
	var history: Array = Array(next_state.get("action_history", [])).duplicate(true)
	history.append(normalized)
	next_state["action_history"] = history
	if BettingActionScript.uses_amount(String(normalized["id"])):
		next_state["pot"] = int(next_state.get("pot", 0)) + max(int(normalized.get("amount", 0)), 0)
	next_state.erase("last_error")
	return next_state

static func _is_valid_action(action: Dictionary) -> bool:
	if not BettingActionScript.has_valid_shape(action):
		return false
	return BettingActionScript.is_known(String(action.get("id", "")))

static func _normalize_action(action: Dictionary) -> Dictionary:
	return {
		"id": String(action.get("id", "")),
		"player_id": String(action.get("player_id", "")),
		"amount": int(action.get("amount", 0)),
		"enabled": bool(action.get("enabled", true)),
	}
