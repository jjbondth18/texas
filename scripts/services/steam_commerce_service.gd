extends Node
class_name SteamCommerceService

signal authorization_response(order_id: String, authorized: bool)

const APP_ID := 4969030
const AUTHORIZATION_SIGNAL := "microtransaction_auth_response"

var _steam: Object
var _pending_order_ids: Dictionary = {}
var _handled_callbacks: Dictionary = {}


func _ready() -> void:
	_bind_authorization_callback()


func is_available() -> bool:
	return _steam != null and is_instance_valid(_steam) and _steam.has_signal(AUTHORIZATION_SIGNAL)


func register_pending_order(order_id: String) -> void:
	var normalized := order_id.strip_edges()
	if normalized != "":
		_pending_order_ids[normalized] = true


func clear_pending_order(order_id: String) -> void:
	_pending_order_ids.erase(order_id.strip_edges())


func _bind_authorization_callback() -> void:
	if not Engine.has_singleton("Steam"):
		return
	_steam = Engine.get_singleton("Steam")
	if _steam == null or not _steam.has_signal(AUTHORIZATION_SIGNAL):
		_steam = null
		return
	var callback := Callable(self, "_on_microtransaction_auth_response")
	if not _steam.is_connected(AUTHORIZATION_SIGNAL, callback):
		_steam.connect(AUTHORIZATION_SIGNAL, callback)


func _on_microtransaction_auth_response(app_id: int, order_id: int, authorized: bool) -> void:
	if app_id != APP_ID:
		return
	var order_id_text := str(order_id)
	if not _pending_order_ids.has(order_id_text):
		return
	var callback_key := "%s:%s" % [order_id_text, str(authorized)]
	if _handled_callbacks.has(callback_key):
		return
	_handled_callbacks[callback_key] = true
	authorization_response.emit(order_id_text, authorized)
