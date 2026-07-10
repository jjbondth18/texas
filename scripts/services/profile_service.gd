extends RefCounted
class_name ProfileService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const SaveManagerScript := preload("res://scripts/services/save_manager.gd")
const IdentityServiceScript := preload("res://scripts/services/identity_service.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

static var _saved_profile: Dictionary = {}
static var _loaded_save_suffix := ""
static var _last_unlocked_avatar_ids: Array[String] = []
static var _last_daily_bonus_claimed := false
static var _last_daily_bonus_reward: Dictionary = {}
static var _server_profile_synced := false

func get_current_profile() -> Dictionary:
	var save_suffix: String = IdentityServiceScript.dev_save_suffix()
	if _saved_profile.is_empty() or _loaded_save_suffix != save_suffix:
		var loaded_profile: Dictionary = SaveManagerScript.load_profile_save(save_suffix)
		if loaded_profile.is_empty():
			loaded_profile = MockDataProviderScript.get_mock_player_profile()
		_saved_profile = IdentityServiceScript.new().apply_dev_overrides_to_profile(loaded_profile)
		_loaded_save_suffix = save_suffix
	return _saved_profile.duplicate(true)

func save_current_profile(profile: Dictionary) -> void:
	var save_suffix: String = IdentityServiceScript.dev_save_suffix()
	var resolved_profile: Dictionary = IdentityServiceScript.new().apply_dev_overrides_to_profile(profile)
	_saved_profile = Dictionary(SaveManagerScript.profile_to_save_data(resolved_profile).get("player_profile", {}))
	_loaded_save_suffix = save_suffix
	SaveManagerScript.save_profile_save(_saved_profile, save_suffix)

func apply_server_profile_snapshot(profile_snapshot: Dictionary, wallet_snapshot: Dictionary = {}, unlocked_avatar_ids: Array = [], daily_login_awarded: bool = false) -> Dictionary:
	var profile := get_current_profile()
	if not profile_snapshot.is_empty():
		var nested_wallet := Dictionary(profile_snapshot.get("wallet", {}))
		if not nested_wallet.is_empty():
			wallet_snapshot = nested_wallet
		var nested_unlocks := Array(profile_snapshot.get("unlocked_avatar_ids", []))
		if not nested_unlocks.is_empty():
			unlocked_avatar_ids = nested_unlocks
		profile["player_id"] = String(profile_snapshot.get("player_id", profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID)))
		if profile_snapshot.has("created_at"):
			profile["created_at"] = str(profile_snapshot.get("created_at", profile.get("created_at", "")))
		if profile_snapshot.has("updated_at"):
			profile["updated_at"] = str(profile_snapshot.get("updated_at", profile.get("updated_at", "")))
		var progression := Dictionary(profile_snapshot.get("progression", {}))
		if progression.has("total_xp"):
			profile["total_xp"] = int(progression.get("total_xp", profile.get("total_xp", 0)))
			profile["xp_current"] = PlayerProfileScript.xp_current_for_total_xp(int(profile["total_xp"]))
			profile["xp_max"] = PlayerProfileScript.XP_PER_LEVEL
			profile["xp_text"] = "%d / %d XP" % [int(profile["xp_current"]), PlayerProfileScript.XP_PER_LEVEL]
		if progression.has("level"):
			profile["level"] = int(progression.get("level", profile.get("level", PlayerProfileScript.DEFAULT_LEVEL)))
		if progression.has("title_id"):
			var server_title_id := str(progression.get("title_id", profile.get("title_id", "new_player")))
			profile["title_id"] = server_title_id
			profile["current_title_name"] = server_title_id
			profile["title"] = server_title_id
		var statistics := Dictionary(profile_snapshot.get("statistics", {}))
		if statistics.has("hands_played"):
			profile["hands_played"] = int(statistics.get("hands_played", profile.get("hands_played", 0)))
			profile["total_hands_played"] = int(profile["hands_played"])
		if statistics.has("hands_won"):
			profile["hands_won"] = int(statistics.get("hands_won", profile.get("hands_won", 0)))
			profile["total_hands_won"] = int(profile["hands_won"])
		if statistics.has("chips_won"):
			profile["chips_won"] = int(statistics.get("chips_won", profile.get("chips_won", 0)))
		if statistics.has("gems_won"):
			profile["gems_won"] = int(statistics.get("gems_won", profile.get("gems_won", 0)))
		var daily_status := Dictionary(profile_snapshot.get("daily_bonus", {}))
		if not daily_status.is_empty():
			profile["daily_bonus_claim_count"] = int(daily_status.get("claim_count", profile.get("daily_bonus_claim_count", 0)))
			profile["daily_bonus_cycle_day"] = int(daily_status.get("cycle_day", daily_status.get("current_day", profile.get("daily_bonus_cycle_day", 1))))
			profile["daily_bonus_claimed_days_in_cycle"] = int(daily_status.get("claimed_days_in_cycle", profile.get("daily_bonus_claimed_days_in_cycle", 0)))
			profile["daily_bonus_can_claim_today"] = bool(daily_status.get("can_claim_today", profile.get("daily_bonus_can_claim_today", false)))
			profile["daily_bonus_status_synced"] = true
			profile["daily_reward_claimed_today"] = bool(daily_status.get("already_claimed_today", profile.get("daily_reward_claimed_today", false)))
			if bool(profile["daily_reward_claimed_today"]) and daily_status.has("claim_date"):
				profile["last_daily_reward_date"] = str(daily_status.get("claim_date", profile.get("last_daily_reward_date", "")))
		if profile_snapshot.has("daily_bonus_claim_count"):
			profile["daily_bonus_claim_count"] = int(profile_snapshot.get("daily_bonus_claim_count", profile.get("daily_bonus_claim_count", 0)))
		if profile_snapshot.has("daily_bonus_cycle_day"):
			profile["daily_bonus_cycle_day"] = int(profile_snapshot.get("daily_bonus_cycle_day", profile.get("daily_bonus_cycle_day", 1)))
		if profile_snapshot.has("daily_bonus_claimed_days_in_cycle"):
			profile["daily_bonus_claimed_days_in_cycle"] = int(profile_snapshot.get("daily_bonus_claimed_days_in_cycle", profile.get("daily_bonus_claimed_days_in_cycle", 0)))
		if profile_snapshot.has("daily_bonus_can_claim_today"):
			profile["daily_bonus_can_claim_today"] = bool(profile_snapshot.get("daily_bonus_can_claim_today", false))
		if profile_snapshot.has("daily_bonus_status_synced"):
			profile["daily_bonus_status_synced"] = bool(profile_snapshot.get("daily_bonus_status_synced", false))
		if profile_snapshot.has("daily_reward_claimed_today"):
			profile["daily_reward_claimed_today"] = bool(profile_snapshot.get("daily_reward_claimed_today", false))
		if profile_snapshot.has("last_daily_reward_date"):
			profile["last_daily_reward_date"] = str(profile_snapshot.get("last_daily_reward_date", profile.get("last_daily_reward_date", "")))
		var display_name := String(profile_snapshot.get("display_name", profile_snapshot.get("player_name", profile_snapshot.get("name", "")))).strip_edges()
		if display_name != "":
			profile["name"] = display_name
			profile["player_name"] = display_name
		if profile_snapshot.has("avatar_id"):
			var avatar_id := _client_avatar_id_for_server_id(String(profile_snapshot.get("avatar_id", PlayerProfileScript.get_avatar_id(profile))))
			profile["avatar_id"] = avatar_id
			profile["selected_avatar_id"] = avatar_id
			profile["avatar"] = AvatarLibraryScript.avatar_path(avatar_id)
		if profile_snapshot.has("is_new_player"):
			profile["is_new_player"] = bool(profile_snapshot.get("is_new_player", false))
	if not wallet_snapshot.is_empty():
		profile["total_chips"] = int(wallet_snapshot.get("chips", PlayerProfileScript.get_total_chips(profile)))
		profile["chips"] = int(profile["total_chips"])
		profile["gems"] = int(wallet_snapshot.get("gems", PlayerProfileScript.get_total_gems(profile)))
	if not unlocked_avatar_ids.is_empty():
		var normalized_unlocked := _normalize_server_avatar_ids(unlocked_avatar_ids)
		profile["unlocked_avatar_ids"] = normalized_unlocked
		var selected_id: String = PlayerProfileScript.get_avatar_id(profile)
		if not normalized_unlocked.has(selected_id):
			profile["selected_avatar_id"] = normalized_unlocked[0]
			profile["avatar_id"] = normalized_unlocked[0]
			profile["avatar"] = AvatarLibraryScript.avatar_path(normalized_unlocked[0])
	if daily_login_awarded:
		_grant_daily_login_xp(profile, _today_key(), PlayerProfileScript.DAILY_LOGIN_XP)
		profile["last_daily_reward_date"] = _today_key()
		profile["daily_reward_claimed_today"] = true
	_server_profile_synced = true
	_last_daily_bonus_claimed = daily_login_awarded
	save_current_profile(profile)
	return get_current_profile()

func apply_server_wallet_snapshot(wallet_snapshot: Dictionary) -> Dictionary:
	if wallet_snapshot.is_empty():
		return get_current_profile()
	var profile := get_current_profile()
	profile["total_chips"] = int(wallet_snapshot.get("chips", PlayerProfileScript.get_total_chips(profile)))
	profile["chips"] = int(profile["total_chips"])
	profile["gems"] = int(wallet_snapshot.get("gems", PlayerProfileScript.get_total_gems(profile)))
	_server_profile_synced = true
	save_current_profile(profile)
	return get_current_profile()

func apply_server_profile(profile_snapshot: Dictionary, wallet_snapshot: Dictionary = {}, unlocked_avatar_ids: Array = []) -> Dictionary:
	return apply_server_profile_snapshot(profile_snapshot, wallet_snapshot, unlocked_avatar_ids)

func apply_wallet_snapshot(wallet_snapshot: Dictionary) -> Dictionary:
	return apply_server_wallet_snapshot(wallet_snapshot)

func apply_avatar_unlocks(unlocked_avatar_ids: Array) -> Dictionary:
	if unlocked_avatar_ids.is_empty():
		return get_current_profile()
	var profile := get_current_profile()
	var normalized_unlocked := _normalize_server_avatar_ids(unlocked_avatar_ids)
	profile["unlocked_avatar_ids"] = normalized_unlocked
	var selected_id: String = PlayerProfileScript.get_avatar_id(profile)
	if not normalized_unlocked.has(selected_id):
		profile["selected_avatar_id"] = normalized_unlocked[0]
		profile["avatar_id"] = normalized_unlocked[0]
		profile["avatar"] = AvatarLibraryScript.avatar_path(normalized_unlocked[0])
	_server_profile_synced = true
	save_current_profile(profile)
	return get_current_profile()

func apply_session_profit(profit: int) -> Dictionary:
	var profile := get_current_profile()
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	profile["total_chips"] = max(total_chips + profit, 0)
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return get_current_profile()

func apply_session_result(session_result: Dictionary) -> Dictionary:
	if _is_practice_session_result(session_result):
		_last_unlocked_avatar_ids.clear()
		return get_current_profile()
	var profile := get_current_profile()
	var profit: int = int(session_result.get("session_profit", session_result.get("profit", 0)))
	var final_table_chips: int = int(session_result.get("session_end_chips", session_result.get("final_chips", 0)))
	var currency: String = str(session_result.get("currency", "chips"))
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	var previous_sessions: int = int(profile.get("total_sessions_played", 0))
	var previous_hands_won: int = int(profile.get("total_hands_won", 0))
	if currency in ["gem", "gems"] and bool(session_result.get("buy_in_deducted_from_wallet", false)):
		profile["gems"] = max(PlayerProfileScript.get_total_gems(profile) + final_table_chips, 0)
	elif bool(session_result.get("buy_in_deducted_from_wallet", false)):
		profile["total_chips"] = max(total_chips + final_table_chips, 0)
	else:
		profile["total_chips"] = max(total_chips + profit, 0)
	profile["chips"] = int(profile["total_chips"])
	profile["total_sessions_played"] = int(profile.get("total_sessions_played", 0)) + 1
	profile["total_hands_played"] = int(profile.get("total_hands_played", 0)) + int(session_result.get("hands_played", 0))
	profile["total_hands_won"] = int(profile.get("total_hands_won", 0)) + int(session_result.get("hands_won", 0))
	profile["total_profit"] = int(profile.get("total_profit", 0)) + profit
	profile["biggest_pot"] = max(int(profile.get("biggest_pot", 0)), int(session_result.get("biggest_pot", 0)))
	profile["best_session_profit"] = max(int(profile.get("best_session_profit", 0)), profit)
	var session_best_hand: String = String(session_result.get("best_hand_desc", ""))
	if session_best_hand != "" and session_best_hand != "-":
		profile["best_hand_desc"] = session_best_hand
	_last_unlocked_avatar_ids = _unlock_avatars_for_session(profile, session_result, previous_sessions, previous_hands_won)
	save_current_profile(profile)
	return get_current_profile()

func _is_practice_session_result(session_result: Dictionary) -> bool:
	if String(session_result.get("mode", "")) == "training":
		return true
	if String(session_result.get("table_type", "")) == "training_ai":
		return true
	if bool(session_result.get("uses_practice_chips", false)):
		return true
	return not bool(session_result.get("affects_account_balance", true))

func select_avatar(avatar_id: String) -> Dictionary:
	var profile := get_current_profile()
	var unlocked: Array = Array(profile.get("unlocked_avatar_ids", []))
	if not unlocked.has(avatar_id):
		push_warning("[ProfileService] Cannot select locked avatar: %s" % avatar_id)
		return profile
	profile["selected_avatar_id"] = avatar_id
	profile["avatar_id"] = avatar_id
	profile["avatar"] = AvatarLibraryScript.avatar_path(avatar_id)
	save_current_profile(profile)
	return get_current_profile()

func purchase_avatar_with_chips(avatar_id: String, price_chips: int = AvatarLibraryScript.DEFAULT_AVATAR_PRICE_CHIPS) -> Dictionary:
	var clean_id := avatar_id.strip_edges()
	var profile := get_current_profile()
	if clean_id == "":
		return {"success": false, "reason": "missing_avatar_id", "profile": profile}
	var unlocked: Array = Array(profile.get("unlocked_avatar_ids", [])).duplicate()
	if unlocked.has(clean_id):
		profile["selected_avatar_id"] = clean_id
		profile["avatar_id"] = clean_id
		profile["avatar"] = AvatarLibraryScript.avatar_path(clean_id)
		save_current_profile(profile)
		return {"success": true, "reason": "already_unlocked", "profile": get_current_profile()}
	var cost: int = max(price_chips, 0)
	var chips: int = PlayerProfileScript.get_total_chips(profile)
	if chips < cost:
		return {"success": false, "reason": "not_enough_chips", "required_chips": cost, "wallet_chips": chips, "profile": profile}
	profile["total_chips"] = chips - cost
	profile["chips"] = int(profile["total_chips"])
	unlocked.append(clean_id)
	profile["unlocked_avatar_ids"] = unlocked
	profile["selected_avatar_id"] = clean_id
	profile["avatar_id"] = clean_id
	profile["avatar"] = AvatarLibraryScript.avatar_path(clean_id)
	save_current_profile(profile)
	return {"success": true, "reason": "purchased", "profile": get_current_profile()}

func deduct_table_buy_in(buy_in: int) -> Dictionary:
	return deduct_table_buy_in_currency(buy_in, "chips")

func deduct_table_buy_in_currency(buy_in: int, currency: String = "chips") -> Dictionary:
	if buy_in <= 0:
		return get_current_profile()
	var profile := get_current_profile()
	if currency in ["gem", "gems"]:
		var total_gems: int = PlayerProfileScript.get_total_gems(profile)
		if total_gems < buy_in:
			push_warning("[ProfileService] Cannot deduct buy-in %d from wallet gems %d." % [buy_in, total_gems])
			return {}
		profile["gems"] = total_gems - buy_in
		save_current_profile(profile)
		return get_current_profile()
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	if total_chips < buy_in:
		push_warning("[ProfileService] Cannot deduct buy-in %d from wallet chips %d." % [buy_in, total_chips])
		return {}
	profile["total_chips"] = total_chips - buy_in
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return get_current_profile()

func transfer_chips_to_table(amount: int) -> Dictionary:
	if amount <= 0:
		return {"success": false, "amount": 0, "profile": get_current_profile()}
	var profile := get_current_profile()
	var available: int = PlayerProfileScript.get_total_chips(profile)
	var transfer_amount: int = min(amount, available)
	if transfer_amount <= 0:
		return {"success": false, "amount": 0, "profile": profile}
	profile["total_chips"] = available - transfer_amount
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return {"success": true, "amount": transfer_amount, "profile": get_current_profile()}

func refund_table_chips(amount: int) -> Dictionary:
	return refund_table_currency(amount, "chips")

func refund_table_currency(amount: int, currency: String = "chips") -> Dictionary:
	if amount <= 0:
		return get_current_profile()
	var profile := get_current_profile()
	if currency in ["gem", "gems"]:
		var total_gems: int = PlayerProfileScript.get_total_gems(profile)
		profile["gems"] = total_gems + amount
		save_current_profile(profile)
		return get_current_profile()
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	profile["total_chips"] = total_chips + amount
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return get_current_profile()

func mock_purchase_chips(amount: int) -> Dictionary:
	if amount <= 0:
		return get_current_profile()
	var profile := get_current_profile()
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	profile["total_chips"] = total_chips + amount
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return get_current_profile()

func mock_purchase_gems(amount: int) -> Dictionary:
	if amount <= 0:
		return get_current_profile()
	var profile := get_current_profile()
	var total_gems: int = PlayerProfileScript.get_total_gems(profile)
	profile["gems"] = total_gems + amount
	save_current_profile(profile)
	return get_current_profile()

func is_replay_unlocked(replay_id: String) -> bool:
	var clean_id := replay_id.strip_edges()
	if clean_id == "":
		return false
	var profile := get_current_profile()
	return Array(profile.get("unlocked_replay_ids", [])).has(clean_id)

func unlock_replay(replay_id: String, cost_gems: int = PlayerProfileScript.REPLAY_UNLOCK_COST_GEMS) -> Dictionary:
	var clean_id := replay_id.strip_edges()
	var profile := get_current_profile()
	if clean_id == "":
		return {"success": false, "reason": "missing_replay_id", "profile": profile}
	var unlocked: Array = Array(profile.get("unlocked_replay_ids", [])).duplicate()
	if unlocked.has(clean_id):
		return {"success": true, "reason": "already_unlocked", "profile": profile}
	var available_gems: int = PlayerProfileScript.get_total_gems(profile)
	if available_gems < cost_gems:
		return {"success": false, "reason": "not_enough_gems", "profile": profile}
	profile["gems"] = available_gems - cost_gems
	unlocked.append(clean_id)
	profile["unlocked_replay_ids"] = unlocked
	save_current_profile(profile)
	return {"success": true, "reason": "unlocked", "profile": get_current_profile()}

func claim_daily_login_bonus(today: String = "") -> Dictionary:
	var profile := get_current_profile()
	if _server_profile_synced:
		_last_daily_bonus_claimed = false
		_last_daily_bonus_reward = {}
		return profile
	var date_key: String = today if today != "" else _today_key()
	var already_claimed: bool = String(profile.get("last_daily_reward_date", "")) == date_key and bool(profile.get("daily_reward_claimed_today", false))
	_last_daily_bonus_claimed = false
	_last_daily_bonus_reward = {}
	if already_claimed:
		return profile
	var reward_day: int = PlayerProfileScript.next_daily_bonus_day(profile)
	var reward: Dictionary = PlayerProfileScript.daily_bonus_reward_for_day(reward_day)
	var chips_awarded: int = int(reward.get("chips", 0))
	var xp_awarded: int = int(reward.get("xp", 0))
	var gems_awarded: int = int(reward.get("gems", 0))
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	profile["total_chips"] = total_chips + chips_awarded
	profile["chips"] = int(profile["total_chips"])
	profile["gems"] = PlayerProfileScript.get_total_gems(profile) + gems_awarded
	_grant_daily_login_xp(profile, date_key, xp_awarded)
	profile["daily_bonus_claim_count"] = max(int(profile.get("daily_bonus_claim_count", 0)), 0) + 1
	var completed_in_cycle: int = int(profile["daily_bonus_claim_count"]) % PlayerProfileScript.DAILY_BONUS_REWARDS.size()
	profile["daily_bonus_cycle_day"] = reward_day
	profile["daily_bonus_claimed_days_in_cycle"] = reward_day if completed_in_cycle == 0 else completed_in_cycle
	profile["daily_bonus_can_claim_today"] = false
	profile["daily_bonus_status_synced"] = false
	profile["last_daily_reward_date"] = date_key
	profile["daily_reward_claimed_today"] = true
	save_current_profile(profile)
	_last_daily_bonus_claimed = true
	_last_daily_bonus_reward = {
		"day": reward_day,
		"chips": chips_awarded,
		"xp": xp_awarded,
		"gems": gems_awarded,
		"profile": get_current_profile(),
	}
	print("Daily Bonus Day %d: +%d Chips, +%d XP, +%d Gems" % [reward_day, chips_awarded, xp_awarded, gems_awarded])
	return get_current_profile()

func was_last_daily_bonus_claimed() -> bool:
	return _last_daily_bonus_claimed

func get_last_daily_bonus_reward() -> Dictionary:
	return _last_daily_bonus_reward.duplicate(true)

func get_last_unlocked_avatar_ids() -> Array[String]:
	return _last_unlocked_avatar_ids.duplicate()

static func reset_mock_profile() -> void:
	_saved_profile = IdentityServiceScript.new().apply_dev_overrides_to_profile(MockDataProviderScript.get_mock_player_profile())
	_loaded_save_suffix = IdentityServiceScript.dev_save_suffix()
	_last_unlocked_avatar_ids.clear()
	_last_daily_bonus_claimed = false
	_last_daily_bonus_reward = {}
	_server_profile_synced = false

func _unlock_avatars_for_session(profile: Dictionary, session_result: Dictionary, previous_sessions: int, previous_hands_won: int) -> Array[String]:
	var unlocked: Array = Array(profile.get("unlocked_avatar_ids", [])).duplicate()
	var new_ids: Array[String] = []
	if previous_sessions == 0:
		_try_unlock_avatar_for_rule("first_session_complete", unlocked, new_ids)
	if int(session_result.get("hands_won", 0)) > 0 and previous_hands_won == 0:
		_try_unlock_avatar_for_rule("first_hand_win", unlocked, new_ids)
	if int(profile.get("total_hands_won", 0)) >= 5:
		_try_unlock_avatar_for_rule("five_hands_won", unlocked, new_ids)
	if int(profile.get("biggest_pot", 0)) >= 5000:
		_try_unlock_avatar_for_rule("big_pot_5000", unlocked, new_ids)
	if int(session_result.get("session_profit", session_result.get("profit", 0))) > 0:
		_try_unlock_avatar_for_rule("profitable_session", unlocked, new_ids)
	profile["unlocked_avatar_ids"] = unlocked
	return new_ids

func _try_unlock_avatar_for_rule(rule_id: String, unlocked: Array, new_ids: Array[String]) -> void:
	var avatar_id: String = AvatarLibraryScript.resolve_unlock_avatar_id(rule_id, unlocked)
	if avatar_id == "":
		return
	unlocked.append(avatar_id)
	new_ids.append(avatar_id)

func apply_server_daily_login_xp_award(today: String = "", xp_awarded: int = PlayerProfileScript.DAILY_LOGIN_XP, gems_awarded: int = 0) -> Dictionary:
	var profile := get_current_profile()
	var date_key: String = today if today != "" else _today_key()
	_grant_daily_login_xp(profile, date_key, xp_awarded)
	if gems_awarded > 0:
		profile["gems"] = PlayerProfileScript.get_total_gems(profile) + gems_awarded
	profile["last_daily_reward_date"] = date_key
	profile["daily_reward_claimed_today"] = true
	save_current_profile(profile)
	return get_current_profile()

func _grant_daily_login_xp(profile: Dictionary, date_key: String, xp_awarded: int) -> void:
	if String(profile.get("last_daily_reward_xp_date", "")) == date_key:
		_refresh_progression_fields(profile)
		return
	var total_xp: int = PlayerProfileScript.get_total_xp(profile) + max(xp_awarded, 0)
	profile["total_xp"] = total_xp
	profile["last_daily_reward_xp_date"] = date_key
	_refresh_progression_fields(profile)

func _refresh_progression_fields(profile: Dictionary) -> void:
	var total_xp: int = PlayerProfileScript.get_total_xp(profile)
	var level: int = PlayerProfileScript.level_for_total_xp(total_xp)
	profile["total_xp"] = total_xp
	profile["level"] = level
	profile["xp_current"] = PlayerProfileScript.xp_current_for_total_xp(total_xp)
	profile["xp_max"] = PlayerProfileScript.XP_PER_LEVEL
	profile["xp_text"] = "%d / %d XP" % [int(profile["xp_current"]), PlayerProfileScript.XP_PER_LEVEL]
	profile["current_title_name"] = PlayerProfileScript.title_for_level(level)
	profile["title"] = profile["current_title_name"]

func is_profile_backend_available() -> bool:
	return _server_profile_synced

func _normalize_server_avatar_ids(unlocked_avatar_ids: Array) -> Array[String]:
	var result: Array[String] = []
	for item in unlocked_avatar_ids:
		var avatar_id := _client_avatar_id_for_server_id(String(item))
		if avatar_id != "" and not result.has(avatar_id):
			result.append(avatar_id)
	if result.is_empty():
		result.append_array(AvatarLibraryScript.default_unlocked_avatar_ids())
	return result

func _client_avatar_id_for_server_id(server_avatar_id: String) -> String:
	var avatar_id := server_avatar_id.strip_edges()
	if avatar_id == "" or avatar_id == "default":
		avatar_id = PlayerProfileScript.DEFAULT_AVATAR_ID
	if not ResourceLoader.exists(AvatarLibraryScript.avatar_path(avatar_id)):
		avatar_id = PlayerProfileScript.DEFAULT_AVATAR_ID
	return avatar_id

func _today_key() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(now.get("year", 0)), int(now.get("month", 0)), int(now.get("day", 0))]
