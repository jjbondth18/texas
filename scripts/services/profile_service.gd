extends RefCounted
class_name ProfileService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")

func get_current_profile() -> Dictionary:
	return MockDataProviderScript.get_mock_player_profile()

func is_profile_backend_available() -> bool:
	return false
