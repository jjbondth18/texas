extends RefCounted
class_name IdentityService

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

const PROVIDER_LOCAL_DEV := "local_dev"
const ARG_DEV_PLAYER_ID := "dev-player-id"
const ARG_DEV_PLAYER_NAME := "dev-player-name"
const ARG_DEV_SAVE_SUFFIX := "dev-save-suffix"
const ENV_DEV_PLAYER_ID := "TEXAS_DEV_PLAYER_ID"
const ENV_DEV_PLAYER_NAME := "TEXAS_DEV_PLAYER_NAME"
const ENV_DEV_SAVE_SUFFIX := "TEXAS_DEV_SAVE_SUFFIX"


func get_identity(profile: Dictionary = {}) -> Dictionary:
	var resolved_profile: Dictionary = apply_dev_overrides_to_profile(profile)
	var local_player_id: String = String(resolved_profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID)).strip_edges()
	if local_player_id == "":
		local_player_id = PlayerProfileScript.DEFAULT_PLAYER_ID
	var display_name: String = PlayerProfileScript.get_player_name(resolved_profile)
	if display_name == "":
		display_name = PlayerProfileScript.DEFAULT_PLAYER_NAME
	return {
		"provider": PROVIDER_LOCAL_DEV,
		"external_id": local_player_id,
		"display_name": display_name,
		"avatar_id": PlayerProfileScript.get_avatar_id(resolved_profile),
		"save_suffix": dev_save_suffix(),
		"has_dev_override": has_dev_override(),
	}


func apply_dev_overrides_to_profile(profile: Dictionary) -> Dictionary:
	var resolved: Dictionary = profile.duplicate(true)
	if resolved.is_empty():
		resolved = {
			"player_id": PlayerProfileScript.DEFAULT_PLAYER_ID,
			"name": PlayerProfileScript.DEFAULT_PLAYER_NAME,
			"player_name": PlayerProfileScript.DEFAULT_PLAYER_NAME,
			"avatar_id": PlayerProfileScript.DEFAULT_AVATAR_ID,
			"selected_avatar_id": PlayerProfileScript.DEFAULT_AVATAR_ID,
		}
	var override_id: String = dev_player_id()
	if override_id != "":
		resolved["player_id"] = override_id
	elif String(resolved.get("player_id", "")).strip_edges() == "":
		resolved["player_id"] = PlayerProfileScript.DEFAULT_PLAYER_ID
	var override_name: String = dev_player_name()
	if override_name != "":
		resolved["name"] = override_name
		resolved["player_name"] = override_name
	elif PlayerProfileScript.get_player_name(resolved) == "":
		resolved["name"] = PlayerProfileScript.DEFAULT_PLAYER_NAME
		resolved["player_name"] = PlayerProfileScript.DEFAULT_PLAYER_NAME
	var suffix: String = dev_save_suffix()
	if suffix != "":
		resolved["dev_save_suffix"] = suffix
	return resolved


static func has_dev_override() -> bool:
	return dev_player_id() != "" or dev_player_name() != "" or dev_save_suffix() != ""


static func dev_player_id() -> String:
	return _dev_override(ARG_DEV_PLAYER_ID, ENV_DEV_PLAYER_ID)


static func dev_player_name() -> String:
	return _dev_override(ARG_DEV_PLAYER_NAME, ENV_DEV_PLAYER_NAME)


static func dev_save_suffix() -> String:
	return _sanitize_save_suffix(_dev_override(ARG_DEV_SAVE_SUFFIX, ENV_DEV_SAVE_SUFFIX))


static func _dev_override(arg_name: String, env_name: String) -> String:
	var args: Array = _all_cmdline_args()
	var equals_prefix: String = "--%s=" % arg_name
	var flag_name: String = "--%s" % arg_name
	for index in range(args.size()):
		var arg: String = String(args[index])
		if arg.begins_with(equals_prefix):
			return arg.substr(equals_prefix.length()).strip_edges()
		if arg == flag_name and index + 1 < args.size():
			return String(args[index + 1]).strip_edges()
	var env_value: String = OS.get_environment(env_name).strip_edges()
	return env_value


static func _all_cmdline_args() -> Array:
	var args: Array = OS.get_cmdline_args()
	if OS.has_method("get_cmdline_user_args"):
		args.append_array(OS.get_cmdline_user_args())
	return args


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
