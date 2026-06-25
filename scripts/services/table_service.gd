extends RefCounted
class_name TableService

const MockDataProviderScript := preload("res://scripts/demo/mock_data_provider.gd")

func get_table_state(_table_id: String = "mock_table_001") -> Dictionary:
	return MockDataProviderScript.get_table_view_model()

func can_join_table(_table_id: String) -> bool:
	return true
