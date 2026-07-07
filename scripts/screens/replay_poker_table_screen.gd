extends Control
class_name ReplayPokerTableScreen

signal back_to_detail_requested
signal back_to_replays_requested
signal previous_step_requested
signal next_step_requested
signal playback_toggle_requested
signal speed_toggle_requested
signal timeline_toggle_requested

const AvatarLibraryScript := preload("res://scripts/data/avatar_library.gd")
const ReplayEquityTableScript := preload("res://scripts/replay/replay_equity_table.gd")

const DESIGN_SIZE := Vector2(2560.0, 1000.0)
const TABLE_BACKGROUND_PATH := "res://assets/poker_table/backgrounds/table_neon_v1.png"
const REPLAY_PERF_DEBUG := false
const EQUITY_PHASES := ["preflop", "flop", "turn", "river", "final"]

var _record: Dictionary = {}
var _index_entry: Dictionary = {}
var _steps: Array = []
var _current_step := 0
var _total_steps := 0
var _is_playing := false
var _speed := 1.0
var _timeline_visible := true
var _winner_seats: Dictionary = {}

var _seats: Dictionary = {}
var _replay_step_label: Label
var _timeline_toggle_button: Button
var _play_button: Button
var _speed_button: Button
var _replay_controls_panel: PanelContainer
var _replay_info_action_label: Label
var _equity_table_panel: PanelContainer
var _equity_header_grid: GridContainer
var _equity_table_grid: GridContainer
var _equity_table_empty_label: Label
var _equity_mode_label: Label
var _equity_objective_button: Button
var _equity_perceived_button: Button
var _equity_mode: String = ReplayEquityTableScript.MODE_OBJECTIVE
var _equity_hero_seat: int = -1
var _equity_cache: Dictionary = {}
var _equity_rendered_mode: String = ""
var _equity_cells: Array = []
var _equity_last_phase: String = ""
var _timeline_action_lines: Array = []
var _timeline_event_lines: Array = []
var _timeline_built := false

@onready var _table_surface_layer: Control = $TableSurfaceLayer
@onready var _ui_layer: Control = $UIFloatingLayer
@onready var _pot_display: PotDisplay = $TableSurfaceLayer/TableLayer/PotDisplay
@onready var _community_board: CommunityBoard = $TableSurfaceLayer/TableLayer/CommunityBoard
@onready var _room_info_panel: TableRoomInfoPanel = $UIFloatingLayer/LeftPanel/TableInfoPanel
@onready var _status_panel: TableStatusPanel = $UIFloatingLayer/LeftPanel/PlayerStatusList
@onready var _log_panel: TableInfoPanel = $UIFloatingLayer/RightPanel/LogPanel
@onready var _chat_panel: TableInfoPanel = $UIFloatingLayer/RightPanel/ChatPanel
@onready var _exit_button: Button = $UIFloatingLayer/RightPanel/ExitTableButton
@onready var _action_bar: ActionBar = $UIFloatingLayer/BottomHud
@onready var _top_root: Control = $UIFloatingLayer/TopRoot
@onready var _top_right_action_bar: HBoxContainer = $UIFloatingLayer/TopRoot/TopRightActionBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hide_editor_guides(self)
	_setup_seat_map()
	_setup_replay_visual_shell()
	_layout()
	_render_empty_table()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func set_replay_context(record: Dictionary, index_entry: Dictionary, steps: Array) -> void:
	_record = record.duplicate(true)
	_index_entry = index_entry.duplicate(true)
	_steps = steps.duplicate(true)
	_total_steps = _steps.size()
	_winner_seats = _build_winner_seat_map(_record)
	_equity_cache.clear()
	_equity_rendered_mode = ""
	_equity_last_phase = ""
	_timeline_built = false
	_build_equity_cache()
	_build_timeline_cache()
	_update_replay_title()


func render_replay_state(playback_state: Dictionary, current_step: int, total_steps: int, is_playing: bool, speed: float) -> void:
	_current_step = current_step
	_total_steps = total_steps
	_is_playing = is_playing
	_speed = speed
	var players: Array = Array(playback_state.get("players", []))
	var current_actor_seat: int = int(playback_state.get("current_actor_seat", -1))
	var pot_amount: int = int(playback_state.get("pot", 0))
	var action_text: String = str(playback_state.get("action_text", "Initial state"))

	_update_replay_title(action_text)
	_update_room_info(playback_state)
	_pot_display.set_pot({"main": pot_amount, "side_pots": []})
	_community_board.set_cards(_cards_to_card_data(Array(playback_state.get("board_cards", []))))
	_render_seats(players, current_actor_seat)
	_render_bottom_hud(players, playback_state)
	_update_timeline_highlight(current_step)
	_update_control_text()


func set_timeline_visible(value: bool) -> void:
	_timeline_visible = value
	if _log_panel != null:
		_log_panel.visible = _timeline_visible
	if _timeline_toggle_button != null:
		_timeline_toggle_button.text = "HIDE TIMELINE" if _timeline_visible else "SHOW TIMELINE"


func _setup_seat_map() -> void:
	_seats = {
		1: $TableSurfaceLayer/TableLayer/SeatLayer/Seat1Panel,
		2: $TableSurfaceLayer/TableLayer/SeatLayer/Seat2Panel,
		3: $TableSurfaceLayer/TableLayer/SeatLayer/Seat3Panel,
		4: $TableSurfaceLayer/TableLayer/SeatLayer/Seat4Panel,
		5: $TableSurfaceLayer/TableLayer/SeatLayer/Seat5Panel,
		6: $TableSurfaceLayer/TableLayer/SeatLayer/Seat6Panel,
		7: $TableSurfaceLayer/TableLayer/SeatLayer/Seat7Panel,
		8: $TableSurfaceLayer/TableLayer/SeatLayer/Seat8Panel,
		9: $TableSurfaceLayer/TableLayer/SeatLayer/Seat9Panel,
	}


func _setup_replay_visual_shell() -> void:
	var bg_rect: TextureRect = $BackgroundLayer/TableBackground
	if ResourceLoader.exists(TABLE_BACKGROUND_PATH):
		bg_rect.texture = load(TABLE_BACKGROUND_PATH) as Texture2D
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE

	if _chat_panel != null:
		_chat_panel.visible = false
	if _exit_button != null:
		_exit_button.visible = false

	_configure_replay_info_panel()
	_configure_replay_timeline_panel()
	_setup_top_replay_controls()
	_setup_bottom_replay_controls()
	_setup_equity_table_panel()
	set_timeline_visible(true)


func _configure_replay_info_panel() -> void:
	if _room_info_panel == null:
		return
	_room_info_panel.custom_minimum_size = Vector2(320, 184)
	_room_info_panel.size = Vector2(320, 184)
	_hide_table_room_info_children(["Seat", "ACTION TIMER"])
	_replay_info_action_label = Label.new()
	_replay_info_action_label.name = "ReplayCurrentActionLabel"
	_replay_info_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_replay_info_action_label.custom_minimum_size = Vector2(0, 38)
	HomeTheme.make_font_settings(_replay_info_action_label, 12, Color(0.94, 0.90, 1.0, 0.94))
	_room_info_panel.add_child(_replay_info_action_label)


func _hide_table_room_info_children(text_markers: Array[String]) -> void:
	if _room_info_panel == null:
		return
	for child in _room_info_panel.find_children("*", "Label", true, false):
		var label: Label = child as Label
		if label == null:
			continue
		if label == _replay_info_action_label or label.name == "ReplayCurrentActionLabel":
			continue
		for marker_value in text_markers:
			var marker: String = str(marker_value).to_upper()
			if label.text.to_upper().find(marker) != -1:
				label.visible = false
	for child in _room_info_panel.find_children("*", "ProgressBar", true, false):
		var bar: ProgressBar = child as ProgressBar
		if bar != null:
			bar.visible = false


func _configure_replay_timeline_panel() -> void:
	var right_panel: Control = $UIFloatingLayer/RightPanel
	right_panel.position = Vector2(2240, 150)
	right_panel.size = Vector2(320, 700)
	right_panel.custom_minimum_size = right_panel.size
	if _log_panel != null:
		_log_panel.position = Vector2(-16, -28)
		_log_panel.size = Vector2(336, 640)
		_log_panel.custom_minimum_size = _log_panel.size


func _setup_top_replay_controls() -> void:
	_top_root.visible = true
	_top_root.anchor_left = 0.0
	_top_root.anchor_top = 0.0
	_top_root.anchor_right = 1.0
	_top_root.anchor_bottom = 0.0
	_top_root.offset_left = 0.0
	_top_root.offset_top = 0.0
	_top_root.offset_right = 0.0
	_top_root.offset_bottom = 86.0
	_top_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in _top_right_action_bar.get_children():
		_top_right_action_bar.remove_child(child)
		child.queue_free()
	_top_right_action_bar.visible = true
	_top_right_action_bar.anchor_left = 1.0
	_top_right_action_bar.anchor_top = 0.0
	_top_right_action_bar.anchor_right = 1.0
	_top_right_action_bar.anchor_bottom = 0.0
	_top_right_action_bar.offset_left = -540.0
	_top_right_action_bar.offset_top = 16.0
	_top_right_action_bar.offset_right = -24.0
	_top_right_action_bar.offset_bottom = 58.0
	_top_right_action_bar.alignment = BoxContainer.ALIGNMENT_END
	_top_right_action_bar.add_theme_constant_override("separation", 10)

	var back_detail: Button = _make_replay_button("BACK TO DETAIL", Vector2(146, 42))
	back_detail.pressed.connect(func() -> void: back_to_detail_requested.emit())
	_top_right_action_bar.add_child(back_detail)

	var back_replays: Button = _make_replay_button("BACK TO REPLAYS", Vector2(150, 42))
	back_replays.pressed.connect(func() -> void: back_to_replays_requested.emit())
	_top_right_action_bar.add_child(back_replays)

	_timeline_toggle_button = _make_replay_button("HIDE TIMELINE", Vector2(146, 42))
	_timeline_toggle_button.pressed.connect(func() -> void: timeline_toggle_requested.emit())
	_top_right_action_bar.add_child(_timeline_toggle_button)


func _setup_bottom_replay_controls() -> void:
	_action_bar.set_actions([], 0)
	_action_bar.set_turn_prompt("REPLAY CONTROLS")
	_action_bar.set_action_timer(0, 1, false, false)

	var main_buttons: Control = _action_bar.get_node_or_null("ControlZone/MainButtons") as Control
	if main_buttons != null:
		main_buttons.visible = false
	var raise_panel: Control = _action_bar.get_node_or_null("ControlZone/RaiseControlPanel") as Control
	if raise_panel != null:
		raise_panel.visible = false

	var control_zone: Control = _action_bar.get_node_or_null("ControlZone") as Control
	if control_zone == null:
		return
	_replay_controls_panel = PanelContainer.new()
	_replay_controls_panel.name = "ReplayPokerControls"
	_replay_controls_panel.position = Vector2(52, 100)
	_replay_controls_panel.size = Vector2(552, 150)
	_replay_controls_panel.custom_minimum_size = _replay_controls_panel.size
	_replay_controls_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.010, 0.024, 0.72), Color(0.20, 0.80, 1.0, 0.34), 14, 1))
	control_zone.add_child(_replay_controls_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_replay_controls_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_replay_step_label = Label.new()
	_replay_step_label.name = "ReplayStepSummary"
	_replay_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replay_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_replay_step_label.custom_minimum_size = Vector2(500, 38)
	HomeTheme.make_font_settings(_replay_step_label, 13, Color(0.86, 0.92, 1.0, 0.94))
	vbox.add_child(_replay_step_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	var prev_button: Button = _make_replay_button("PREV", Vector2(104, 42))
	prev_button.pressed.connect(func() -> void: previous_step_requested.emit())
	row.add_child(prev_button)
	_play_button = _make_replay_button("PLAY", Vector2(112, 42))
	_play_button.pressed.connect(func() -> void: playback_toggle_requested.emit())
	row.add_child(_play_button)
	var next_button: Button = _make_replay_button("NEXT", Vector2(104, 42))
	next_button.pressed.connect(func() -> void: next_step_requested.emit())
	row.add_child(next_button)
	_speed_button = _make_replay_button("SPEED 1x", Vector2(122, 42))
	_speed_button.pressed.connect(func() -> void: speed_toggle_requested.emit())
	row.add_child(_speed_button)


func _setup_equity_table_panel() -> void:
	var identity_zone: Control = _action_bar.get_node_or_null("IdentityZone") as Control
	if identity_zone != null:
		identity_zone.visible = false

	_equity_table_panel = PanelContainer.new()
	_equity_table_panel.name = "ReplayEquityTablePanel"
	_equity_table_panel.position = Vector2(0, 0)
	_equity_table_panel.size = Vector2(785, 368)
	_equity_table_panel.custom_minimum_size = _equity_table_panel.size
	_equity_table_panel.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.018, 0.012, 0.044, 0.56), Color(0.82, 0.16, 1.0, 0.48), 14, 1))
	_action_bar.add_child(_equity_table_panel)
	_equity_table_panel.move_to_front()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_equity_table_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var title := Label.new()
	title.name = "ReplayEquityTableTitle"
	title.text = "EQUITY TABLE"
	title.custom_minimum_size = Vector2(250, 24)
	HomeTheme.make_font_settings(title, 15, Color(0.93, 0.88, 1.0, 0.96))
	title_row.add_child(title)

	_equity_objective_button = _make_equity_mode_button("OBJECTIVE", ReplayEquityTableScript.MODE_OBJECTIVE)
	title_row.add_child(_equity_objective_button)
	_equity_perceived_button = _make_equity_mode_button("PERCEIVED", ReplayEquityTableScript.MODE_PERCEIVED)
	title_row.add_child(_equity_perceived_button)

	_equity_mode_label = Label.new()
	_equity_mode_label.name = "ReplayEquityModeDescription"
	_equity_mode_label.custom_minimum_size = Vector2(736, 20)
	_equity_mode_label.clip_text = true
	_equity_mode_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	HomeTheme.make_font_settings(_equity_mode_label, 11, Color(0.72, 0.78, 0.94, 0.86))
	vbox.add_child(_equity_mode_label)

	_equity_table_empty_label = Label.new()
	_equity_table_empty_label.name = "ReplayEquityTableEmpty"
	_equity_table_empty_label.text = "No equity data."
	HomeTheme.make_font_settings(_equity_table_empty_label, 12, Color(0.74, 0.78, 0.94, 0.82))
	vbox.add_child(_equity_table_empty_label)

	_equity_header_grid = GridContainer.new()
	_equity_header_grid.name = "ReplayEquityTableHeaderGrid"
	_equity_header_grid.columns = 7
	_equity_header_grid.add_theme_constant_override("h_separation", 4)
	_equity_header_grid.add_theme_constant_override("v_separation", 0)
	vbox.add_child(_equity_header_grid)

	var scroll := ScrollContainer.new()
	scroll.name = "ReplayEquityTableScroll"
	scroll.custom_minimum_size = Vector2(736, 132)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	_equity_table_grid = GridContainer.new()
	_equity_table_grid.name = "ReplayEquityTableGrid"
	_equity_table_grid.columns = 7
	_equity_table_grid.add_theme_constant_override("h_separation", 4)
	_equity_table_grid.add_theme_constant_override("v_separation", 3)
	scroll.add_child(_equity_table_grid)


func _make_equity_mode_button(text: String, mode: String) -> Button:
	var button := _make_replay_button(text, Vector2(104, 26))
	button.name = "ReplayEquityMode%sButton" % text.capitalize()
	button.pressed.connect(func() -> void: _on_equity_mode_pressed(mode))
	return button


func _on_equity_mode_pressed(mode: String) -> void:
	_equity_mode = mode
	_render_equity_table(_current_equity_phase())


func _layout() -> void:
	if not is_inside_tree():
		return
	var scale_value: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var design_position: Vector2 = (size - DESIGN_SIZE * scale_value) * 0.5
	for layer in [_table_surface_layer, _ui_layer]:
		if layer == null:
			continue
		layer.scale = Vector2(scale_value, scale_value)
		layer.position = design_position
		layer.size = DESIGN_SIZE


func _render_empty_table() -> void:
	for seat_index in range(1, 10):
		var seat: PokerSeat = _seats.get(seat_index, null) as PokerSeat
		if seat != null:
			seat.set_seat_data({"seat_index": seat_index, "seat_id": seat_index, "status": "empty"})
	_pot_display.set_pot({"main": 0, "side_pots": []})
	_community_board.set_cards([])


func _render_seats(players: Array, current_actor_seat: int) -> void:
	var status_seats: Array = []
	var player_by_seat: Dictionary = {}
	for player_item in players:
		var player: Dictionary = Dictionary(player_item)
		var seat_index: int = int(player.get("seat_index", -1))
		if seat_index > 0:
			player_by_seat[seat_index] = player

	for seat_index in range(1, 10):
		var seat_control: PokerSeat = _seats.get(seat_index, null) as PokerSeat
		if seat_control == null:
			continue
		var seat_data: Dictionary = {}
		if player_by_seat.has(seat_index):
			seat_data = _seat_data_from_player(Dictionary(player_by_seat[seat_index]), current_actor_seat)
			status_seats.append(seat_data.duplicate(true))
		else:
			seat_data = {"seat_index": seat_index, "seat_id": seat_index, "status": "empty", "occupied": false}
		seat_control.set_seat_data(seat_data)
	_status_panel.set_status({"seats": status_seats, "turn_seat_index": current_actor_seat})


func _seat_data_from_player(player: Dictionary, current_actor_seat: int) -> Dictionary:
	var seat_index: int = int(player.get("seat_index", -1))
	var status_text: String = str(player.get("status", "active"))
	var final_status: String = str(player.get("final_status", ""))
	var is_winner: bool = _winner_seats.has(seat_index) and _current_step >= _total_steps
	var display_status: String = _replay_display_status(status_text, final_status, is_winner)
	var avatar_id: String = str(player.get("avatar_id", ""))
	if avatar_id == "":
		avatar_id = AvatarLibraryScript.avatar_id_for_seat(seat_index, false)
	var cards: Array = _cards_to_card_data(Array(player.get("hole_cards", [])))
	if cards.is_empty():
		cards = _cards_to_card_data(_cards_from_text(str(player.get("cards_text", ""))))
	for i in range(cards.size()):
		var card: Dictionary = Dictionary(cards[i])
		card["face_up"] = true
		cards[i] = card
	return {
		"seat_index": seat_index,
		"seat_id": seat_index,
		"visual_position": seat_index,
		"player_id": str(player.get("player_id", "")),
		"player_name": str(player.get("player_name", player.get("player_id", "Seat %d" % seat_index))),
		"avatar_id": avatar_id,
		"avatar_texture": AvatarLibraryScript.get_avatar_by_id(avatar_id),
		"chips": int(player.get("stack", player.get("ending_stack", player.get("starting_stack", 0)))),
		"current_bet": int(player.get("current_bet", 0)),
		"cards": cards,
		"status": display_status,
		"raw_status": display_status,
		"last_action": _status_to_action_label(display_status),
		"last_action_amount": int(player.get("current_bet", 0)),
		"is_turn": seat_index == current_actor_seat,
		"is_local": seat_index == _primary_player_seat(Array(_record.get("players", []))),
		"ready": false,
		"occupied": true,
		"is_ai": bool(player.get("is_ai", false)),
		"warmup_ai": bool(player.get("is_local_warmup_ai", false)),
	}


func _render_bottom_hud(players: Array, playback_state: Dictionary) -> void:
	var primary: Dictionary = _primary_player_from_state(players)
	if primary.is_empty() and not players.is_empty():
		primary = Dictionary(players[0])
	var action_text: String = str(playback_state.get("action_text", "Initial state"))
	if not primary.is_empty():
		_set_bottom_hole_cards(_cards_to_card_data(_replay_cards_for_player(primary)))
	else:
		_set_bottom_hole_cards([])
	_update_equity_highlight(_current_equity_phase())
	_action_bar.set_turn_prompt("REPLAY CONTROLS")
	if _replay_step_label != null:
		_replay_step_label.text = "Step %d / %d\n%s" % [_current_step, _total_steps, action_text]


func _build_equity_cache() -> void:
	_equity_cache.clear()
	for mode in [ReplayEquityTableScript.MODE_OBJECTIVE, ReplayEquityTableScript.MODE_PERCEIVED]:
		var base_table: Dictionary = ReplayEquityTableScript.build_table(_record, "preflop", mode, _equity_hero_seat)
		var phase_tables: Dictionary = {}
		for phase in EQUITY_PHASES:
			var table: Dictionary = base_table.duplicate(true)
			table["active_phase"] = phase
			phase_tables[phase] = table
		_equity_cache[mode] = phase_tables
	_log_replay_perf("build equity cache objective/perceived once")


func _equity_table_for(mode: String, active_phase: String) -> Dictionary:
	if _equity_cache.is_empty():
		_build_equity_cache()
	var normalized_mode: String = ReplayEquityTableScript.MODE_PERCEIVED if mode == ReplayEquityTableScript.MODE_PERCEIVED else ReplayEquityTableScript.MODE_OBJECTIVE
	var phase: String = active_phase if active_phase in EQUITY_PHASES else "preflop"
	var mode_cache: Dictionary = Dictionary(_equity_cache.get(normalized_mode, {}))
	if mode_cache.is_empty():
		var base_table: Dictionary = ReplayEquityTableScript.build_table(_record, "preflop", normalized_mode, _equity_hero_seat)
		for phase_name in EQUITY_PHASES:
			var table: Dictionary = base_table.duplicate(true)
			table["active_phase"] = phase_name
			mode_cache[phase_name] = table
		_equity_cache[normalized_mode] = mode_cache
		_log_replay_perf("build missing equity cache mode=%s" % normalized_mode)
	return Dictionary(mode_cache.get(phase, {}))


func _set_bottom_hole_cards(cards: Array) -> void:
	var root: Control = _action_bar.local_cards_root
	if root == null:
		return
	for i in range(root.get_child_count()):
		var card_view: CardView = root.get_child(i) as CardView
		if card_view == null:
			continue
		if i < cards.size():
			card_view.visible = true
			card_view.set_card(Dictionary(cards[i]))
		else:
			card_view.visible = false


func _render_equity_table(active_phase: String) -> void:
	if _equity_table_grid == null:
		return
	var table: Dictionary = _equity_table_for(_equity_mode, active_phase)
	var rows: Array = Array(table.get("rows", []))
	var normalized_phase: String = str(table.get("active_phase", "preflop"))
	_equity_hero_seat = int(table.get("hero_seat", _equity_hero_seat))
	_update_equity_mode_header(table)
	if _equity_rendered_mode == _equity_mode and not _equity_cells.is_empty():
		_update_equity_highlight(normalized_phase)
		return
	if _equity_header_grid != null:
		_clear_children(_equity_header_grid)
	_clear_children(_equity_table_grid)
	_equity_cells.clear()
	_equity_rendered_mode = _equity_mode
	if _equity_table_empty_label != null:
		_equity_table_empty_label.visible = rows.is_empty()
		_equity_table_empty_label.text = str(table.get("message", "No equity data."))
	if rows.is_empty():
		return
	if _equity_table_empty_label != null:
		_equity_table_empty_label.visible = false

	var columns: Array[Dictionary] = [
		{"key": "seat", "label": "Seat", "width": 56},
		{"key": "player", "label": "Player", "width": 184},
		{"key": "preflop", "label": "Preflop", "width": 98},
		{"key": "flop", "label": "Flop", "width": 92},
		{"key": "turn", "label": "Turn", "width": 92},
		{"key": "river", "label": "River", "width": 92},
		{"key": "final", "label": "Final", "width": 96},
	]
	for column_item in columns:
		var column: Dictionary = Dictionary(column_item)
		var header_cell: PanelContainer = _make_equity_cell(str(column.get("label", "")), int(column.get("width", 70)), true, str(column.get("key", "")) == normalized_phase)
		if _equity_header_grid != null:
			_equity_header_grid.add_child(header_cell)
		else:
			_equity_table_grid.add_child(header_cell)
	for row_item in rows:
		var row: Dictionary = Dictionary(row_item)
		for column_item in columns:
			var column: Dictionary = Dictionary(column_item)
			var key: String = str(column.get("key", ""))
			var value: String = _equity_cell_text(row, key)
			_equity_table_grid.add_child(_make_equity_cell(value, int(column.get("width", 70)), false, key == normalized_phase, key, value))
	_update_equity_highlight(normalized_phase)


func _update_equity_mode_header(table: Dictionary) -> void:
	var mode: String = str(table.get("mode", ReplayEquityTableScript.MODE_OBJECTIVE))
	if _equity_mode_label != null:
		if mode == ReplayEquityTableScript.MODE_PERCEIVED:
			_equity_mode_label.text = "Perceived - each player knows only their own cards."
		else:
			_equity_mode_label.text = "Objective - all hole cards known."
	_style_equity_mode_button(_equity_objective_button, mode == ReplayEquityTableScript.MODE_OBJECTIVE)
	_style_equity_mode_button(_equity_perceived_button, mode == ReplayEquityTableScript.MODE_PERCEIVED)


func _style_equity_mode_button(button: Button, active: bool) -> void:
	if button == null:
		return
	var fill: Color = Color(0.030, 0.025, 0.070, 0.72)
	var border: Color = Color(0.42, 0.20, 0.80, 0.42)
	if active:
		fill = Color(0.06, 0.16, 0.24, 0.88)
		border = Color(0.24, 0.86, 1.0, 0.75)
	button.add_theme_stylebox_override("normal", HomeTheme.make_panel_style(fill, border, 7, 1))
	button.add_theme_stylebox_override("hover", HomeTheme.make_panel_style(fill.lightened(0.08), border.lightened(0.08), 7, 1))
	button.add_theme_stylebox_override("pressed", HomeTheme.make_panel_style(fill.darkened(0.05), border, 7, 1))


func _make_equity_cell(text: String, width: int, is_header: bool, is_active_phase: bool, key: String = "", value: String = "") -> PanelContainer:
	var cell := PanelContainer.new()
	cell.name = "ReplayEquityCell_%s" % (key if key != "" else "header")
	cell.custom_minimum_size = Vector2(width, 25 if not is_header else 27)
	cell.set_meta("equity_key", key)
	cell.set_meta("equity_is_header", is_header)
	cell.set_meta("equity_value", value)
	_equity_cells.append(cell)
	_style_equity_cell(cell, is_header, is_active_phase)

	var label := Label.new()
	label.text = text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if key != "player" else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_equity_label(label, is_header, value)
	cell.add_child(label)
	return cell


func _style_equity_cell(cell: PanelContainer, is_header: bool, is_active_phase: bool) -> void:
	var fill: Color = Color(0.035, 0.025, 0.080, 0.42)
	var border: Color = Color(0.34, 0.20, 0.70, 0.28)
	if is_header:
		fill = Color(0.10, 0.055, 0.16, 0.50)
		border = Color(0.85, 0.30, 1.0, 0.50)
	if is_active_phase:
		fill = Color(0.06, 0.16, 0.24, 0.62)
		border = Color(0.25, 0.86, 1.0, 0.72)
	cell.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(fill, border, 5, 1))


func _style_equity_label(label: Label, is_header: bool, value: String) -> void:
	var color: Color = Color(0.86, 0.90, 1.0, 0.94)
	if is_header:
		color = Color(0.93, 0.86, 1.0, 0.96)
	elif value == "Win":
		color = Color(0.22, 1.0, 0.68, 0.98)
	elif value == "Split":
		color = Color(1.0, 0.80, 0.26, 0.98)
	elif value == "Folded":
		color = Color(0.58, 0.61, 0.70, 0.90)
	elif value == "Loss":
		color = Color(0.70, 0.74, 0.84, 0.90)
	HomeTheme.make_font_settings(label, 11 if not is_header else 12, color)


func _update_equity_highlight(active_phase: String) -> void:
	var normalized_phase: String = active_phase if active_phase in EQUITY_PHASES else "preflop"
	if _equity_rendered_mode != _equity_mode or _equity_cells.is_empty():
		_render_equity_table(normalized_phase)
		return
	if _equity_last_phase == normalized_phase:
		return
	_equity_last_phase = normalized_phase
	for cell_item in _equity_cells:
		var cell: PanelContainer = cell_item as PanelContainer
		if cell == null:
			continue
		var key: String = str(cell.get_meta("equity_key", ""))
		var is_header: bool = bool(cell.get_meta("equity_is_header", false))
		_style_equity_cell(cell, is_header, key == normalized_phase)
	_log_replay_perf("step update index=%d phase=%s recreate_nodes=false equity_recomputed=false" % [_current_step, normalized_phase])


func _equity_cell_text(row: Dictionary, key: String) -> String:
	if key == "seat":
		return str(int(row.get("seat", -1)))
	if key == "player":
		var name: String = str(row.get("player", "-"))
		return name.substr(0, 14) if name.length() > 14 else name
	return str(row.get(key, "-"))


func _current_equity_phase() -> String:
	if _current_step >= _total_steps and _total_steps > 0:
		return "final"
	if _current_step <= 0 or _steps.is_empty():
		return "preflop"
	var step_index: int = clampi(_current_step - 1, 0, _steps.size() - 1)
	var step: Dictionary = Dictionary(_steps[step_index])
	var street: String = str(step.get("street", "preflop")).to_lower()
	if street in ["showdown", "hand_over", "result", "final"]:
		return "final"
	if street in ["preflop", "flop", "turn", "river"]:
		return street
	return "preflop"


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _build_timeline_cache() -> void:
	_timeline_action_lines = []
	_timeline_event_lines = []
	var action_count := 0
	for i in range(_steps.size()):
		var step: Dictionary = Dictionary(_steps[i])
		var line: String = str(step.get("timeline_text", step.get("label", "")))
		if line == "":
			line = _fallback_step_text(step)
		if str(step.get("kind", "event")) == "action":
			action_count += 1
			_timeline_action_lines.append("%d. %s" % [action_count, line])
		else:
			_timeline_event_lines.append(line)
	_timeline_built = false


func _update_timeline_highlight(_current_step_index: int) -> void:
	if _log_panel == null:
		return
	if not _timeline_built:
		_log_panel.set_info(_timeline_action_lines, _timeline_event_lines)
		_timeline_built = true


func _update_room_info(playback_state: Dictionary) -> void:
	var mode_text: String = _mode_label(str(_record.get("mode", "")))
	var hand_id: String = str(_record.get("hand_id", _index_entry.get("hand_id", "-")))
	var room_text: String = str(_record.get("room_code", ""))
	if room_text == "":
		room_text = str(_record.get("room_id", "-"))
	var blinds: String = "%d / %d" % [int(_record.get("small_blind", 0)), int(_record.get("big_blind", 0))]
	var max_hands: int = int(_record.get("max_hands", _record.get("hand_count", 0)))
	var hand_number: int = int(_record.get("hand_number", 0))
	var progress: String = "Hand %d / %d" % [hand_number, max_hands] if max_hands > 0 else "Hand %d" % hand_number
	_room_info_panel.set_table_context("REPLAY MODE", hand_id, -1, blinds, "%s %s" % [mode_text, room_text], progress)
	if _replay_info_action_label != null:
		_replay_info_action_label.text = str(playback_state.get("action_text", "Initial state"))
	_hide_table_room_info_children(["Seat", "ACTION TIMER"])


func _update_replay_title(_action_text: String = "") -> void:
	pass


func _update_control_text() -> void:
	if _play_button != null:
		_play_button.text = "PAUSE" if _is_playing else "PLAY"
	if _speed_button != null:
		_speed_button.text = "SPEED %sx" % int(_speed)
	if _timeline_toggle_button != null:
		_timeline_toggle_button.text = "HIDE TIMELINE" if _timeline_visible else "SHOW TIMELINE"


func _primary_player_from_state(players: Array) -> Dictionary:
	var primary_seat: int = _primary_player_seat(Array(_record.get("players", [])))
	for item in players:
		var player: Dictionary = Dictionary(item)
		if int(player.get("seat_index", -1)) == primary_seat:
			return player
	return {}


func _replay_display_status(status_text: String, final_status: String, is_winner: bool) -> String:
	if is_winner:
		return "winner"
	var source: String = final_status if final_status.strip_edges() != "" else status_text
	var normalized: String = source.to_lower()
	if normalized.find("fold") != -1:
		return "folded"
	if normalized.find("all") != -1:
		return "all_in"
	if normalized.find("showdown") != -1:
		return "showdown"
	if normalized.find("lost") != -1 or normalized.find("lose") != -1:
		return "lost"
	if normalized.find("blind") != -1:
		return source
	if normalized.find("check") != -1:
		return "checked"
	if normalized.find("call") != -1:
		return "called"
	if normalized.find("raise") != -1:
		return "raised"
	if normalized.find("bet") != -1:
		return "bet"
	return "active"


func _primary_player_seat(players: Array) -> int:
	for item in players:
		var player: Dictionary = Dictionary(item)
		if int(player.get("seat_index", -1)) == 5 and not bool(player.get("is_ai", false)):
			return 5
	for item in players:
		var player: Dictionary = Dictionary(item)
		if not bool(player.get("is_ai", false)):
			return int(player.get("seat_index", 5))
	if not players.is_empty():
		return int(Dictionary(players[0]).get("seat_index", 5))
	return 5


func _replay_cards_for_player(player: Dictionary) -> Array:
	var cards: Array = Array(player.get("hole_cards", []))
	if not cards.is_empty():
		return cards
	return _cards_from_text(str(player.get("cards_text", "")))


func _cards_from_text(text: String) -> Array:
	var result: Array = []
	var cleaned: String = text.strip_edges()
	if cleaned == "" or cleaned == "Unknown":
		return result
	for part in cleaned.split(" ", false):
		result.append(str(part))
	return result


func _cards_to_card_data(cards: Array) -> Array:
	var result: Array = []
	for card_item in cards:
		result.append(_card_data(card_item))
	return result


func _card_data(card_value: Variant) -> Dictionary:
	if card_value is Dictionary:
		var card: Dictionary = Dictionary(card_value).duplicate(true)
		if not card.has("face_up"):
			card["face_up"] = true
		return card
	var code: String = str(card_value).strip_edges().to_upper()
	code = code.replace("SPADES", "S").replace("HEARTS", "H").replace("DIAMONDS", "D").replace("CLUBS", "C")
	if code.length() < 2:
		return {"rank": "", "suit": "", "face_up": false}
	var suit_char: String = code.substr(code.length() - 1, 1)
	var rank_text: String = code.substr(0, code.length() - 1)
	match suit_char:
		"S":
			return {"rank": rank_text, "suit": "spades", "face_up": true}
		"H":
			return {"rank": rank_text, "suit": "hearts", "face_up": true}
		"D":
			return {"rank": rank_text, "suit": "diamonds", "face_up": true}
		"C":
			return {"rank": rank_text, "suit": "clubs", "face_up": true}
	return {"rank": rank_text, "suit": "", "face_up": true}


func _build_winner_seat_map(record: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var results: Dictionary = Dictionary(record.get("results", {}))
	for winner_item in Array(results.get("winners", [])):
		var winner: Dictionary = Dictionary(winner_item)
		var seat_index: int = int(winner.get("winner_seat", winner.get("seat_index", winner.get("seat_id", -1))))
		if seat_index > 0:
			result[seat_index] = true
	return result


func _status_to_action_label(status: String) -> String:
	var normalized: String = status.to_lower()
	if normalized.find("fold") != -1:
		return "Fold"
	if normalized.find("winner") != -1:
		return "Win"
	if normalized.find("blind") != -1:
		return status
	if normalized.find("check") != -1:
		return "Check"
	if normalized.find("call") != -1:
		return "Call"
	if normalized.find("raise") != -1:
		return "Raise"
	if normalized.find("bet") != -1:
		return "Bet"
	if normalized.find("all") != -1:
		return "All-in"
	return ""


func _fallback_step_text(step: Dictionary) -> String:
	if str(step.get("kind", "")) == "action":
		var action: Dictionary = Dictionary(step.get("action", {}))
		return str(action.get("message", action.get("action", "Action")))
	return str(step.get("label", "Hand event"))


func _mode_label(mode: String) -> String:
	match mode.to_lower():
		"public":
			return "Public Table"
		"private":
			return "Private Room"
		"training":
			return "Training"
		"local_warmup":
			return "Warm-up"
	return "Replay"


func _compact_hand_number(hand_id: String) -> String:
	var digits := ""
	for i in range(hand_id.length()):
		var ch: String = hand_id.substr(i, 1)
		if ch.is_valid_int():
			digits += ch
	if digits == "":
		return hand_id
	return digits


func _make_replay_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.72), Color(0.52, 0.78, 1.0, 0.42), 14))
	button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.030, 0.038, 0.082, 0.86), Color(0.72, 0.92, 1.0, 0.72), 14))
	button.add_theme_stylebox_override("pressed", HomeTheme.make_button_style(Color(0.018, 0.022, 0.052, 0.94), Color(1.0, 0.0, 0.50, 0.72), 14))
	button.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.96))
	button.add_theme_font_size_override("font_size", 13)
	return button


func _log_replay_perf(message: String) -> void:
	if REPLAY_PERF_DEBUG:
		print("[ReplayPerf] %s" % message)


func _hide_editor_guides(node: Node) -> void:
	for child in node.get_children():
		var canvas_item: CanvasItem = child as CanvasItem
		if canvas_item != null and (child is ReferenceRect or str(child.name).begins_with("Guide")):
			canvas_item.visible = false
		_hide_editor_guides(child)
