extends RefCounted
class_name MockHomeData

const PLAYER_NAME := "Luna0581"
const LEVEL := 24
const XP_CURRENT := 875
const XP_MAX := 1500
const CHIPS := 25750
const PREMIUM_CURRENCY := 1250

const MODES := [
	{ "id": "quick_play", "title": "QUICK PLAY", "subtitle": "Jump in now\nNo waiting", "featured": true },
	{ "id": "cash_tables", "title": "CASH TABLES", "subtitle": "Choose your stakes\nSit & play", "featured": false },
	{ "id": "tournaments", "title": "TOURNAMENTS", "subtitle": "Compete & win\nBig prizes", "featured": false },
	{ "id": "private_table", "title": "PRIVATE TABLE", "subtitle": "Invite your friends\nPlay together", "featured": false },
	{ "id": "club_games", "title": "CLUB GAMES", "subtitle": "Join a club\nPlay & earn", "featured": false },
]

const DAILY_BONUS := [
	{ "day": "DAY 1", "amount": "500", "claimed": true, "active": false },
	{ "day": "DAY 2", "amount": "750", "claimed": true, "active": false },
	{ "day": "DAY 3", "amount": "1,000", "claimed": true, "active": false },
	{ "day": "DAY 4", "amount": "1,250", "claimed": false, "active": true },
	{ "day": "DAY 5", "amount": "1,500", "claimed": false, "active": false },
	{ "day": "DAY 6", "amount": "2,000", "claimed": false, "active": false },
	{ "day": "DAY 7", "amount": "5,000", "claimed": false, "active": false },
]

static func player() -> Dictionary:
	return {
		"player_name": PLAYER_NAME,
		"level": LEVEL,
		"xp_current": XP_CURRENT,
		"xp_max": XP_MAX,
		"chips": CHIPS,
		"premium_currency": PREMIUM_CURRENCY,
	}
