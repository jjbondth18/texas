extends RefCounted
class_name BackendService

func create_quick_play_table(_profile: Dictionary) -> Dictionary:
	push_error("create_quick_play_table must be implemented by a backend.")
	return {}

func create_training_table(_profile: Dictionary) -> Dictionary:
	push_error("create_training_table must be implemented by a backend.")
	return {}

func create_friends_room(_profile: Dictionary) -> Dictionary:
	push_error("create_friends_room must be implemented by a backend.")
	return {}

func join_room(_room_id: String, _profile: Dictionary) -> Dictionary:
	push_error("join_room must be implemented by a backend.")
	return {}

func leave_room() -> void:
	pass

func get_current_table_context() -> Dictionary:
	return {}
