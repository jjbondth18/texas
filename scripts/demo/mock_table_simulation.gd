extends RefCounted
class_name MockTableSimulation

const DeckScript := preload("res://scripts/core/deck.gd")
const PokerPhaseScript := preload("res://scripts/core/poker_phase.gd")
const BettingActionScript := preload("res://scripts/core/betting_action.gd")

static func get_mock_table_snapshot() -> Dictionary:
	var deck = DeckScript.new()
	return {
		"table_id": "mock_table_001",
		"phase": PokerPhaseScript.PREFLOP,
		"deck_count": deck.count(),
		"community_cards": [],
		"pot": 75,
		"seats": [],
		"available_actions": [
			{"id": BettingActionScript.FOLD, "label": "Fold", "enabled": true},
			{"id": BettingActionScript.CALL, "label": "Call 50", "enabled": true, "amount": 50},
			{"id": BettingActionScript.RAISE, "label": "Raise", "enabled": true, "min": 100, "max": 1000},
		],
	}
