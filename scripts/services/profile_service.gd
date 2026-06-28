extends RefCounted
class_name ProfileService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

static var _saved_profile: Dictionary = {}

func get_current_profile() -> Dictionary:
	if _saved_profile.is_empty():
		_saved_profile = MockDataProviderScript.get_mock_player_profile()
	return _saved_profile.duplicate(true)

func save_current_profile(profile: Dictionary) -> void:
	_saved_profile = PlayerProfileScript.normalized_dict(profile)

func apply_session_profit(profit: int) -> Dictionary:
	var profile := get_current_profile()
	var total_chips: int = PlayerProfileScript.get_total_chips(profile)
	profile["total_chips"] = max(total_chips + profit, 0)
	profile["chips"] = int(profile["total_chips"])
	save_current_profile(profile)
	return get_current_profile()

static func reset_mock_profile() -> void:
	_saved_profile = MockDataProviderScript.get_mock_player_profile()

func is_profile_backend_available() -> bool:
	return false
