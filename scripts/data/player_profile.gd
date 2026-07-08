extends RefCounted
class_name PlayerProfile

const CurrencyBalanceScript := preload("res://scripts/data/currency_balance.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

const DEFAULT_PLAYER_ID := "local_player"
const DEFAULT_PLAYER_NAME := "Luna0581"
const DEFAULT_AVATAR_ID := "4_05"
const XP_PER_LEVEL := 100
const DEFAULT_TOTAL_XP := 0
const DEFAULT_LEVEL := 1
const DEFAULT_XP_CURRENT := 0
const DEFAULT_XP_MAX := XP_PER_LEVEL
const DEFAULT_TOTAL_CHIPS := 24500
const DEFAULT_GEMS := 0
const DEFAULT_TABLE_BUY_IN := 20000
const SCHEMA_VERSION := 3
const DAILY_LOGIN_CHIPS := 500
const DAILY_LOGIN_XP := 25
const DAILY_BONUS_REWARDS := [
	{"day": 1, "chips": 500, "xp": 25, "gems": 0},
	{"day": 2, "chips": 750, "xp": 25, "gems": 0},
	{"day": 3, "chips": 1000, "xp": 25, "gems": 0},
	{"day": 4, "chips": 1250, "xp": 25, "gems": 0},
	{"day": 5, "chips": 1500, "xp": 25, "gems": 0},
	{"day": 6, "chips": 2000, "xp": 25, "gems": 0},
	{"day": 7, "chips": 5000, "xp": 50, "gems": 5},
]
const REPLAY_UNLOCK_COST_GEMS := 20
const TITLE_UNLOCKS := [
	{"level": 1, "title": "Rookie"},
	{"level": 3, "title": "Casual Player"},
	{"level": 5, "title": "Table Regular"},
	{"level": 10, "title": "Sharp Caller"},
	{"level": 15, "title": "River Hunter"},
	{"level": 20, "title": "Card Shark"},
	{"level": 30, "title": "High Roller"},
	{"level": 50, "title": "Poker Legend"},
]

var player_id := DEFAULT_PLAYER_ID
var name := ""
var total_xp := DEFAULT_TOTAL_XP
var level := 1
var xp_current := 0
var xp_max := 1
var avatar := ""
var avatar_id := DEFAULT_AVATAR_ID
var selected_avatar_id := DEFAULT_AVATAR_ID
var unlocked_avatar_ids: Array[String] = []
var balance = CurrencyBalanceScript.new()
var total_sessions_played := 0
var total_hands_played := 0
var total_hands_won := 0
var total_profit := 0
var biggest_pot := 0
var best_hand_desc := ""
var best_session_profit := 0
var last_daily_reward_date := ""
var last_daily_reward_xp_date := ""
var daily_bonus_claim_count := 0
var daily_bonus_cycle_day := 1
var daily_bonus_claimed_days_in_cycle := 0
var daily_bonus_can_claim_today := true
var daily_bonus_status_synced := false
var daily_reward_claimed_today := false
var replay_unlock_cost_gems := REPLAY_UNLOCK_COST_GEMS
var unlocked_replay_ids: Array[String] = []

func _init(
	player_name: String = "",
	player_level: int = 1,
	current_xp: int = 0,
	_max_xp: int = 1,
	player_chips: int = 0,
	player_gems: int = 0,
	avatar_path: String = "",
	profile_player_id: String = DEFAULT_PLAYER_ID,
	profile_avatar_id: String = DEFAULT_AVATAR_ID,
	profile_selected_avatar_id: String = "",
	profile_unlocked_avatar_ids: Array = [],
	profile_stats: Dictionary = {}
) -> void:
	name = player_name
	var legacy_xp_progress: int = clamp(current_xp, 0, XP_PER_LEVEL - 1)
	total_xp = int(profile_stats.get("total_xp", max(0, (player_level - 1) * XP_PER_LEVEL + legacy_xp_progress)))
	level = level_for_total_xp(total_xp)
	xp_current = xp_current_for_total_xp(total_xp)
	xp_max = XP_PER_LEVEL
	avatar = avatar_path
	player_id = profile_player_id
	avatar_id = profile_avatar_id if profile_avatar_id != "" else DEFAULT_AVATAR_ID
	selected_avatar_id = profile_selected_avatar_id if profile_selected_avatar_id != "" else avatar_id
	unlocked_avatar_ids.clear()
	for id in profile_unlocked_avatar_ids:
		var unlocked_id: String = String(id)
		if unlocked_id != "" and not unlocked_avatar_ids.has(unlocked_id):
			unlocked_avatar_ids.append(unlocked_id)
	if unlocked_avatar_ids.is_empty():
		unlocked_avatar_ids.append_array(AvatarLibraryScript.default_unlocked_avatar_ids())
	if unlocked_avatar_ids.is_empty():
		unlocked_avatar_ids.append(DEFAULT_AVATAR_ID)
	if selected_avatar_id == "" or not unlocked_avatar_ids.has(selected_avatar_id):
		selected_avatar_id = unlocked_avatar_ids[0]
	avatar_id = selected_avatar_id
	balance = CurrencyBalanceScript.new(player_chips, player_gems)
	total_sessions_played = int(profile_stats.get("total_sessions_played", 0))
	total_hands_played = int(profile_stats.get("total_hands_played", 0))
	total_hands_won = int(profile_stats.get("total_hands_won", 0))
	total_profit = int(profile_stats.get("total_profit", 0))
	biggest_pot = int(profile_stats.get("biggest_pot", 0))
	best_hand_desc = String(profile_stats.get("best_hand_desc", ""))
	best_session_profit = int(profile_stats.get("best_session_profit", 0))
	last_daily_reward_date = String(profile_stats.get("last_daily_reward_date", ""))
	last_daily_reward_xp_date = String(profile_stats.get("last_daily_reward_xp_date", ""))
	daily_bonus_claim_count = int(profile_stats.get("daily_bonus_claim_count", 0))
	daily_bonus_cycle_day = int(profile_stats.get("daily_bonus_cycle_day", next_daily_bonus_day(profile_stats)))
	daily_bonus_claimed_days_in_cycle = int(profile_stats.get("daily_bonus_claimed_days_in_cycle", daily_bonus_claim_count % DAILY_BONUS_REWARDS.size()))
	daily_bonus_can_claim_today = bool(profile_stats.get("daily_bonus_can_claim_today", not bool(profile_stats.get("daily_reward_claimed_today", false))))
	daily_bonus_status_synced = bool(profile_stats.get("daily_bonus_status_synced", false))
	daily_reward_claimed_today = bool(profile_stats.get("daily_reward_claimed_today", false))
	replay_unlock_cost_gems = int(profile_stats.get("replay_unlock_cost_gems", REPLAY_UNLOCK_COST_GEMS))
	unlocked_replay_ids.clear()
	for id in Array(profile_stats.get("unlocked_replay_ids", [])):
		var replay_id := str(id).strip_edges()
		if replay_id != "" and not unlocked_replay_ids.has(replay_id):
			unlocked_replay_ids.append(replay_id)

func xp_text() -> String:
	return "%d / %d XP" % [xp_current, xp_max]

func to_lobby_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"player_id": player_id,
		"name": name,
		"player_name": name,
		"total_xp": total_xp,
		"level": level,
		"xp_text": xp_text(),
		"current_title_name": title_for_level(level),
		"title": title_for_level(level),
		"chips": balance.chips,
		"total_chips": balance.chips,
		"gems": balance.gems,
		"avatar": avatar,
		"avatar_id": avatar_id,
		"selected_avatar_id": selected_avatar_id,
		"unlocked_avatar_ids": unlocked_avatar_ids.duplicate(),
		"total_sessions_played": total_sessions_played,
		"total_hands_played": total_hands_played,
		"total_hands_won": total_hands_won,
		"total_profit": total_profit,
		"biggest_pot": biggest_pot,
		"best_hand_desc": best_hand_desc,
		"best_session_profit": best_session_profit,
		"last_daily_reward_date": last_daily_reward_date,
		"last_daily_reward_xp_date": last_daily_reward_xp_date,
		"daily_bonus_claim_count": daily_bonus_claim_count,
		"daily_bonus_cycle_day": daily_bonus_cycle_day,
		"daily_bonus_claimed_days_in_cycle": daily_bonus_claimed_days_in_cycle,
		"daily_bonus_can_claim_today": daily_bonus_can_claim_today,
		"daily_bonus_status_synced": daily_bonus_status_synced,
		"daily_reward_claimed_today": daily_reward_claimed_today,
		"replay_unlock_cost_gems": replay_unlock_cost_gems,
		"unlocked_replay_ids": unlocked_replay_ids.duplicate(),
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
		Array(data.get("unlocked_avatar_ids", [])),
		data
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

static func win_rate(data: Dictionary) -> float:
	var hands: int = int(data.get("total_hands_played", 0))
	if hands <= 0:
		return 0.0
	return float(int(data.get("total_hands_won", 0))) / float(hands)

static func get_player_name(data: Dictionary) -> String:
	return String(data.get("player_name", data.get("name", DEFAULT_PLAYER_NAME)))

static func get_avatar_id(data: Dictionary) -> String:
	return String(data.get("selected_avatar_id", data.get("avatar_id", DEFAULT_AVATAR_ID)))

static func get_total_chips(data: Dictionary) -> int:
	return int(data.get("total_chips", data.get("chips", DEFAULT_TOTAL_CHIPS)))

static func get_total_gems(data: Dictionary) -> int:
	return int(data.get("gems", DEFAULT_GEMS))

static func get_total_xp(data: Dictionary) -> int:
	var legacy_xp_progress: int = clamp(int(data.get("xp_current", DEFAULT_XP_CURRENT)), 0, XP_PER_LEVEL - 1)
	return int(data.get("total_xp", max(0, (int(data.get("level", DEFAULT_LEVEL)) - 1) * XP_PER_LEVEL + legacy_xp_progress)))

static func level_for_total_xp(value: int) -> int:
	return int(floor(float(max(value, 0)) / float(XP_PER_LEVEL))) + 1

static func xp_current_for_total_xp(value: int) -> int:
	return max(value, 0) % XP_PER_LEVEL

static func title_for_level(value: int) -> String:
	var resolved := "Rookie"
	for entry in TITLE_UNLOCKS:
		var threshold := int(entry.get("level", 1))
		if value >= threshold:
			resolved = String(entry.get("title", resolved))
	return resolved

static func title_for_profile(data: Dictionary) -> String:
	return title_for_level(level_for_total_xp(get_total_xp(data)))

static func daily_bonus_reward_for_day(day: int) -> Dictionary:
	var safe_day: int = clamp(day, 1, DAILY_BONUS_REWARDS.size())
	return Dictionary(DAILY_BONUS_REWARDS[safe_day - 1]).duplicate(true)

static func next_daily_bonus_day(data: Dictionary) -> int:
	var claim_count: int = max(int(data.get("daily_bonus_claim_count", 0)), 0)
	return (claim_count % DAILY_BONUS_REWARDS.size()) + 1

static func daily_bonus_display_state(data: Dictionary, today: String = "") -> Dictionary:
	var date_key := today
	if date_key == "":
		var now: Dictionary = Time.get_datetime_dict_from_system()
		date_key = "%04d-%02d-%02d" % [int(now.get("year", 0)), int(now.get("month", 0)), int(now.get("day", 0))]
	var claim_count: int = max(int(data.get("daily_bonus_claim_count", 0)), 0)
	var claimed_today: bool = String(data.get("last_daily_reward_date", "")) == date_key and bool(data.get("daily_reward_claimed_today", false))
	var has_server_status: bool = bool(data.get("daily_bonus_status_synced", false))
	var completed_in_cycle: int = clamp(int(data.get("daily_bonus_claimed_days_in_cycle", claim_count % DAILY_BONUS_REWARDS.size())), 0, DAILY_BONUS_REWARDS.size())
	var can_claim_today: bool = bool(data.get("daily_bonus_can_claim_today", not claimed_today))
	var current_day: int = clamp(int(data.get("daily_bonus_cycle_day", completed_in_cycle + 1)), 1, DAILY_BONUS_REWARDS.size())
	if not has_server_status:
		completed_in_cycle = claim_count % DAILY_BONUS_REWARDS.size()
		current_day = completed_in_cycle + 1
		can_claim_today = not claimed_today
		if claimed_today:
			current_day = completed_in_cycle if completed_in_cycle > 0 else DAILY_BONUS_REWARDS.size()
			completed_in_cycle = current_day
	elif claimed_today:
		can_claim_today = false
	var next_reward_day: int = current_day
	if claimed_today:
		next_reward_day = 1 if current_day >= DAILY_BONUS_REWARDS.size() else current_day + 1
	var days: Array[Dictionary] = []
	for reward_value in DAILY_BONUS_REWARDS:
		var reward := Dictionary(reward_value)
		var day: int = int(reward.get("day", 1))
		var is_claimed: bool = day <= completed_in_cycle
		var is_claimed_today: bool = claimed_today and day == current_day
		var can_claim: bool = can_claim_today and not claimed_today and day == current_day and not is_claimed
		var is_next: bool = claimed_today and day == next_reward_day and not is_claimed
		var is_future: bool = not is_claimed and not can_claim and not is_next
		var status_text := "LOCKED"
		if is_claimed_today:
			status_text = "CLAIMED TODAY"
		elif is_claimed:
			status_text = "CLAIMED"
		elif can_claim:
			status_text = "CLAIM"
		elif is_next:
			status_text = "NEXT"
		days.append({
			"day": day,
			"label": "Day %d" % day,
			"chips": int(reward.get("chips", 0)),
			"xp": int(reward.get("xp", 0)),
			"gems": int(reward.get("gems", 0)),
			"claimed": is_claimed,
			"claimed_today_card": is_claimed_today,
			"active": can_claim,
			"claimable": can_claim,
			"next": is_next,
			"future": is_future,
			"locked": is_future,
			"highlight": can_claim or is_claimed_today,
			"soft_highlight": is_next,
			"status_text": status_text,
		})
	var action_line: String = "Today: Claim Day %d reward" % current_day
	if claimed_today:
		action_line = "Next Reward: Day %d available tomorrow" % next_reward_day
	return {
		"current_day": current_day,
		"claimed_today": claimed_today,
		"claimed_days_in_cycle": completed_in_cycle,
		"can_claim_today": can_claim_today,
		"next_reward_day": next_reward_day,
		"summary_line": "Cycle Progress: %d / %d" % [completed_in_cycle, DAILY_BONUS_REWARDS.size()],
		"action_line": action_line,
		"days": days,
	}

static func table_buy_in(data: Dictionary) -> int:
	return min(DEFAULT_TABLE_BUY_IN, max(get_total_chips(data), 0))
