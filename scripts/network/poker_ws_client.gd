extends Node
class_name PokerWsClient

const PokerProtocolScript := preload("res://scripts/network/poker_protocol.gd")
const IdentityServiceScript := preload("res://scripts/services/identity_service.gd")
const NetworkConfigScript := preload("res://scripts/network/network_config.gd")

signal connected()
signal disconnected()
signal hello_received(player_id: String, room_id: String)
signal profile_synced(profile: Dictionary, wallet: Dictionary, unlocked_avatar_ids: Array)
signal wallet_synced(wallet: Dictionary)
signal daily_login_awarded(chips: int)
signal avatar_catalog_received(catalog: Array)
signal table_list_received(tables: Array)
signal table_created(room_id: String, table_info: Dictionary)
signal table_joined(room_id: String, table_info: Dictionary)
signal mock_purchase_result_received(ok: bool, currency: String, amount: int, wallet: Dictionary)
signal start_ai_warmup_result_received(ok: bool, room_id: String, reason: String)
signal sit_down_result_received(ok: bool, room_id: String, seat_index: int, player_id: String, reason: String, wallet_chips: int, required_chips: int)
signal table_snapshot_received(snapshot: Dictionary)
signal private_snapshot_received(snapshot: Dictionary)
signal server_error(message: String)
signal message_received(message: Dictionary)

var url := NetworkConfigScript.server_url()
var local_player_id := ""
var player_id := ""
var room_id := ""
var auto_poll := true

var _peer := WebSocketPeer.new()
var _was_connected := false

func connect_to_server(target_url: String = url) -> int:
	url = target_url
	_peer = WebSocketPeer.new()
	_was_connected = false
	return _peer.connect_to_url(url)

func close() -> void:
	_peer.close()

func _process(_delta: float) -> void:
	if auto_poll:
		poll()

func poll() -> void:
	_peer.poll()
	var state := _peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not _was_connected:
		_was_connected = true
		connected.emit()
	while state == WebSocketPeer.STATE_OPEN and _peer.get_available_packet_count() > 0:
		var payload := _peer.get_packet().get_string_from_utf8()
		_handle_message(PokerProtocolScript.decode(payload))
	if _was_connected and state == WebSocketPeer.STATE_CLOSED:
		_was_connected = false
		disconnected.emit()

func send_message(message: Dictionary) -> int:
	if _peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		server_error.emit("WebSocket is not connected")
		return ERR_UNAVAILABLE
	return _peer.send_text(PokerProtocolScript.encode(message))

func send_hello(player_name: String = "", profile_player_id: String = "", avatar_id: String = "", auth_provider: String = "", external_id: String = "") -> int:
	var identity: Dictionary = IdentityServiceScript.new().get_identity()
	var resolved_name := player_name if player_name != "" else String(identity.get("display_name", ""))
	var resolved_external_id := external_id if external_id != "" else String(identity.get("external_id", profile_player_id))
	var resolved_provider := auth_provider if auth_provider != "" else String(identity.get("provider", "local_dev"))
	var resolved_avatar_id := avatar_id if avatar_id != "" else String(identity.get("avatar_id", ""))
	var compatible_player_id := profile_player_id if profile_player_id != "" else resolved_external_id
	local_player_id = resolved_external_id
	return send_message(PokerProtocolScript.hello(resolved_name, compatible_player_id, resolved_avatar_id, resolved_provider, resolved_external_id))

func create_room() -> int:
	return send_message(PokerProtocolScript.create_room())

func join_room(target_room_id: String) -> int:
	room_id = target_room_id
	return send_message(PokerProtocolScript.join_room(target_room_id))

func sit_down(seat_index: int, buy_in: int = 5000) -> int:
	return send_message(PokerProtocolScript.sit_down(seat_index, buy_in))

func leave_seat() -> int:
	return send_message(PokerProtocolScript.leave_seat())

func cash_out() -> int:
	return send_message(PokerProtocolScript.cash_out())

func ready(is_ready: bool = true) -> int:
	return send_message(PokerProtocolScript.ready(is_ready))

func start_hand() -> int:
	return send_message(PokerProtocolScript.start_hand())

func start_ai_warmup(target_room_id: String = room_id) -> int:
	return send_message(PokerProtocolScript.start_ai_warmup(target_room_id))

func player_action(action: String, amount: int = 0) -> int:
	return send_message(PokerProtocolScript.player_action(action, amount))

func add_table_chips(amount: int) -> int:
	return send_message(PokerProtocolScript.add_table_chips(amount))

func get_profile() -> int:
	return send_message(PokerProtocolScript.get_profile())

func get_avatar_catalog() -> int:
	return send_message(PokerProtocolScript.get_avatar_catalog())

func buy_avatar(avatar_id: String) -> int:
	return send_message(PokerProtocolScript.buy_avatar(avatar_id))

func select_avatar(avatar_id: String) -> int:
	return send_message(PokerProtocolScript.select_avatar(avatar_id))

func mock_purchase(currency: String, amount: int) -> int:
	return send_message(PokerProtocolScript.mock_purchase(currency, amount))

func list_tables() -> int:
	return send_message(PokerProtocolScript.list_tables())

func create_table(table_name: String = "", config: Dictionary = {}) -> int:
	return send_message(PokerProtocolScript.create_table(table_name, config))

func join_table(target_room_id: String) -> int:
	room_id = target_room_id
	return send_message(PokerProtocolScript.join_table(target_room_id))

func _handle_message(message: Dictionary) -> void:
	message_received.emit(message)
	var type_value := String(message.get("type", ""))
	match type_value:
		PokerProtocolScript.HELLO:
			var canonical_player_id := String(message.get("server_player_id", message.get("player_id", player_id)))
			if canonical_player_id != "":
				player_id = canonical_player_id
			room_id = String(message.get("room_id", room_id))
			_emit_profile_payload(message)
			var is_authenticated_hello := message.has("server_player_id") or message.has("profile") or message.has("wallet") or message.has("unlocked_avatar_ids")
			if is_authenticated_hello or room_id != "":
				hello_received.emit(player_id, room_id)
		PokerProtocolScript.PROFILE_SNAPSHOT:
			_emit_profile_payload(message)
		PokerProtocolScript.WALLET_SNAPSHOT:
			var wallet := Dictionary(message.get("wallet", {})).duplicate(true)
			if not wallet.is_empty():
				wallet_synced.emit(wallet)
		PokerProtocolScript.AVATAR_CATALOG:
			avatar_catalog_received.emit(Array(message.get("avatar_catalog", [])).duplicate(true))
		PokerProtocolScript.TABLE_LIST:
			table_list_received.emit(Array(message.get("tables", [])).duplicate(true))
		PokerProtocolScript.TABLE_CREATED:
			var created_table := Dictionary(message.get("table", {})).duplicate(true)
			room_id = String(message.get("room_id", created_table.get("room_id", room_id)))
			table_created.emit(room_id, created_table)
		PokerProtocolScript.TABLE_JOINED:
			var joined_table := Dictionary(message.get("table", {})).duplicate(true)
			room_id = String(message.get("room_id", joined_table.get("room_id", room_id)))
			table_joined.emit(room_id, joined_table)
		PokerProtocolScript.MOCK_PURCHASE_RESULT:
			var purchase_wallet := Dictionary(message.get("wallet", {})).duplicate(true)
			if not purchase_wallet.is_empty():
				wallet_synced.emit(purchase_wallet)
			mock_purchase_result_received.emit(
				bool(message.get("ok", false)),
				String(message.get("currency", "")),
				int(message.get("amount", 0)),
				purchase_wallet
			)
		PokerProtocolScript.START_AI_WARMUP_RESULT:
			room_id = String(message.get("room_id", room_id))
			start_ai_warmup_result_received.emit(
				bool(message.get("ok", false)),
				room_id,
				String(message.get("reason", ""))
			)
		PokerProtocolScript.SIT_DOWN_RESULT:
			var result_player_id := String(message.get("server_player_id", message.get("player_id", player_id)))
			if result_player_id != "":
				player_id = result_player_id
			room_id = String(message.get("room_id", room_id))
			sit_down_result_received.emit(
				bool(message.get("ok", false)),
				room_id,
				int(message.get("seat_index", -1)),
				result_player_id,
				String(message.get("reason", "")),
				int(message.get("wallet_chips", -1)),
				int(message.get("required_chips", -1))
			)
		PokerProtocolScript.TABLE_SNAPSHOT:
			var snapshot := Dictionary(message.get("snapshot", {})).duplicate(true)
			room_id = String(message.get("room_id", snapshot.get("room_id", room_id)))
			table_snapshot_received.emit(snapshot)
		PokerProtocolScript.PRIVATE_SNAPSHOT:
			private_snapshot_received.emit(Dictionary(message.get("snapshot", {})).duplicate(true))
		PokerProtocolScript.ERROR:
			server_error.emit(String(message.get("error_code", message.get("error", "Unknown server error"))))

func _emit_profile_payload(message: Dictionary) -> void:
	var profile := Dictionary(message.get("profile", {})).duplicate(true)
	var wallet := Dictionary(message.get("wallet", {})).duplicate(true)
	var unlocked := Array(message.get("unlocked_avatar_ids", []))
	if not profile.is_empty() or not wallet.is_empty() or not unlocked.is_empty():
		profile_synced.emit(profile, wallet, unlocked)
	if not wallet.is_empty():
		wallet_synced.emit(wallet)
	if bool(message.get("daily_login_awarded", false)):
		daily_login_awarded.emit(int(message.get("awarded_chips", 0)))
