extends RefCounted
class_name CoreDeck

const CardScript := preload("res://scripts/core/card.gd")

var cards: Array[Dictionary] = []

func _init(generate_standard_deck: bool = true) -> void:
	if generate_standard_deck:
		reset()

func reset() -> void:
	cards.clear()
	for suit in CardScript.SUITS:
		for rank in CardScript.RANKS:
			cards.append(CardScript.new(rank, suit).to_dict())

func count() -> int:
	return cards.size()

func shuffle(seed_value: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cards[i]
		cards[i] = cards[j]
		cards[j] = tmp

func draw(count_to_draw: int = 1) -> Array[Dictionary]:
	var drawn: Array[Dictionary] = []
	for _i in range(max(count_to_draw, 0)):
		if cards.is_empty():
			break
		drawn.append(cards.pop_front())
	return drawn

func codes() -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		result.append(String(card.get("code", "")))
	return result

func has_unique_codes() -> bool:
	var seen := {}
	for code in codes():
		if seen.has(code):
			return false
		seen[code] = true
	return true

func to_dict() -> Dictionary:
	return {
		"cards": cards.duplicate(true),
		"count": count(),
	}
