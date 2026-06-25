extends RefCounted
class_name PlayerProfile

const CurrencyBalanceScript := preload("res://scripts/data/currency_balance.gd")

var name := ""
var level := 1
var xp_current := 0
var xp_max := 1
var avatar := ""
var balance = CurrencyBalanceScript.new()

func _init(
	player_name: String = "",
	player_level: int = 1,
	current_xp: int = 0,
	max_xp: int = 1,
	player_chips: int = 0,
	player_gems: int = 0,
	avatar_path: String = ""
) -> void:
	name = player_name
	level = player_level
	xp_current = current_xp
	xp_max = max(max_xp, 1)
	avatar = avatar_path
	balance = CurrencyBalanceScript.new(player_chips, player_gems)

func xp_text() -> String:
	return "%d / %d XP" % [xp_current, xp_max]

func to_lobby_dict() -> Dictionary:
	return {
		"name": name,
		"level": level,
		"xp_text": xp_text(),
		"chips": balance.chips,
		"gems": balance.gems,
		"avatar": avatar,
	}

func to_dict() -> Dictionary:
	var data := to_lobby_dict()
	data["xp_current"] = xp_current
	data["xp_max"] = xp_max
	return data

static func from_dict(data: Dictionary):
	return load("res://scripts/data/player_profile.gd").new(
		String(data.get("name", "")),
		int(data.get("level", 1)),
		int(data.get("xp_current", 0)),
		int(data.get("xp_max", 1)),
		int(data.get("chips", 0)),
		int(data.get("gems", 0)),
		String(data.get("avatar", ""))
	)
