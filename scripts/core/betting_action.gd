extends RefCounted
class_name BettingAction

const FOLD := "fold"
const CHECK := "check"
const CALL := "call"
const BET := "bet"
const RAISE := "raise"
const ALL_IN := "all_in"
const SMALL_BLIND := "small_blind"
const BIG_BLIND := "big_blind"
const SIT_OUT := "sit_out"

const AMOUNT_ACTIONS := [
	CALL,
	BET,
	RAISE,
	ALL_IN,
	SMALL_BLIND,
	BIG_BLIND,
]

const ALL_ACTIONS := [
	FOLD,
	CHECK,
	CALL,
	BET,
	RAISE,
	ALL_IN,
	SMALL_BLIND,
	BIG_BLIND,
	SIT_OUT,
]

static func is_known(action_id: String) -> bool:
	return ALL_ACTIONS.has(action_id)

static func uses_amount(action_id: String) -> bool:
	return AMOUNT_ACTIONS.has(action_id)

static func make(action_id: String, player_id: String, amount: int = 0, enabled: bool = true) -> Dictionary:
	return {
		"id": action_id,
		"player_id": player_id,
		"amount": amount,
		"enabled": enabled,
	}

static func has_valid_shape(action: Dictionary) -> bool:
	return action.has("id") and action.has("player_id") and action.has("enabled")
