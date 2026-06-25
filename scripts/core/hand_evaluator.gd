extends RefCounted
class_name HandEvaluator

const CardScript := preload("res://scripts/core/card.gd")
const HandRankScript := preload("res://scripts/core/hand_rank.gd")

const RANK_VALUES := {
	"2": 2,
	"3": 3,
	"4": 4,
	"5": 5,
	"6": 6,
	"7": 7,
	"8": 8,
	"9": 9,
	"T": 10,
	"J": 11,
	"Q": 12,
	"K": 13,
	"A": 14,
}

static func evaluate(card_codes: Array) -> Dictionary:
	var normalized := _normalize_codes(card_codes)
	if normalized.is_empty():
		return _result(HandRankScript.HIGH_CARD, [], [])
	var rank_counts := _rank_counts(normalized)
	var suit_counts := _suit_counts(normalized)
	var is_flush := _has_count_at_least(suit_counts, 5)
	var straight_cards := _straight_cards(normalized)
	var is_straight := not straight_cards.is_empty()
	var grouped := _rank_groups(rank_counts)
	var rank_id := HandRankScript.HIGH_CARD
	var cards := _top_cards(normalized, 5)
	var kickers: Array[String] = []

	if is_flush and is_straight and _contains_royal(straight_cards):
		rank_id = HandRankScript.ROYAL_FLUSH
		cards = straight_cards
	elif is_flush and is_straight:
		rank_id = HandRankScript.STRAIGHT_FLUSH
		cards = straight_cards
	elif grouped.get(4, []).size() > 0:
		rank_id = HandRankScript.FOUR_OF_A_KIND
		cards = _cards_for_ranks(normalized, [grouped[4][0]]) + _top_cards_excluding(normalized, [grouped[4][0]], 1)
	elif grouped.get(3, []).size() > 0 and grouped.get(2, []).size() > 0:
		rank_id = HandRankScript.FULL_HOUSE
		cards = _cards_for_ranks(normalized, [grouped[3][0], grouped[2][0]])
	elif is_flush:
		rank_id = HandRankScript.FLUSH
		cards = _top_flush_cards(normalized, 5)
	elif is_straight:
		rank_id = HandRankScript.STRAIGHT
		cards = straight_cards
	elif grouped.get(3, []).size() > 0:
		rank_id = HandRankScript.THREE_OF_A_KIND
		cards = _cards_for_ranks(normalized, [grouped[3][0]]) + _top_cards_excluding(normalized, [grouped[3][0]], 2)
	elif grouped.get(2, []).size() >= 2:
		rank_id = HandRankScript.TWO_PAIR
		cards = _cards_for_ranks(normalized, [grouped[2][0], grouped[2][1]]) + _top_cards_excluding(normalized, [grouped[2][0], grouped[2][1]], 1)
	elif grouped.get(2, []).size() == 1:
		rank_id = HandRankScript.ONE_PAIR
		cards = _cards_for_ranks(normalized, [grouped[2][0]]) + _top_cards_excluding(normalized, [grouped[2][0]], 3)

	if rank_id == HandRankScript.ONE_PAIR:
		kickers = _top_cards_excluding(normalized, [grouped[2][0]], 3)
	elif rank_id == HandRankScript.HIGH_CARD:
		kickers = cards.slice(1)

	return _result(rank_id, cards, kickers)

static func _result(rank_id: String, cards: Array, kickers: Array) -> Dictionary:
	return {
		"rank": rank_id,
		"rank_value": HandRankScript.value(rank_id),
		"cards": cards,
		"kickers": kickers,
	}

static func _normalize_codes(card_codes: Array) -> Array[String]:
	var result: Array[String] = []
	for code in card_codes:
		var value := String(code).strip_edges().to_upper()
		if value.length() == 2:
			result.append(value)
	result.sort_custom(func(a: String, b: String) -> bool: return _rank_value_from_code(a) > _rank_value_from_code(b))
	return result

static func _rank_counts(cards: Array[String]) -> Dictionary:
	var counts := {}
	for code in cards:
		var rank := code.substr(0, 1)
		counts[rank] = int(counts.get(rank, 0)) + 1
	return counts

static func _suit_counts(cards: Array[String]) -> Dictionary:
	var counts := {}
	for code in cards:
		var suit := code.substr(1, 1)
		counts[suit] = int(counts.get(suit, 0)) + 1
	return counts

static func _has_count_at_least(counts: Dictionary, min_count: int) -> bool:
	for key in counts:
		if int(counts[key]) >= min_count:
			return true
	return false

static func _rank_groups(rank_counts: Dictionary) -> Dictionary:
	var groups := {4: [], 3: [], 2: [], 1: []}
	for rank in rank_counts:
		var count := int(rank_counts[rank])
		if groups.has(count):
			groups[count].append(rank)
	for count in groups:
		groups[count].sort_custom(func(a: String, b: String) -> bool: return RANK_VALUES[a] > RANK_VALUES[b])
	return groups

static func _straight_cards(cards: Array[String]) -> Array[String]:
	var ranks: Array[int] = []
	var code_by_rank := {}
	for code in cards:
		var value := _rank_value_from_code(code)
		if not ranks.has(value):
			ranks.append(value)
			code_by_rank[value] = code
	if ranks.has(14):
		ranks.append(1)
		code_by_rank[1] = code_by_rank[14]
	ranks.sort()
	ranks.reverse()
	for start in range(0, ranks.size()):
		var run: Array[int] = [ranks[start]]
		for i in range(start + 1, ranks.size()):
			if ranks[i] == run[-1] - 1:
				run.append(ranks[i])
				if run.size() == 5:
					var result: Array[String] = []
					for rank in run:
						result.append(code_by_rank[rank])
					return result
			elif ranks[i] != run[-1]:
				break
	return []

static func _contains_royal(cards: Array[String]) -> bool:
	var ranks := []
	for code in cards:
		ranks.append(code.substr(0, 1))
	return ranks.has("A") and ranks.has("K") and ranks.has("Q") and ranks.has("J") and ranks.has("T")

static func _top_cards(cards: Array[String], count: int) -> Array[String]:
	var result: Array[String] = []
	for code in cards.slice(0, min(count, cards.size())):
		result.append(String(code))
	return result

static func _top_cards_excluding(cards: Array[String], excluded_ranks: Array, count: int) -> Array[String]:
	var result: Array[String] = []
	for code in cards:
		if excluded_ranks.has(code.substr(0, 1)):
			continue
		result.append(code)
		if result.size() == count:
			break
	return result

static func _cards_for_ranks(cards: Array[String], ranks: Array) -> Array[String]:
	var result: Array[String] = []
	for rank in ranks:
		for code in cards:
			if code.substr(0, 1) == rank:
				result.append(code)
	return result

static func _top_flush_cards(cards: Array[String], count: int) -> Array[String]:
	var by_suit := {}
	for code in cards:
		var suit := code.substr(1, 1)
		if not by_suit.has(suit):
			var arr: Array[String] = []
			by_suit[suit] = arr
		by_suit[suit].append(code)
	for suit in by_suit:
		var suited: Array[String] = by_suit[suit]
		if suited.size() >= count:
			var res: Array[String] = []
			res.assign(suited.slice(0, count))
			return res
	var empty: Array[String] = []
	return empty

static func _rank_value_from_code(code: String) -> int:
	return int(RANK_VALUES.get(code.substr(0, 1), 0))
