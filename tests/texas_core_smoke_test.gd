extends SceneTree

const DeckScript := preload("res://scripts/core/deck.gd")
const PokerPhaseScript := preload("res://scripts/core/poker_phase.gd")
const BettingActionScript := preload("res://scripts/core/betting_action.gd")
const HandRankScript := preload("res://scripts/core/hand_rank.gd")
const HandEvaluatorScript := preload("res://scripts/core/hand_evaluator.gd")
const TableStateReducerScript := preload("res://scripts/core/table_state_reducer.gd")
const MockTableSimulationScript := preload("res://scripts/demo/mock_table_simulation.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_check_deck()
	_check_constants()
	_check_hand_evaluator()
	_check_mock_table_simulation()
	_check_table_state_reducer()
	if _failures.is_empty():
		print("Texas core smoke test passed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _check_deck() -> void:
	var deck = DeckScript.new()
	_require(deck.count() == 52, "Deck must contain 52 cards.")
	_require(deck.has_unique_codes(), "Deck card codes must be unique.")
	var drawn := deck.draw(2)
	_require(drawn.size() == 2, "Deck draw(2) must return 2 cards.")
	_require(deck.count() == 50, "Drawing 2 cards must reduce deck count to 50.")

func _check_constants() -> void:
	for phase in [PokerPhaseScript.WAITING, PokerPhaseScript.PREFLOP, PokerPhaseScript.FLOP, PokerPhaseScript.TURN, PokerPhaseScript.RIVER, PokerPhaseScript.SHOWDOWN, PokerPhaseScript.FINISHED]:
		_require(PokerPhaseScript.is_known(phase), "Poker phase must exist: %s" % phase)
	for action_id in [BettingActionScript.FOLD, BettingActionScript.CHECK, BettingActionScript.CALL, BettingActionScript.BET, BettingActionScript.RAISE, BettingActionScript.ALL_IN, BettingActionScript.SMALL_BLIND, BettingActionScript.BIG_BLIND, BettingActionScript.SIT_OUT]:
		_require(BettingActionScript.is_known(action_id), "Betting action must exist: %s" % action_id)
	for rank_id in [HandRankScript.HIGH_CARD, HandRankScript.ONE_PAIR, HandRankScript.TWO_PAIR, HandRankScript.THREE_OF_A_KIND, HandRankScript.STRAIGHT, HandRankScript.FLUSH, HandRankScript.FULL_HOUSE, HandRankScript.FOUR_OF_A_KIND, HandRankScript.STRAIGHT_FLUSH, HandRankScript.ROYAL_FLUSH]:
		_require(HandRankScript.is_known(rank_id), "Hand rank must exist: %s" % rank_id)

func _check_hand_evaluator() -> void:
	var result := HandEvaluatorScript.evaluate(["AS", "AD", "7C", "5H", "2S"])
	_require(result.get("rank") == HandRankScript.ONE_PAIR, "Evaluator must detect one pair for AA752.")
	_require(result.get("rank_value") == HandRankScript.value(HandRankScript.ONE_PAIR), "Evaluator rank value must match one pair.")

func _check_mock_table_simulation() -> void:
	var snapshot := MockTableSimulationScript.get_mock_table_snapshot()
	for field in ["table_id", "phase", "pot", "seats", "available_actions"]:
		_require(snapshot.has(field), "Mock table snapshot must include %s." % field)
	_require(snapshot.get("deck_count") == 52, "Mock table snapshot deck_count must be 52.")

func _check_table_state_reducer() -> void:
	var original := {
		"table_id": "mock_table_001",
		"pot": 75,
		"action_history": [],
	}
	var action := BettingActionScript.make(BettingActionScript.CALL, "player_1", 50, true)
	var next_state := TableStateReducerScript.apply_action(original, action)
	_require(int(original.get("pot")) == 75, "Reducer must not mutate original table_state pot.")
	_require(int(next_state.get("pot")) == 125, "Reducer must add call amount to pot.")
	_require(Array(next_state.get("action_history", [])).size() == 1, "Reducer must append action history.")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
