extends RefCounted
class_name LobbyService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")

func get_lobby_view_model() -> Dictionary:
	return MockDataProviderScript.get_lobby_view_model()

func get_lobby_modes() -> Array:
	return MockDataProviderScript.get_lobby_view_model().get("modes", [])

func get_rooms() -> Array[Dictionary]:
	return MockDataProviderScript.get_mock_rooms()

func get_room_browser_view_model() -> Dictionary:
	return MockDataProviderScript.get_room_browser_view_model()
