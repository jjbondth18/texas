extends RefCounted
class_name PokerPhase

const WAITING := "waiting"
const PREFLOP := "preflop"
const FLOP := "flop"
const TURN := "turn"
const RIVER := "river"
const SHOWDOWN := "showdown"
const FINISHED := "finished"

const ORDER := [
	WAITING,
	PREFLOP,
	FLOP,
	TURN,
	RIVER,
	SHOWDOWN,
	FINISHED,
]

static func is_known(phase_id: String) -> bool:
	return ORDER.has(phase_id)
