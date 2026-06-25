extends RefCounted
class_name CardData

var rank := ""
var suit := ""
var face_up := true

func _init(card_rank: String = "", card_suit: String = "", is_face_up: bool = true) -> void:
	rank = card_rank
	suit = card_suit
	face_up = is_face_up

func to_dict() -> Dictionary:
	return {
		"rank": rank,
		"suit": suit,
		"face_up": face_up,
	}

static func from_dict(data: Dictionary):
	return load("res://scripts/data/card_data.gd").new(
		String(data.get("rank", "")),
		String(data.get("suit", "")),
		bool(data.get("face_up", true))
	)
