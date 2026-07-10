extends RefCounted
class_name NetworkConfig

const DEFAULT_SERVER_URL := "ws://127.0.0.1:8080"
const ENV_SERVER_URL := "TEXAS_SERVER_URL"
const PROJECT_SETTING_SERVER_URL := "texas/network/server_url"

static var _logged_server_url := false

static func server_url() -> String:
	var env_url := OS.get_environment(ENV_SERVER_URL).strip_edges()
	if env_url != "":
		_log_server_url_once(env_url, "env:%s" % ENV_SERVER_URL)
		return env_url

	var configured := String(ProjectSettings.get_setting(PROJECT_SETTING_SERVER_URL, "")).strip_edges()
	if configured != "":
		_log_server_url_once(configured, "project:%s" % PROJECT_SETTING_SERVER_URL)
		return configured

	_log_server_url_once(DEFAULT_SERVER_URL, "default")
	return DEFAULT_SERVER_URL

static func _log_server_url_once(url: String, source: String) -> void:
	if _logged_server_url:
		return
	_logged_server_url = true
	print("[NetworkConfig] server_url=%s source=%s" % [url, source])
