extends RefCounted
class_name CoreCard

const RANKS := ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
const SUITS := ["clubs", "diamonds", "hearts", "spades"]
const SUIT_CODES := {
	"clubs": "C",
	"diamonds": "D",
	"hearts": "H",
	"spades": "S",
}

var rank := ""
var suit := ""

func _init(card_rank: String = "", card_suit: String = "") -> void:
	rank = card_rank
	suit = card_suit

func code() -> String:
	return "%s%s" % [rank, SUIT_CODES.get(suit, "?")]

func is_valid() -> bool:
	return RANKS.has(rank) and SUITS.has(suit)

func to_dict() -> Dictionary:
	return {
		"rank": rank,
		"suit": suit,
		"code": code(),
	}

static func from_dict(data: Dictionary):
	return load("res://scripts/core/card.gd").new(
		String(data.get("rank", "")),
		String(data.get("suit", ""))
	)

static func code_for(card_rank: String, card_suit: String) -> String:
	return "%s%s" % [card_rank, SUIT_CODES.get(card_suit, "?")]
