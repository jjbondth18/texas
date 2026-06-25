extends RefCounted
class_name NetworkService

enum BackendMode {
	OFFLINE_MOCK,
	STEAM_P2P_PLACEHOLDER,
	DEDICATED_SERVER_PLACEHOLDER,
}

var backend_mode := BackendMode.OFFLINE_MOCK

func is_online_backend_available() -> bool:
	return false

func get_backend_mode() -> BackendMode:
	return backend_mode

func connect_to_backend() -> bool:
	return false

func disconnect_from_backend() -> void:
	pass
