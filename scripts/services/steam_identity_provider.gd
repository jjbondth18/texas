extends RefCounted
class_name SteamIdentityProvider

const PROVIDER_STEAM := "steam"
const STEAM_AUTH_IDENTITY := "texas-server-v1"

static var _cached_auth_ticket_hex := ""
static var _auth_ticket_handle: Variant = null


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
	var identity := {
		"available": true,
		"provider": PROVIDER_STEAM,
		"external_id": steam_id,
		"display_name": persona_name,
		"avatar_id": "default",
		"steam_auth_identity": STEAM_AUTH_IDENTITY,
	}
	var ticket_hex := _steam_auth_ticket_hex(steam)
	if ticket_hex != "":
		identity["steam_auth_ticket"] = ticket_hex
	return identity


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


func _steam_auth_ticket_hex(steam: Object) -> String:
	if _cached_auth_ticket_hex != "":
		return _cached_auth_ticket_hex
	var ticket: Variant = null
	if steam.has_method("GetAuthTicketForWebApi"):
		ticket = steam.call("GetAuthTicketForWebApi", STEAM_AUTH_IDENTITY)
	elif steam.has_method("getAuthTicketForWebApi"):
		ticket = steam.call("getAuthTicketForWebApi", STEAM_AUTH_IDENTITY)
	elif steam.has_method("get_auth_ticket_for_web_api"):
		ticket = steam.call("get_auth_ticket_for_web_api", STEAM_AUTH_IDENTITY)
	if ticket == null:
		return ""
	if typeof(ticket) == TYPE_DICTIONARY:
		var data := Dictionary(ticket)
		_auth_ticket_handle = data.get("auth_ticket_handle", data.get("ticket_handle", _auth_ticket_handle))
		_cached_auth_ticket_hex = _ticket_variant_to_hex(data.get("ticket", data.get("auth_ticket", "")))
	else:
		_auth_ticket_handle = ticket
	return _cached_auth_ticket_hex


func cancel_auth_ticket(steam: Object) -> void:
	if _auth_ticket_handle == null:
		return
	if steam.has_method("cancelAuthTicket"):
		steam.call("cancelAuthTicket", _auth_ticket_handle)
	elif steam.has_method("cancel_auth_ticket"):
		steam.call("cancel_auth_ticket", _auth_ticket_handle)
	_auth_ticket_handle = null
	_cached_auth_ticket_hex = ""


func _ticket_variant_to_hex(ticket: Variant) -> String:
	if typeof(ticket) == TYPE_PACKED_BYTE_ARRAY:
		return _bytes_to_hex(PackedByteArray(ticket))
	if typeof(ticket) == TYPE_ARRAY:
		var bytes := PackedByteArray()
		for value in Array(ticket):
			bytes.append(int(value) & 0xff)
		return _bytes_to_hex(bytes)
	var text := str(ticket).strip_edges()
	if _is_hex_string(text) or text.find(",") == -1:
		return text
	var bytes_from_csv := PackedByteArray()
	for part in text.split(",", false):
		bytes_from_csv.append(int(part.strip_edges()) & 0xff)
	return _bytes_to_hex(bytes_from_csv)


func _is_hex_string(text: String) -> bool:
	if text == "" or text.length() % 2 != 0:
		return false
	for index in range(text.length()):
		var code := text.unicode_at(index)
		var is_digit := code >= 48 and code <= 57
		var is_upper_hex := code >= 65 and code <= 70
		var is_lower_hex := code >= 97 and code <= 102
		if not (is_digit or is_upper_hex or is_lower_hex):
			return false
	return true


func _bytes_to_hex(bytes: PackedByteArray) -> String:
	var output := ""
	for byte in bytes:
		output += "%02x" % int(byte)
	return output


func _unavailable(reason: String) -> Dictionary:
	return {
		"available": false,
		"reason": reason,
	}
