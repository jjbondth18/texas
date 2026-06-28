extends BackendService
class_name ServerBackend

func create_quick_play_table(_profile: Dictionary, _setup_config: Dictionary = {}) -> Dictionary:
	push_warning("[ServerBackend] Placeholder only. Remote server matchmaking is not implemented yet.")
	return {}

func create_training_table(_profile: Dictionary) -> Dictionary:
	push_warning("[ServerBackend] Training is local-only for now.")
	return {}

func create_friends_room(_profile: Dictionary) -> Dictionary:
	push_warning("[ServerBackend] Placeholder only. Remote rooms are not implemented yet.")
	return {}

func join_room(_room_id: String, _profile: Dictionary) -> Dictionary:
	push_warning("[ServerBackend] Placeholder only. Remote rooms are not implemented yet.")
	return {}
