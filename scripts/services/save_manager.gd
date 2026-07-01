extends RefCounted
class_name SaveManager

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

const DEFAULT_SAVE_PATH := "user://save_data.json"

static func profile_to_save_data(profile: Dictionary) -> Dictionary:
	return {
		"schema_version": PlayerProfileScript.SCHEMA_VERSION,
		"player_profile": PlayerProfileScript.normalized_dict(profile),
	}

static func migrate_profile_save(save_data: Dictionary) -> Dictionary:
	var profile_data: Dictionary = {}
	if save_data.has("player_profile"):
		profile_data = Dictionary(save_data.get("player_profile", {}))
	else:
		profile_data = save_data.duplicate(true)
	return PlayerProfileScript.normalized_dict(profile_data)

static func profile_save_path(save_suffix: String = "") -> String:
	var clean_suffix: String = _sanitize_save_suffix(save_suffix)
	if clean_suffix == "":
		return DEFAULT_SAVE_PATH
	return "user://save_data_%s.json" % clean_suffix

static func load_profile_save(save_suffix: String = "") -> Dictionary:
	var path: String = profile_save_path(save_suffix)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[SaveManager] Could not open profile save: %s" % path)
		return {}
	var payload: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Ignoring invalid profile save: %s" % path)
		return {}
	return migrate_profile_save(Dictionary(parsed))

static func save_profile_save(profile: Dictionary, save_suffix: String = "") -> void:
	var path: String = profile_save_path(save_suffix)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("[SaveManager] Could not write profile save: %s" % path)
		return
	file.store_string(JSON.stringify(profile_to_save_data(profile), "\t"))

static func _sanitize_save_suffix(value: String) -> String:
	var clean: String = ""
	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		var code: int = character.unicode_at(0)
		var is_digit: bool = code >= 48 and code <= 57
		var is_upper: bool = code >= 65 and code <= 90
		var is_lower: bool = code >= 97 and code <= 122
		if is_digit or is_upper or is_lower or character == "_" or character == "-":
			clean += character
	return clean
