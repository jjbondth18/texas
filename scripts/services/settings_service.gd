extends RefCounted
class_name SettingsService

const SETTINGS_PATH := "user://settings_preferences.cfg"

const DEFAULTS := {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"mute_all": false,
	"show_hand_hints": true,
	"auto_muck_losing_hands": true,
	"confirm_big_bets": true,
	"animation_speed": "normal",
	"window_mode": "windowed",
	"ui_scale": 1.0,
	"reduce_motion": false,
	"show_player_name": true,
	"allow_friend_invites": true,
	"server_region": "auto",
	"network_mode": "local_mock",
}

static var _settings_cache: Dictionary = {}
static var _settings_path := SETTINGS_PATH

func load_settings() -> Dictionary:
	if _settings_cache.is_empty():
		_settings_cache = _read_settings_file()
	return _settings_cache.duplicate(true)

func save_settings(settings: Dictionary) -> Dictionary:
	var normalized := normalize_settings(settings)
	_settings_cache = normalized.duplicate(true)
	var config := ConfigFile.new()
	for key in normalized.keys():
		config.set_value("settings", String(key), normalized[key])
	config.save(_settings_path)
	apply_safe_settings(normalized)
	return normalized.duplicate(true)

func reset_defaults() -> Dictionary:
	return save_settings(DEFAULTS)

func apply_safe_settings(settings: Dictionary) -> void:
	var normalized := normalize_settings(settings)
	var master := 0.0 if bool(normalized.get("mute_all", false)) else float(normalized.get("master_volume", 1.0))
	_apply_bus_volume("Master", master)
	_apply_bus_volume("Music", float(normalized.get("music_volume", 0.8)))
	_apply_bus_volume("SFX", float(normalized.get("sfx_volume", 0.8)))

static func default_settings() -> Dictionary:
	return DEFAULTS.duplicate(true)

static func normalize_settings(settings: Dictionary) -> Dictionary:
	var normalized := DEFAULTS.duplicate(true)
	for key in settings.keys():
		if not normalized.has(key):
			continue
		normalized[key] = settings[key]
	normalized["master_volume"] = clampf(float(normalized.get("master_volume", 1.0)), 0.0, 1.0)
	normalized["music_volume"] = clampf(float(normalized.get("music_volume", 0.8)), 0.0, 1.0)
	normalized["sfx_volume"] = clampf(float(normalized.get("sfx_volume", 0.8)), 0.0, 1.0)
	normalized["mute_all"] = bool(normalized.get("mute_all", false))
	normalized["show_hand_hints"] = bool(normalized.get("show_hand_hints", true))
	normalized["auto_muck_losing_hands"] = bool(normalized.get("auto_muck_losing_hands", true))
	normalized["confirm_big_bets"] = bool(normalized.get("confirm_big_bets", true))
	normalized["animation_speed"] = _normalized_choice(String(normalized.get("animation_speed", "normal")), ["slow", "normal", "fast"], "normal")
	normalized["window_mode"] = _normalized_choice(String(normalized.get("window_mode", "windowed")), ["windowed", "fullscreen", "borderless"], "windowed")
	normalized["ui_scale"] = _normalized_ui_scale(float(normalized.get("ui_scale", 1.0)))
	normalized["reduce_motion"] = bool(normalized.get("reduce_motion", false))
	normalized["show_player_name"] = bool(normalized.get("show_player_name", true))
	normalized["allow_friend_invites"] = bool(normalized.get("allow_friend_invites", true))
	normalized["server_region"] = _normalized_choice(String(normalized.get("server_region", "auto")), ["auto", "us_east", "us_west", "asia"], "auto")
	normalized["network_mode"] = _normalized_choice(String(normalized.get("network_mode", "local_mock")), ["local_mock", "future_server"], "local_mock")
	return normalized

static func reset_for_tests(path: String = "", remove_file: bool = true) -> void:
	_settings_cache.clear()
	_settings_path = path if path != "" else SETTINGS_PATH
	if path != "" and remove_file:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _read_settings_file() -> Dictionary:
	var config := ConfigFile.new()
	var result := config.load(_settings_path)
	if result != OK:
		return DEFAULTS.duplicate(true)
	var settings := DEFAULTS.duplicate(true)
	for key in DEFAULTS.keys():
		settings[key] = config.get_value("settings", String(key), DEFAULTS[key])
	return normalize_settings(settings)

func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var safe_volume := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, -80.0 if safe_volume <= 0.0 else linear_to_db(safe_volume))

static func _normalized_choice(value: String, allowed: Array, fallback: String) -> String:
	return value if allowed.has(value) else fallback

static func _normalized_ui_scale(value: float) -> float:
	var closest := 1.0
	var closest_delta := 99.0
	for option in [0.9, 1.0, 1.1, 1.2]:
		var delta: float = absf(value - float(option))
		if delta < closest_delta:
			closest_delta = delta
			closest = float(option)
	return closest
