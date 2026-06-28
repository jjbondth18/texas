extends Control
class_name LocalServerTestPanel

const PokerWsClientScript := preload("res://scripts/network/poker_ws_client.gd")
const PokerProtocolScript := preload("res://scripts/network/poker_protocol.gd")
const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")
const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

const DEFAULT_SERVER_URL := "ws://127.0.0.1:8080"

var _client: PokerWsClient
var _profile_service := ProfileServiceScript.new()
var _local_player_id := ""
var _server_player_id := ""
var _last_table_snapshot: Dictionary = {}
var _last_private_snapshot: Dictionary = {}

var _server_url_edit: LineEdit
var _player_name_edit: LineEdit
var _room_id_edit: LineEdit
var _seat_index_spin: SpinBox
var _buy_in_spin: SpinBox
var _amount_spin: SpinBox
var _status_label: Label
var _player_id_label: Label
var _hole_cards_label: Label
var _snapshot_text: TextEdit
var _event_log: TextEdit

func _ready() -> void:
	_build_ui()
	_load_profile_defaults()
	_set_status("Idle")

func _exit_tree() -> void:
	if is_instance_valid(_client):
		_client.close()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 16
	root.offset_right = -16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "Local Server Test"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var connection_grid := GridContainer.new()
	connection_grid.columns = 4
	connection_grid.add_theme_constant_override("h_separation", 8)
	connection_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(connection_grid)

	_server_url_edit = _add_labeled_line_edit(connection_grid, "Server URL", DEFAULT_SERVER_URL)
	_player_name_edit = _add_labeled_line_edit(connection_grid, "Player Name", "")
	_room_id_edit = _add_labeled_line_edit(connection_grid, "Room ID", "")
	_seat_index_spin = _add_labeled_spin(connection_grid, "Seat", 0, 5, 0)
	_buy_in_spin = _add_labeled_spin(connection_grid, "Buy In", 1, 1000000, 5000)
	_amount_spin = _add_labeled_spin(connection_grid, "Bet/Raise To", 0, 1000000, 100)

	var button_bar := HBoxContainer.new()
	button_bar.add_theme_constant_override("separation", 8)
	root.add_child(button_bar)
	_add_button(button_bar, "Connect", _on_connect_pressed)
	_add_button(button_bar, "Create Room", _on_create_room_pressed)
	_add_button(button_bar, "Join Room", _on_join_room_pressed)
	_add_button(button_bar, "Sit Down", _on_sit_down_pressed)
	_add_button(button_bar, "Ready", _on_ready_pressed)
	_add_button(button_bar, "Start Hand", _on_start_hand_pressed)

	var action_bar := HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	root.add_child(action_bar)
	_add_button(action_bar, "Fold", func() -> void: _send_player_action(PokerProtocolScript.ACTION_FOLD))
	_add_button(action_bar, "Check", func() -> void: _send_player_action(PokerProtocolScript.ACTION_CHECK))
	_add_button(action_bar, "Call", func() -> void: _send_player_action(PokerProtocolScript.ACTION_CALL))
	_add_button(action_bar, "Bet/Raise", _on_bet_raise_pressed)

	_status_label = Label.new()
	root.add_child(_status_label)
	_player_id_label = Label.new()
	root.add_child(_player_id_label)
	_hole_cards_label = Label.new()
	root.add_child(_hole_cards_label)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)

	_snapshot_text = TextEdit.new()
	_snapshot_text.editable = false
	_snapshot_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_snapshot_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_snapshot_text)

	_event_log = TextEdit.new()
	_event_log.editable = false
	_event_log.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_event_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_event_log)

func _load_profile_defaults() -> void:
	var profile: Dictionary = _profile_service.get_current_profile()
	_player_name_edit.text = PlayerProfileScript.get_player_name(profile)
	_local_player_id = String(profile.get("player_id", PlayerProfileScript.DEFAULT_PLAYER_ID))
	if _local_player_id == "":
		_local_player_id = "local_%d" % Time.get_unix_time_from_system()
	_update_player_id_label()

func _add_labeled_line_edit(parent: GridContainer, label_text: String, value: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.custom_minimum_size = Vector2(260, 0)
	parent.add_child(edit)
	return edit

func _add_labeled_spin(parent: GridContainer, label_text: String, min_value: int, max_value: int, value: int) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size = Vector2(120, 0)
	parent.add_child(spin)
	return spin

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)

func _ensure_client() -> void:
	if is_instance_valid(_client):
		return
	_client = PokerWsClientScript.new()
	_client.connected.connect(_on_connected)
	_client.disconnected.connect(_on_disconnected)
	_client.hello_received.connect(_on_hello_received)
	_client.table_snapshot_received.connect(_on_table_snapshot_received)
	_client.private_snapshot_received.connect(_on_private_snapshot_received)
	_client.server_error.connect(_on_server_error)
	_client.message_received.connect(_on_message_received)
	add_child(_client)

func _on_connect_pressed() -> void:
	_ensure_client()
	var err := _client.connect_to_server(_server_url_edit.text.strip_edges())
	if err != OK:
		_show_error("Connect failed: %s" % error_string(err))
		return
	_set_status("Connecting to %s" % _server_url_edit.text.strip_edges())

func _on_connected() -> void:
	_set_status("Connected")
	_append_event("Connected. Sending hello.")
	_send_or_show(_client.send_hello(_player_name_edit.text.strip_edges(), _local_player_id), "hello")

func _on_disconnected() -> void:
	_set_status("Disconnected")
	_append_event("Disconnected from server.")

func _on_hello_received(player_id: String, room_id: String) -> void:
	_server_player_id = player_id
	if room_id != "":
		_room_id_edit.text = room_id
	_update_player_id_label()
	_append_event("Hello received. server_player_id=%s room_id=%s" % [player_id, room_id])

func _on_create_room_pressed() -> void:
	_send_or_show(_client.create_room() if is_instance_valid(_client) else ERR_UNAVAILABLE, "create_room")

func _on_join_room_pressed() -> void:
	var room_id := _room_id_edit.text.strip_edges()
	if room_id == "":
		_show_error("Room ID is required to join.")
		return
	_send_or_show(_client.join_room(room_id) if is_instance_valid(_client) else ERR_UNAVAILABLE, "join_room")

func _on_sit_down_pressed() -> void:
	_send_or_show(
		_client.sit_down(int(_seat_index_spin.value), int(_buy_in_spin.value)) if is_instance_valid(_client) else ERR_UNAVAILABLE,
		"sit_down"
	)

func _on_ready_pressed() -> void:
	_send_or_show(_client.ready(true) if is_instance_valid(_client) else ERR_UNAVAILABLE, "ready")

func _on_start_hand_pressed() -> void:
	_send_or_show(_client.start_hand() if is_instance_valid(_client) else ERR_UNAVAILABLE, "start_hand")

func _on_bet_raise_pressed() -> void:
	var action := PokerProtocolScript.ACTION_BET if int(_last_table_snapshot.get("current_bet", 0)) == 0 else PokerProtocolScript.ACTION_RAISE
	_send_player_action(action, int(_amount_spin.value))

func _send_player_action(action: String, amount: int = 0) -> void:
	if not is_instance_valid(_client):
		_show_error("WebSocket client is not connected.")
		return
	_send_or_show(_client.player_action(action, amount), "player_action:%s" % action)

func _send_or_show(err: int, label: String) -> void:
	if err == OK:
		_append_event("Sent %s" % label)
	else:
		_show_error("%s failed: %s" % [label, error_string(err)])

func _on_table_snapshot_received(snapshot: Dictionary) -> void:
	_last_table_snapshot = snapshot.duplicate(true)
	var room_id := String(snapshot.get("room_id", ""))
	if room_id != "":
		_room_id_edit.text = room_id
	_render_snapshot()

func _on_private_snapshot_received(snapshot: Dictionary) -> void:
	_last_private_snapshot = snapshot.duplicate(true)
	_render_private_snapshot()

func _on_server_error(message: String) -> void:
	_show_error(message)

func _on_message_received(message: Dictionary) -> void:
	var type_value := String(message.get("type", ""))
	if type_value == PokerProtocolScript.TABLE_SNAPSHOT or type_value == PokerProtocolScript.PRIVATE_SNAPSHOT:
		return
	_append_event("Received %s" % type_value)

func _render_snapshot() -> void:
	var lines: Array[String] = []
	lines.append("room_id: %s" % String(_last_table_snapshot.get("room_id", "")))
	lines.append("hand_state: %s" % String(_last_table_snapshot.get("phase", "")))
	lines.append("betting_round: %s" % String(_last_table_snapshot.get("phase", "")))
	lines.append("pot: %d" % int(_last_table_snapshot.get("pot", 0)))
	lines.append("side_pots: %s" % _format_side_pots(Array(_last_table_snapshot.get("side_pots", []))))
	lines.append("community_cards: %s" % _format_cards(Array(_last_table_snapshot.get("community_cards", []))))
	lines.append("current_turn_seat: %d" % int(_last_table_snapshot.get("current_turn_seat", -1)))
	lines.append("")
	lines.append("Seats")
	for seat in Array(_last_table_snapshot.get("seats", [])):
		var data := Dictionary(seat)
		lines.append("seat %d | %s | chips=%d | bet=%d | status=%s" % [
			int(data.get("seat_index", -1)),
			String(data.get("name", data.get("player_id", ""))),
			int(data.get("chips", 0)),
			int(data.get("current_bet", 0)),
			String(data.get("status", "")),
		])
	_snapshot_text.text = "\n".join(lines)
	_render_private_snapshot()

func _render_private_snapshot() -> void:
	var hole_cards := _format_cards(Array(_last_private_snapshot.get("hole_cards", [])))
	var legal_actions := _format_legal_actions(Array(_last_private_snapshot.get("legal_actions", [])))
	_hole_cards_label.text = "Hole Cards: %s    Legal: %s" % [hole_cards, legal_actions]

func _format_cards(cards: Array) -> String:
	var codes: Array[String] = []
	for card in cards:
		var data := Dictionary(card)
		codes.append(String(data.get("code", "")))
	return ", ".join(codes)

func _format_side_pots(side_pots: Array) -> String:
	var parts: Array[String] = []
	for side_pot in side_pots:
		var data := Dictionary(side_pot)
		parts.append("%d eligible=%s" % [int(data.get("amount", 0)), str(data.get("eligible_seats", []))])
	return " | ".join(parts)

func _format_legal_actions(actions: Array) -> String:
	var parts: Array[String] = []
	for action in actions:
		var data := Dictionary(action)
		var id := String(data.get("action", ""))
		if data.has("amount"):
			id += "(%d)" % int(data.get("amount", 0))
		elif data.has("min_amount"):
			id += "(%d-%d)" % [int(data.get("min_amount", 0)), int(data.get("max_amount", 0))]
		parts.append(id)
	return ", ".join(parts)

func _set_status(message: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = "Status: %s" % message

func _show_error(message: String) -> void:
	_set_status("Error")
	_append_event("ERROR: %s" % message)

func _append_event(message: String) -> void:
	if not is_instance_valid(_event_log):
		return
	var timestamp := Time.get_time_string_from_system()
	_event_log.text += "[%s] %s\n" % [timestamp, message]
	_event_log.set_caret_line(_event_log.get_line_count())

func _update_player_id_label() -> void:
	if is_instance_valid(_player_id_label):
		_player_id_label.text = "Local Profile ID: %s    Server Player ID: %s" % [_local_player_id, _server_player_id]
