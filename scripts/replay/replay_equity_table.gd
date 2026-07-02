extends RefCounted
class_name ReplayEquityTable

const HandEvaluatorScript := preload("res://scripts/core/hand_evaluator.gd")

const MODE_OBJECTIVE := "objective"
const MODE_PERCEIVED := "perceived"
const PHASES := ["preflop", "flop", "turn", "river"]
const MONTE_CARLO_TRIALS := 220
const PERCEIVED_MONTE_CARLO_TRIALS := 1200


static func build_table(record: Dictionary, active_phase: String, mode: String = MODE_OBJECTIVE, hero_seat: int = -1) -> Dictionary:
	var normalized_mode: String = MODE_PERCEIVED if mode == MODE_PERCEIVED else MODE_OBJECTIVE
	var players: Array = _sorted_players(Array(record.get("players", [])))
	var rows: Array = []
	if players.is_empty():
		return {"active_phase": _normalized_phase(active_phase), "mode": normalized_mode, "hero_seat": -1, "hero_name": "-", "rows": rows, "message": "No equity data."}

	var resolved_hero_seat: int = _resolve_hero_seat(players, hero_seat)
	var hero_name: String = _player_name_for_seat(players, resolved_hero_seat)
	if normalized_mode == MODE_PERCEIVED:
		rows = _perceived_rows(record, players, resolved_hero_seat)
	else:
		rows = _objective_rows(record, players)

	return {
		"active_phase": _normalized_phase(active_phase),
		"mode": normalized_mode,
		"hero_seat": resolved_hero_seat,
		"hero_name": hero_name,
		"rows": rows,
		"message": "",
	}


static func _objective_rows(record: Dictionary, players: Array) -> Array:
	var community: Dictionary = Dictionary(record.get("community_cards", {}))
	var results: Dictionary = Dictionary(record.get("results", {}))
	var winner_seats: Array[int] = _winner_seats(results)
	var fold_phase_by_seat: Dictionary = _fold_phase_by_seat(Array(record.get("actions", [])))
	var rows: Array = []

	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var seat_index: int = int(player.get("seat_index", -1))
		rows.append({
			"seat": seat_index,
			"player": str(player.get("player_name", player.get("player_id", "Seat %d" % seat_index))),
			"preflop": _objective_equity_label(record, players, community, fold_phase_by_seat, "preflop", seat_index),
			"flop": _objective_equity_label(record, players, community, fold_phase_by_seat, "flop", seat_index),
			"turn": _objective_equity_label(record, players, community, fold_phase_by_seat, "turn", seat_index),
			"river": _objective_equity_label(record, players, community, fold_phase_by_seat, "river", seat_index),
			"final": _final_label(player, winner_seats, fold_phase_by_seat),
		})
	return rows


static func _perceived_rows(record: Dictionary, players: Array, hero_seat: int) -> Array:
	var hero: Dictionary = _player_for_seat(players, hero_seat)
	if hero.is_empty():
		return []
	var community: Dictionary = Dictionary(record.get("community_cards", {}))
	var results: Dictionary = Dictionary(record.get("results", {}))
	var winner_seats: Array[int] = _winner_seats(results)
	var fold_phase_by_seat: Dictionary = _fold_phase_by_seat(Array(record.get("actions", [])))
	var hero_name: String = str(hero.get("player_name", hero.get("player_id", "Seat %d" % hero_seat)))

	var hero_row: Dictionary = {
		"seat": hero_seat,
		"player": hero_name,
		"preflop": _perceived_hero_equity_label(record, players, community, fold_phase_by_seat, "preflop", hero_seat),
		"flop": _perceived_hero_equity_label(record, players, community, fold_phase_by_seat, "flop", hero_seat),
		"turn": _perceived_hero_equity_label(record, players, community, fold_phase_by_seat, "turn", hero_seat),
		"river": _perceived_hero_equity_label(record, players, community, fold_phase_by_seat, "river", hero_seat),
		"final": _perceived_final_label(hero_seat, winner_seats, fold_phase_by_seat, true),
	}
	var opponent_row: Dictionary = {
		"seat": "-",
		"player": "Opponents combined",
		"preflop": _opponent_range_label(hero_row.get("preflop", "N/A")),
		"flop": _opponent_range_label(hero_row.get("flop", "N/A")),
		"turn": _opponent_range_label(hero_row.get("turn", "N/A")),
		"river": _opponent_range_label(hero_row.get("river", "N/A")),
		"final": _perceived_final_label(hero_seat, winner_seats, fold_phase_by_seat, false),
	}
	return [hero_row, opponent_row]


static func _objective_equity_label(record: Dictionary, players: Array, community: Dictionary, fold_phase_by_seat: Dictionary, phase: String, target_seat: int) -> String:
	if _phase_missing(community, phase):
		return "-"
	if _folded_before_phase(fold_phase_by_seat, target_seat, phase):
		return "Folded"
	var known_board: Array[String] = _board_for_phase(community, phase)
	var active_players: Array = _active_players_for_phase(players, fold_phase_by_seat, phase)
	if active_players.size() < 2:
		return "N/A"
	var target_has_cards: bool = false
	for player_item in active_players:
		var player: Dictionary = Dictionary(player_item)
		if int(player.get("seat_index", -1)) == target_seat:
			target_has_cards = _hole_cards(player).size() == 2
			break
	if not target_has_cards:
		return "N/A"
	var equity: float = _deterministic_monte_carlo(record, active_players, known_board, target_seat, phase, MONTE_CARLO_TRIALS)
	if equity < 0.0:
		return "N/A"
	return "%.1f%%" % (equity * 100.0)


static func _perceived_hero_equity_label(record: Dictionary, players: Array, community: Dictionary, fold_phase_by_seat: Dictionary, phase: String, hero_seat: int) -> String:
	if _phase_missing(community, phase):
		return "-"
	if _folded_before_phase(fold_phase_by_seat, hero_seat, phase):
		return "Folded"
	var hero: Dictionary = _player_for_seat(players, hero_seat)
	var hero_hole: Array[String] = _hole_cards(hero)
	if hero_hole.size() != 2:
		return "N/A"
	var known_board: Array[String] = _board_for_phase(community, phase)
	var opponent_count: int = 0
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var seat_index: int = int(player.get("seat_index", -1))
		if seat_index != hero_seat and not _folded_before_phase(fold_phase_by_seat, seat_index, phase):
			opponent_count += 1
	if opponent_count <= 0:
		return "N/A"
	var equity: float = _perceived_monte_carlo(record, hero_hole, known_board, opponent_count, phase)
	if equity < 0.0:
		return "N/A"
	return "%.1f%%" % (equity * 100.0)


static func _deterministic_monte_carlo(record: Dictionary, active_players: Array, known_board: Array[String], target_seat: int, phase: String, trial_count: int) -> float:
	var used: Dictionary = {}
	for card in known_board:
		used[card] = true
	for player_item in active_players:
		var player: Dictionary = Dictionary(player_item)
		var hole_cards: Array[String] = _hole_cards(player)
		if hole_cards.size() != 2:
			return -1.0
		for card in hole_cards:
			used[card] = true

	var deck: Array[String] = _remaining_deck(used)
	var needed_board_cards: int = 5 - known_board.size()
	if needed_board_cards < 0:
		return -1.0

	var wins: float = 0.0
	var seed_text: String = "%s:%s:objective" % [str(record.get("hand_id", "")), phase]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(seed_text.hash()))

	for _trial in range(trial_count):
		var trial_deck: Array[String] = deck.duplicate()
		_shuffle_with_rng(trial_deck, rng)
		var board: Array[String] = known_board.duplicate()
		for i in range(needed_board_cards):
			if i < trial_deck.size():
				board.append(trial_deck[i])
		var winning_seats: Array[int] = _winning_seats(active_players, board)
		if winning_seats.has(target_seat):
			wins += 1.0 / float(max(winning_seats.size(), 1))

	return wins / float(max(trial_count, 1))


static func _perceived_monte_carlo(record: Dictionary, hero_hole: Array[String], known_board: Array[String], opponent_count: int, phase: String) -> float:
	var used: Dictionary = {}
	for card in known_board:
		used[card] = true
	for card in hero_hole:
		used[card] = true
	var deck: Array[String] = _remaining_deck(used)
	var needed_board_cards: int = 5 - known_board.size()
	var needed_opponent_cards: int = opponent_count * 2
	if needed_board_cards < 0 or deck.size() < needed_board_cards + needed_opponent_cards:
		return -1.0

	var wins: float = 0.0
	var seed_text: String = "%s:%s:perceived:%s" % [str(record.get("hand_id", "")), phase, ",".join(hero_hole)]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(seed_text.hash()))

	for _trial in range(PERCEIVED_MONTE_CARLO_TRIALS):
		var trial_deck: Array[String] = deck.duplicate()
		_shuffle_with_rng(trial_deck, rng)
		var offset: int = 0
		var opponents: Array = []
		for opponent_index in range(opponent_count):
			var opponent_cards: Array[String] = [trial_deck[offset], trial_deck[offset + 1]]
			offset += 2
			opponents.append({"seat_index": opponent_index + 100, "hole_cards": opponent_cards})
		var board: Array[String] = known_board.duplicate()
		for i in range(needed_board_cards):
			board.append(trial_deck[offset + i])
		var hero_player: Dictionary = {"seat_index": 1, "hole_cards": hero_hole}
		var all_players: Array = [hero_player] + opponents
		var winning_seats: Array[int] = _winning_seats(all_players, board)
		if winning_seats.has(1):
			wins += 1.0 / float(max(winning_seats.size(), 1))

	return wins / float(PERCEIVED_MONTE_CARLO_TRIALS)


static func _winning_seats(players: Array, board: Array[String]) -> Array[int]:
	var best_eval: Dictionary = {}
	var winners: Array[int] = []
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var seat_index: int = int(player.get("seat_index", -1))
		var cards: Array[String] = _hole_cards(player) + board
		var evaluation: Dictionary = HandEvaluatorScript.evaluate(cards)
		if best_eval.is_empty() or _compare_eval(evaluation, best_eval) > 0:
			best_eval = evaluation
			winners = [seat_index]
		elif _compare_eval(evaluation, best_eval) == 0:
			winners.append(seat_index)
	return winners


static func _compare_eval(a: Dictionary, b: Dictionary) -> int:
	var rank_a: int = int(a.get("rank_value", 0))
	var rank_b: int = int(b.get("rank_value", 0))
	if rank_a != rank_b:
		return 1 if rank_a > rank_b else -1
	var cards_a: Array = Array(a.get("cards", []))
	var cards_b: Array = Array(b.get("cards", []))
	for i in range(min(cards_a.size(), cards_b.size())):
		var value_a: int = _rank_value(str(cards_a[i]))
		var value_b: int = _rank_value(str(cards_b[i]))
		if value_a != value_b:
			return 1 if value_a > value_b else -1
	return 0


static func _sorted_players(players: Array) -> Array:
	var result: Array = []
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var seat_index: int = int(player.get("seat_index", -1))
		if seat_index > 0:
			result.append(player)
	result.sort_custom(func(a, b): return int(Dictionary(a).get("seat_index", 99)) < int(Dictionary(b).get("seat_index", 99)))
	return result.slice(0, min(9, result.size()))


static func _active_players_for_phase(players: Array, fold_phase_by_seat: Dictionary, phase: String) -> Array:
	var result: Array = []
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var seat_index: int = int(player.get("seat_index", -1))
		if _folded_before_phase(fold_phase_by_seat, seat_index, phase):
			continue
		result.append(player)
	return result


static func _resolve_hero_seat(players: Array, requested_seat: int) -> int:
	if requested_seat > 0 and not _player_for_seat(players, requested_seat).is_empty():
		return requested_seat
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		if bool(player.get("is_local", false)):
			return int(player.get("seat_index", -1))
	if not _player_for_seat(players, 5).is_empty():
		return 5
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		if not bool(player.get("is_ai", false)):
			return int(player.get("seat_index", -1))
	return int(Dictionary(players[0]).get("seat_index", -1))


static func _player_for_seat(players: Array, seat_index: int) -> Dictionary:
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		if int(player.get("seat_index", -1)) == seat_index:
			return player
	return {}


static func _player_name_for_seat(players: Array, seat_index: int) -> String:
	var player: Dictionary = _player_for_seat(players, seat_index)
	if player.is_empty():
		return "-"
	return str(player.get("player_name", player.get("player_id", "Seat %d" % seat_index)))


static func _fold_phase_by_seat(actions: Array) -> Dictionary:
	var result: Dictionary = {}
	for action_item in actions:
		var action: Dictionary = Dictionary(action_item)
		var action_name: String = str(action.get("action", "")).to_lower()
		if action_name.find("fold") == -1:
			continue
		var seat_index: int = int(action.get("actor_seat", action.get("seat_id", -1)))
		if seat_index <= 0:
			continue
		result[seat_index] = _normalized_phase(str(action.get("street", "preflop")))
	return result


static func _folded_before_phase(fold_phase_by_seat: Dictionary, seat_index: int, phase: String) -> bool:
	if not fold_phase_by_seat.has(seat_index):
		return false
	var fold_phase: String = str(fold_phase_by_seat[seat_index])
	return _phase_index(phase) > _phase_index(fold_phase)


static func _final_label(player: Dictionary, winner_seats: Array[int], fold_phase_by_seat: Dictionary) -> String:
	var seat_index: int = int(player.get("seat_index", -1))
	var final_status: String = str(player.get("final_status", "")).to_lower()
	if winner_seats.has(seat_index):
		return "Split" if winner_seats.size() > 1 else "Win"
	if fold_phase_by_seat.has(seat_index) or final_status.find("fold") != -1:
		return "Folded"
	if not winner_seats.is_empty():
		return "Loss"
	return "-"


static func _perceived_final_label(hero_seat: int, winner_seats: Array[int], fold_phase_by_seat: Dictionary, is_hero: bool) -> String:
	if is_hero:
		if fold_phase_by_seat.has(hero_seat):
			return "Folded"
		if winner_seats.has(hero_seat):
			return "Split" if winner_seats.size() > 1 else "Win"
		return "Loss" if not winner_seats.is_empty() else "-"
	if winner_seats.is_empty():
		return "-"
	if winner_seats.has(hero_seat) and winner_seats.size() == 1:
		return "Loss"
	if winner_seats.has(hero_seat):
		return "Split"
	return "Win"


static func _opponent_range_label(hero_value: Variant) -> String:
	var text: String = str(hero_value)
	if not text.ends_with("%"):
		return text
	var hero_equity: float = float(text.trim_suffix("%"))
	return "%.1f%%" % max(0.0, 100.0 - hero_equity)


static func _winner_seats(results: Dictionary) -> Array[int]:
	var seats: Array[int] = []
	for winner_item in Array(results.get("winners", [])):
		var winner: Dictionary = Dictionary(winner_item)
		var seat_index: int = int(winner.get("winner_seat", winner.get("seat_index", -1)))
		if seat_index > 0:
			seats.append(seat_index)
	return seats


static func _phase_missing(community: Dictionary, phase: String) -> bool:
	match phase:
		"flop":
			return Array(community.get("flop", [])).size() < 3
		"turn":
			return Array(community.get("turn", [])).is_empty()
		"river":
			return Array(community.get("river", [])).is_empty()
	return false


static func _board_for_phase(community: Dictionary, phase: String) -> Array[String]:
	var board: Array[String] = []
	if phase in ["flop", "turn", "river"]:
		board.append_array(_card_codes(Array(community.get("flop", []))))
	if phase in ["turn", "river"]:
		board.append_array(_card_codes(Array(community.get("turn", []))))
	if phase == "river":
		board.append_array(_card_codes(Array(community.get("river", []))))
	return board


static func _hole_cards(player: Dictionary) -> Array[String]:
	return _card_codes(Array(player.get("hole_cards", [])))


static func _card_codes(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card_item in cards:
		var code: String = ""
		if card_item is Dictionary:
			code = str(Dictionary(card_item).get("code", ""))
		else:
			code = str(card_item)
		code = code.strip_edges().to_upper()
		if code.length() == 2:
			result.append(code)
	return result


static func _remaining_deck(used: Dictionary) -> Array[String]:
	var deck: Array[String] = []
	for rank in ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]:
		for suit in ["S", "H", "D", "C"]:
			var code: String = "%s%s" % [rank, suit]
			if not used.has(code):
				deck.append(code)
	return deck


static func _shuffle_with_rng(deck: Array[String], rng: RandomNumberGenerator) -> void:
	for i in range(deck.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: String = deck[i]
		deck[i] = deck[j]
		deck[j] = temp


static func _normalized_phase(value: String) -> String:
	var phase: String = value.to_lower()
	if phase in ["showdown", "hand_over", "result", "final"]:
		return "final"
	if phase in PHASES:
		return phase
	return "preflop"


static func _phase_index(phase: String) -> int:
	match _normalized_phase(phase):
		"preflop":
			return 0
		"flop":
			return 1
		"turn":
			return 2
		"river":
			return 3
		"final":
			return 4
	return 0


static func _rank_value(code: String) -> int:
	return int(HandEvaluatorScript.RANK_VALUES.get(code.substr(0, 1), 0))
