extends RefCounted
class_name SteamIdentityProvider

const PROVIDER_STEAM := "steam"


func get_identity() -> Dictionary:
	if not Engine.has_singleton("Steam"):
		return _unavailable("steam_singleton_missing")
	var steam := Engine.get_singleton("Steam")
	if steam == null:
		return _unavailable("steam_singleton_null")
	var init_result: Variant = _try_initialize(steam)
	if not _is_init_success(init_result):
		return _unavailable("steam_init_failed")
	if not _is_steam_running(steam):
		return _unavailable("steam_not_running")
	if not _is_user_logged_on(steam):
		return _unavailable("steam_user_not_logged_on")
	var steam_id: String = _steam_id(steam)
	if steam_id == "" or steam_id == "0":
		return _unavailable("steam_id_missing")
	var persona_name: String = _persona_name(steam)
	if persona_name == "":
		persona_name = "Steam Player"
	return {
		"available": true,
		"provider": PROVIDER_STEAM,
		"external_id": steam_id,
		"display_name": persona_name,
		"avatar_id": "default",
	}


func _try_initialize(steam: Object) -> Variant:
	if steam.has_method("steamInit"):
		return steam.call("steamInit")
	if steam.has_method("init"):
		return steam.call("init")
	return true


func _is_init_success(result: Variant) -> bool:
	match typeof(result):
		TYPE_NIL:
			return true
		TYPE_BOOL:
			return bool(result)
		TYPE_INT:
			return int(result) == 1
		TYPE_DICTIONARY:
			var data: Dictionary = Dictionary(result)
			if data.has("status"):
				return int(data.get("status", 0)) == 1
			if data.has("success"):
				return bool(data.get("success", false))
			return true
		_:
			return true


func _is_steam_running(steam: Object) -> bool:
	if steam.has_method("isSteamRunning"):
		return bool(steam.call("isSteamRunning"))
	if steam.has_method("is_steam_running"):
		return bool(steam.call("is_steam_running"))
	return true


func _is_user_logged_on(steam: Object) -> bool:
	if steam.has_method("loggedOn"):
		return bool(steam.call("loggedOn"))
	if steam.has_method("isLoggedOn"):
		return bool(steam.call("isLoggedOn"))
	if steam.has_method("is_logged_on"):
		return bool(steam.call("is_logged_on"))
	return true


func _steam_id(steam: Object) -> String:
	var value: Variant = ""
	if steam.has_method("getSteamID"):
		value = steam.call("getSteamID")
	elif steam.has_method("getSteamID64"):
		value = steam.call("getSteamID64")
	elif steam.has_method("get_steam_id"):
		value = steam.call("get_steam_id")
	return str(value).strip_edges()


func _persona_name(steam: Object) -> String:
	var value: Variant = ""
	if steam.has_method("getPersonaName"):
		value = steam.call("getPersonaName")
	elif steam.has_method("getFriendPersonaName") and _steam_id(steam) != "":
		value = steam.call("getFriendPersonaName", int(_steam_id(steam)))
	elif steam.has_method("get_persona_name"):
		value = steam.call("get_persona_name")
	return str(value).strip_edges()


func _unavailable(reason: String) -> Dictionary:
	return {
		"available": false,
		"reason": reason,
	}
