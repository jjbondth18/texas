extends RefCounted
class_name ProfileService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const SaveManagerScript := preload("res://scripts/services/save_manager.gd")

static var _saved_profile: Dictionary = {}

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
	save_current_profile(profile)
	return get_current_profile()

static func reset_mock_profile() -> void:
	_saved_profile = MockDataProviderScript.get_mock_player_profile()

func is_profile_backend_available() -> bool:
	return false
