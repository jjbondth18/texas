extends RefCounted
class_name HandRank

const HIGH_CARD := "high_card"
const ONE_PAIR := "one_pair"
const TWO_PAIR := "two_pair"
const THREE_OF_A_KIND := "three_of_a_kind"
const STRAIGHT := "straight"
const FLUSH := "flush"
const FULL_HOUSE := "full_house"
const FOUR_OF_A_KIND := "four_of_a_kind"
const STRAIGHT_FLUSH := "straight_flush"
const ROYAL_FLUSH := "royal_flush"

const ORDER := [
	HIGH_CARD,
	ONE_PAIR,
	TWO_PAIR,
	THREE_OF_A_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	STRAIGHT_FLUSH,
	ROYAL_FLUSH,
]

static func value(rank_id: String) -> int:
	return ORDER.find(rank_id)

static func is_known(rank_id: String) -> bool:
	return ORDER.has(rank_id)
