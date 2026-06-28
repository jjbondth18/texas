extends BackendService
class_name SteamLobbyBackend

func create_quick_play_table(_profile: Dictionary, _setup_config: Dictionary = {}) -> Dictionary:
	push_warning("[SteamLobbyBackend] Placeholder only. Use LocalMockBackend for current builds.")
	return {}

func create_training_table(_profile: Dictionary) -> Dictionary:
	push_warning("[SteamLobbyBackend] Training is local-only for now.")
	return {}

func create_friends_room(_profile: Dictionary) -> Dictionary:
	push_warning("[SteamLobbyBackend] Placeholder only. Steam lobbies are not implemented yet.")
	return {}

func join_room(_room_id: String, _profile: Dictionary) -> Dictionary:
	push_warning("[SteamLobbyBackend] Placeholder only. Steam lobbies are not implemented yet.")
	return {}
