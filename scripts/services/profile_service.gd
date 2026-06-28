extends RefCounted
class_name ProfileService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const SaveManagerScript := preload("res://scripts/services/save_manager.gd")
const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")

static var _saved_profile: Dictionary = {}
static var _last_unlocked_avatar_ids: Array[String] = []

func get_current_profile() -> Dictionary:
	if _saved_profile.is_empty():
		_saved_profile = MockDataProviderScript.get_mock_player_profile()
	return _saved_profile.duplicate(true)

func save_current_profile(profile: Dictionary) -> void:
	_saved_profile = SaveManagerScript.profile_to_save_data(profile).get("player_profile", {})

func apply_session_profit(profit: int) -> Dictionary:
	var profile := get_current_profile()
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	profile["total_chips"] = max(total_chips + profit, 0)
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return get_current_profile()

func apply_session_result(session_result: Dictionary) -> Dictionary:
	var profile := get_current_profile()
	var profit: int = int(session_result.get("session_profit", session_result.get("profit", 0)))
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	var previous_sessions: int = int(profile.get("total_sessions_played", 0))
	var previous_hands_won: int = int(profile.get("total_hands_won", 0))
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

func get_last_unlocked_avatar_ids() -> Array[String]:
	return _last_unlocked_avatar_ids.duplicate()

static func reset_mock_profile() -> void:
	_saved_profile = MockDataProviderScript.get_mock_player_profile()
	_last_unlocked_avatar_ids.clear()

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

func is_profile_backend_available() -> bool:
	return false
