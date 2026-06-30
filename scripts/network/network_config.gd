extends RefCounted
class_name NetworkConfig

const DEFAULT_SERVER_URL := "ws://127.0.0.1:8080"

static func server_url() -> String:
	var configured := String(ProjectSettings.get_setting("texas/network/server_url", DEFAULT_SERVER_URL)).strip_edges()
	return configured if configured != "" else DEFAULT_SERVER_URL
