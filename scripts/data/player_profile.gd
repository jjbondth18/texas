extends RefCounted
class_name PlayerProfile

const CurrencyBalanceScript := preload("res://scripts/data/currency_balance.gd")

const DEFAULT_PLAYER_ID := "local_player"
const DEFAULT_PLAYER_NAME := "Luna0581"
const DEFAULT_AVATAR_ID := "4_05"
const DEFAULT_LEVEL := 24
const DEFAULT_XP_CURRENT := 875
const DEFAULT_XP_MAX := 1500
const DEFAULT_TOTAL_CHIPS := 24500
const DEFAULT_GEMS := 1250
const DEFAULT_TABLE_BUY_IN := 20000

var player_id := DEFAULT_PLAYER_ID
var name := ""
var level := 1
var xp_current := 0
var xp_max := 1
var avatar := ""
var avatar_id := DEFAULT_AVATAR_ID
var selected_avatar_id := DEFAULT_AVATAR_ID
var unlocked_avatar_ids: Array[String] = []
var balance = CurrencyBalanceScript.new()

func _init(
	player_name: String = "",
	player_level: int = 1,
	current_xp: int = 0,
	max_xp: int = 1,
	player_chips: int = 0,
	player_gems: int = 0,
	avatar_path: String = "",
	profile_player_id: String = DEFAULT_PLAYER_ID,
	profile_avatar_id: String = DEFAULT_AVATAR_ID,
	profile_selected_avatar_id: String = "",
	profile_unlocked_avatar_ids: Array = []
) -> void:
	name = player_name
	level = player_level
	xp_current = current_xp
	xp_max = max(max_xp, 1)
	avatar = avatar_path
	player_id = profile_player_id
	avatar_id = profile_avatar_id if profile_avatar_id != "" else DEFAULT_AVATAR_ID
	selected_avatar_id = profile_selected_avatar_id if profile_selected_avatar_id != "" else avatar_id
	unlocked_avatar_ids.clear()
	for id in profile_unlocked_avatar_ids:
		unlocked_avatar_ids.append(String(id))
	if unlocked_avatar_ids.is_empty():
		unlocked_avatar_ids.append(selected_avatar_id)
	balance = CurrencyBalanceScript.new(player_chips, player_gems)

func xp_text() -> String:
	return "%d / %d XP" % [xp_current, xp_max]

func to_lobby_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"name": name,
		"player_name": name,
		"level": level,
		"xp_text": xp_text(),
		"chips": balance.chips,
		"total_chips": balance.chips,
		"gems": balance.gems,
		"avatar": avatar,
		"avatar_id": avatar_id,
		"selected_avatar_id": selected_avatar_id,
		"unlocked_avatar_ids": unlocked_avatar_ids.duplicate(),
	}

func to_dict() -> Dictionary:
	var data := to_lobby_dict()
	data["xp_current"] = xp_current
	data["xp_max"] = xp_max
	return data

static func from_dict(data: Dictionary) -> PlayerProfile:
	return load("res://scripts/data/player_profile.gd").new(
		String(data.get("name", data.get("player_name", ""))),
		int(data.get("level", 1)),
		int(data.get("xp_current", 0)),
		int(data.get("xp_max", 1)),
		int(data.get("total_chips", data.get("chips", 0))),
		int(data.get("gems", 0)),
		String(data.get("avatar", "")),
		String(data.get("player_id", DEFAULT_PLAYER_ID)),
		String(data.get("avatar_id", DEFAULT_AVATAR_ID)),
		String(data.get("selected_avatar_id", data.get("avatar_id", DEFAULT_AVATAR_ID))),
		Array(data.get("unlocked_avatar_ids", []))
	)

static func default_profile() -> Dictionary:
	return load("res://scripts/data/player_profile.gd").new(
		DEFAULT_PLAYER_NAME,
		DEFAULT_LEVEL,
		DEFAULT_XP_CURRENT,
		DEFAULT_XP_MAX,
		DEFAULT_TOTAL_CHIPS,
		DEFAULT_GEMS,
		"res://assets/playersAv_cut/%s.png" % DEFAULT_AVATAR_ID,
		DEFAULT_PLAYER_ID,
		DEFAULT_AVATAR_ID,
		DEFAULT_AVATAR_ID,
		[DEFAULT_AVATAR_ID]
	).to_dict()

static func normalized_dict(data: Dictionary) -> Dictionary:
	var profile: PlayerProfile = from_dict(data)
	return profile.to_dict()

static func get_player_name(data: Dictionary) -> String:
	return String(data.get("player_name", data.get("name", DEFAULT_PLAYER_NAME)))

static func get_avatar_id(data: Dictionary) -> String:
	return String(data.get("selected_avatar_id", data.get("avatar_id", DEFAULT_AVATAR_ID)))

static func get_total_chips(data: Dictionary) -> int:
	return int(data.get("total_chips", data.get("chips", DEFAULT_TOTAL_CHIPS)))

static func table_buy_in(data: Dictionary) -> int:
	return min(DEFAULT_TABLE_BUY_IN, max(get_total_chips(data), 0))
