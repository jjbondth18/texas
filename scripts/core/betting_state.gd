extends RefCounted
class_name BettingState

var current_bet := 0
var min_raise := 0
var pot := 0
var player_bets: Dictionary = {}

func _init(initial_pot: int = 0, initial_current_bet: int = 0, initial_min_raise: int = 0) -> void:
	pot = initial_pot
	current_bet = initial_current_bet
	min_raise = initial_min_raise

func apply_amount(player_id: String, amount: int) -> void:
	var safe_amount = max(amount, 0)
	pot += safe_amount
	player_bets[player_id] = int(player_bets.get(player_id, 0)) + safe_amount
	current_bet = max(current_bet, int(player_bets[player_id]))

func to_dict() -> Dictionary:
	return {
		"current_bet": current_bet,
		"min_raise": min_raise,
		"pot": pot,
		"player_bets": player_bets.duplicate(true),
	}

static func from_dict(data: Dictionary):
	var state = load("res://scripts/core/betting_state.gd").new(
		int(data.get("pot", 0)),
		int(data.get("current_bet", 0)),
		int(data.get("min_raise", 0))
	)
	state.player_bets = Dictionary(data.get("player_bets", {})).duplicate(true)
	return state
