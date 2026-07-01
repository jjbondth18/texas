extends PanelContainer
class_name TableStatusPanel

# POKER TABLE UI FREEZE:
# Do not change layout/position/size of existing poker table UI nodes unless the task explicitly asks for visual changes.
# Logic/data binding changes are allowed, but must not move or resize frozen UI components.

var _rows_container: VBoxContainer
var _pills := {}
var is_left_panel := false
var _seat_order: Array[int] = []
const TABLE_SEAT_JOIN_ORDER_9P := [5, 8, 2, 6, 4, 9, 1, 7, 3]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Transparent panel background
	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty_style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 5) #贴右边缘
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	
	# VBox container for separating Header, Player list and Exit Button
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Wrap the "PLAYER STATUS" label in a MarginContainer to give it a 20px bottom margin
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(status_margin)
	
	var status_label := Label.new()
	status_label.text = "PLAYER STATUS"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.85))
	status_margin.add_child(status_label)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Wrap rows_container in a MarginContainer inside scroll to prevent clipping during slide
	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	is_left_panel = global_position.x < 1280 or get_parent().name.contains("Left")
	if is_left_panel:
		scroll_margin.add_theme_constant_override("margin_left", 16)
		scroll_margin.add_theme_constant_override("margin_right", 20)
	else:
		scroll_margin.add_theme_constant_override("margin_left", 40)
		scroll_margin.add_theme_constant_override("margin_right", 0)
		
	scroll_margin.add_theme_constant_override("margin_top", 0)
	scroll_margin.add_theme_constant_override("margin_bottom", 0)
	scroll.add_child(scroll_margin)
	
	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.add_theme_constant_override("separation", 12) # Fixed separation 12
	scroll_margin.add_child(_rows_container)
	


func set_status(snapshot: Dictionary) -> void:
	if _rows_container == null:
		return
		
	is_left_panel = global_position.x < 1280 or get_parent().name.contains("Left")
	var scroll_margin = _rows_container.get_parent() as MarginContainer
	if scroll_margin != null:
		if is_left_panel:
			scroll_margin.add_theme_constant_override("margin_left", 16)
			scroll_margin.add_theme_constant_override("margin_right", 20)
		else:
			scroll_margin.add_theme_constant_override("margin_left", 40)
			scroll_margin.add_theme_constant_override("margin_right", 0)
			
	var seats := Array(snapshot.get("seats", []))
	var active_players := []
	var active_seats: Array[int] = []
	
	for seat_data in seats:
		var seat := Dictionary(seat_data)
		var status_str := String(seat.get("status", "empty"))
		var raw_status := String(seat.get("raw_status", status_str))
		var occupied := bool(seat.get("occupied", status_str != "empty"))
		var seat_index := int(seat.get("seat_index", seat.get("seat_id", 0)))
		var has_player := String(seat.get("player_id", "")) != "" or String(seat.get("player_name", "")) != ""
		if occupied and raw_status != "empty" and has_player:
			active_players.append(seat)
			active_seats.append(seat_index)
			
	# Keep the player status list stable: fixed objective seat join order, never turn-order.
	active_players.sort_custom(func(a, b): return _seat_order_rank(int(a.get("seat_index", a.get("seat_id", 0)))) < _seat_order_rank(int(b.get("seat_index", b.get("seat_id", 0)))))
	
	# Remove pills for seats that are no longer active/present
	for seat_idx in _pills.keys():
		if seat_idx not in active_seats:
			_pills[seat_idx].queue_free()
			_pills.erase(seat_idx)
			
	# Instantiate or update player row pills
	for player in active_players:
		var seat_idx := int(player.get("seat_index", player.get("seat_id", 0)))
		if _pills.has(seat_idx):
			_pills[seat_idx].update_data(player, is_left_panel)
		else:
			var pill := PlayerRowPill.new(player, is_left_panel)
			_pills[seat_idx] = pill
			_rows_container.add_child(pill)
			
	# Enforce seat order only when it changed; turn changes should only update row state.
	var next_order: Array[int] = []
	for player in active_players:
		next_order.append(int(player.get("seat_index", player.get("seat_id", 0))))
	if next_order == _seat_order:
		return
	_seat_order = next_order
	for i in range(active_players.size()):
		var player = active_players[i]
		var seat_idx := int(player.get("seat_index", player.get("seat_id", 0)))
		var pill = _pills[seat_idx]
		if pill.get_index() != i:
			_rows_container.move_child(pill, i)

func _seat_order_rank(seat_index: int) -> int:
	var rank := TABLE_SEAT_JOIN_ORDER_9P.find(seat_index)
	return rank if rank != -1 else 999 + seat_index

func set_action_timer(turn_seat_index: int, remaining_seconds: int, total_seconds: int, active: bool) -> void:
	for seat_idx in _pills.keys():
		var pill = _pills[seat_idx]
		if pill != null and pill.has_method("set_turn_timer"):
			pill.call("set_turn_timer", remaining_seconds, total_seconds, active and int(seat_idx) == turn_seat_index)

# Inner class representing a high-fidelity sliding player row pill in the list
class PlayerRowPill extends PanelContainer:
	var player_data: Dictionary
	var style_box: StyleBoxFlat
	var action_label: Label
	var avatar_rect: TextureRect
	var avatar_panel: Panel
	var name_label: Label
	var chips_label: Label
	var you_badge: PanelContainer
	var is_left := false
	var text_vbox: VBoxContainer
	
	# Turn dots
	var dots_hbox: HBoxContainer
	var dot1: Panel
	var dot2: Panel
	var dot3: Panel
	
	var _is_turn := false
	var _is_fold := false
	var _tween: Tween
	var _turn_timer_active := false
	var _turn_timer_remaining := 0
	var _turn_timer_total := 0
	
	func _init(data: Dictionary, left_side: bool) -> void:
		player_data = data
		is_left = left_side
		custom_minimum_size = Vector2(220, 85) # Width 220px to fit inside scroll container with 40px left margin
		size = custom_minimum_size
		clip_contents = true
		size_flags_horizontal = Control.SIZE_SHRINK_END if is_left else Control.SIZE_EXPAND_FILL
		
		style_box = StyleBoxFlat.new()
		style_box.corner_detail = 8
		style_box.set_corner_radius_all(8)
		style_box.anti_aliasing = true
		
		# Inner padding via content margins of the StyleBox
		style_box.content_margin_left = 12
		style_box.content_margin_right = 12
		style_box.content_margin_top = 10
		style_box.content_margin_bottom = 10
		
		add_theme_stylebox_override("panel", style_box)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.alignment = BoxContainer.ALIGNMENT_END if is_left else BoxContainer.ALIGNMENT_BEGIN
		add_child(hbox)
		
		# Circular Avatar Container
		avatar_panel = Panel.new()
		avatar_panel.custom_minimum_size = Vector2(48, 48)
		avatar_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		avatar_panel.clip_children = Control.CLIP_CHILDREN_AND_DRAW
		
		var av_style := StyleBoxFlat.new()
		av_style.set_corner_radius_all(24)
		av_style.bg_color = Color(0.012, 0.010, 0.022, 0.54)
		av_style.border_color = Color(0.55, 0.38, 0.92, 0.18)
		av_style.set_border_width_all(1)
		avatar_panel.add_theme_stylebox_override("panel", av_style)
		
		avatar_rect = TextureRect.new()
		avatar_rect.custom_minimum_size = Vector2(48, 48)
		avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		avatar_rect.modulate = Color.WHITE
		avatar_panel.add_child(avatar_rect)
		
		# Text Container
		text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_vbox.add_theme_constant_override("separation", 2)
		
		if is_left:
			# Left panel: [ text | avatar ]
			hbox.add_child(text_vbox)
			hbox.add_child(avatar_panel)
		else:
			# Right panel: [ avatar | text ]
			hbox.add_child(avatar_panel)
			hbox.add_child(text_vbox)
		
		# Name row HBox to support name on left and YOU badge on right
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 6)
		name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_child(name_row)
		
		name_label = Label.new()
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_left else HORIZONTAL_ALIGNMENT_LEFT
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(name_label)
		
		# Isolated "YOU" Badge PanelContainer
		you_badge = PanelContainer.new()
		you_badge.name = "YouBadge"
		you_badge.visible = false
		you_badge.size_flags_horizontal = Control.SIZE_SHRINK_END
		you_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var yb_style := StyleBoxFlat.new()
		yb_style.bg_color = Color(1.0, 0.0, 0.5) # Neon Magenta
		yb_style.set_corner_radius_all(4)
		yb_style.content_margin_left = 5
		yb_style.content_margin_right = 5
		yb_style.content_margin_top = 1
		yb_style.content_margin_bottom = 2
		you_badge.add_theme_stylebox_override("panel", yb_style)
		
		var yb_label := Label.new()
		yb_label.text = "YOU"
		yb_label.add_theme_font_size_override("font_size", 10)
		yb_label.add_theme_color_override("font_color", Color.WHITE)
		yb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		yb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		you_badge.add_child(yb_label)
		name_row.add_child(you_badge)
		
		# HBox for flashing dots marquee underneath name
		dots_hbox = HBoxContainer.new()
		dots_hbox.add_theme_constant_override("separation", 4)
		dots_hbox.visible = true
		dots_hbox.modulate.a = 0.0
		dots_hbox.custom_minimum_size = Vector2(0, 6)
		text_vbox.add_child(dots_hbox)
		
		var dot_style := StyleBoxFlat.new()
		dot_style.set_corner_radius_all(3)
		dot_style.bg_color = Color(0.0, 0.95, 1.0) # neon cyan dots
		
		dot1 = Panel.new()
		dot1.custom_minimum_size = Vector2(6, 6)
		dot1.add_theme_stylebox_override("panel", dot_style)
		dots_hbox.add_child(dot1)
		
		dot2 = Panel.new()
		dot2.custom_minimum_size = Vector2(6, 6)
		dot2.add_theme_stylebox_override("panel", dot_style)
		dots_hbox.add_child(dot2)
		
		dot3 = Panel.new()
		dot3.custom_minimum_size = Vector2(6, 6)
		dot3.add_theme_stylebox_override("panel", dot_style)
		dots_hbox.add_child(dot3)
		
		chips_label = Label.new()
		chips_label.add_theme_font_size_override("font_size", 15)
		chips_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		chips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_left else HORIZONTAL_ALIGNMENT_LEFT
		text_vbox.add_child(chips_label)
		
		action_label = Label.new()
		action_label.add_theme_font_size_override("font_size", 12)
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_left else HORIZONTAL_ALIGNMENT_LEFT
		action_label.clip_text = true
		action_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		action_label.custom_minimum_size = Vector2(0, 16)
		text_vbox.add_child(action_label)
		
		# Initial config
		update_data(data, is_left, true)
		
	func update_data(data: Dictionary, left_side: bool, force_snap: bool = false) -> void:
		player_data = data
		is_left = left_side
		size_flags_horizontal = Control.SIZE_SHRINK_END if is_left else Control.SIZE_EXPAND_FILL
		
		# Dynamically ensure children order inside hbox matches side configuration
		var hbox = get_child(0) as HBoxContainer
		if hbox != null:
			hbox.alignment = BoxContainer.ALIGNMENT_END if is_left else BoxContainer.ALIGNMENT_BEGIN
			if is_left:
				if hbox.get_child_count() >= 2 and hbox.get_child(0) == avatar_panel:
					hbox.move_child(text_vbox, 0)
			else:
				if hbox.get_child_count() >= 2 and hbox.get_child(0) == text_vbox:
					hbox.move_child(avatar_panel, 0)
		_apply_text_alignment()
		
		var name_str := String(player_data.get("player_name", ""))
		var chips := int(player_data.get("chips", 0))
		var is_local := bool(player_data.get("is_local", false))
		var is_turn := bool(player_data.get("is_turn", false))
		var last_action := String(player_data.get("last_action", ""))
		var last_action_amount := int(player_data.get("last_action_amount", 0))
		var status_value := String(player_data.get("raw_status", player_data.get("status", "")))
		var is_ready: bool = bool(player_data.get("ready", status_value == "ready"))
		var is_fold := status_value == "folded"
		var player_id := String(player_data.get("player_id", ""))
		
		# Load avatar image
		var av_idx: int = int(abs(player_id.hash())) % 7
		var av_paths := [
			"res://assets/ChatGPT Image 2026年6月24日 22_13_22 (1).png",
			"res://assets/ChatGPT Image 2026年6月24日 22_13_23 (2).png",
			"res://assets/ChatGPT Image 2026年6月24日 22_13_23 (3).png",
			"res://assets/ChatGPT Image 2026年6月24日 22_13_25 (4).png",
			"res://assets/ChatGPT Image 2026年6月24日 22_13_25 (5).png",
			"res://assets/ChatGPT Image 2026年6月24日 22_13_26 (6).png",
			"res://assets/ChatGPT Image 2026年6月24日 22_13_26 (7).png"
		]
		if ResourceLoader.exists(av_paths[av_idx]):
			avatar_rect.texture = load(av_paths[av_idx])
			
		var avatar_texture: Texture2D = player_data.get("avatar_texture", null) as Texture2D
		avatar_rect.texture = avatar_texture
		avatar_rect.visible = avatar_texture != null
		
		name_label.text = name_str
		you_badge.visible = is_local
		
		chips_label.text = _format_chips(chips)
		
		# Determine target visual styling
		var target_x: float = _active_offset() if is_turn else 0.0
		var target_bg: Color
		var target_border: Color
		var target_border_width := 1
		
		if is_fold:
			_is_fold = true
			modulate = Color(1, 1, 1, 0.3)
			avatar_rect.modulate = Color(0.4, 0.4, 0.4, 1.0)
			action_label.text = "FOLD"
			action_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			action_label.visible = true
			target_bg = Color(0.08, 0.08, 0.08, 0.60)
			target_border = Color(0.2, 0.2, 0.2, 0.3)
			target_border_width = 1
		else:
			_is_fold = false
			modulate = Color.WHITE
			avatar_rect.modulate = Color.WHITE
			
			if is_local:
				target_bg = Color(0.16, 0.12, 0.25, 0.7)
				target_border = Color(1.0, 0.0, 0.5, 0.95) # Local: Neon Magenta Outline
				target_border_width = 2
			else:
				target_bg = Color(0.12, 0.09, 0.22, 0.75)
				target_border = Color(0.28, 0.22, 0.45, 0.6)
				target_border_width = 1
				
			if is_turn:
				action_label.visible = true
				action_label.text = _turn_text(is_local)
				action_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.42) if is_local else Color(0.46, 1.0, 0.86))
				target_bg = Color(0.22, 0.14, 0.45, 0.90)
				target_border = Color(0.0, 1.0, 0.7, 0.9) # Turn: Neon Cyan/Green Outline
				target_border_width = 1
			else:
				action_label.visible = true
				if last_action != "":
					action_label.text = _action_text(last_action, last_action_amount)
					action_label.add_theme_color_override("font_color", _action_color(last_action))
				elif status_value == "all_in":
					action_label.text = "ALL-IN"
					action_label.add_theme_color_override("font_color", _action_color("ALL-IN"))
				elif status_value == "waiting_next_hand":
					action_label.text = "READY NEXT HAND" if is_ready else "WAITING NEXT HAND"
					action_label.add_theme_color_override("font_color", Color(0.72, 0.78, 1.0))
				elif is_ready:
					action_label.text = "READY"
					action_label.add_theme_color_override("font_color", Color(0.42, 1.0, 0.72))
				else:
					action_label.text = "NOT READY"
					action_label.add_theme_color_override("font_color", Color(0.58, 0.78, 1.0))
					
		# Animate transition of position, style box background, border color (No scale changes!)
		if is_turn != _is_turn or is_fold != _is_fold or force_snap:
			_is_turn = is_turn
			
			if force_snap:
				position.x = target_x
				style_box.bg_color = target_bg
				style_box.border_color = target_border
				style_box.set_border_width_all(target_border_width)
			else:
				var duration := 0.15 # 0.15s tween
				if _tween:
					_tween.kill()
				_tween = create_tween().set_parallel(true)
				_tween.tween_property(self, "position:x", target_x, duration)
				_tween.tween_property(style_box, "bg_color", target_bg, 0.1 if is_turn else duration)
				_tween.tween_property(style_box, "border_color", target_border, duration)
				style_box.set_border_width_all(target_border_width)
				
		# Keep the dot row allocated so turn changes never resize or move rows.
		dots_hbox.visible = true
		dots_hbox.modulate.a = 1.0 if is_turn else 0.0
		
		# Configure borders & styling
		if is_local and not is_turn:
			style_box.border_color = Color(1.0, 0.0, 0.5, 0.95)
			style_box.set_border_width_all(2)
		elif not is_turn:
			style_box.set_border_width_all(target_border_width)
			style_box.border_color = target_border
			
	func _process(_delta: float) -> void:
		if _is_fold:
			return
			
		var is_local := bool(player_data.get("is_local", false))
		var is_turn := bool(player_data.get("is_turn", false))
		
		# Local Player Static Neon Border (No high frequency pulses)
		if is_local and not is_turn:
			style_box.border_color = Color(1.0, 0.0, 0.5, 0.95)
			style_box.set_border_width_all(2)
				
		# Dots Sequential Blink Marquee (1 -> 2 -> 3 -> off) at 1.0s slow intervals
		if is_turn:
			var t := Time.get_ticks_msec() / 1000.0
			var idx := int(t) % 4
			dot1.modulate.a = 1.0 if idx == 0 else 0.2
			dot2.modulate.a = 1.0 if idx == 1 else 0.2
			dot3.modulate.a = 1.0 if idx == 2 else 0.2
		
		# No blinking turn labels or fast pulsing borders
		action_label.modulate.a = 1.0
		
		# Maintain position X alignment when not tweening
		var target_x: float = _active_offset() if is_turn else 0.0
		if _tween == null or not _tween.is_valid() or not _tween.is_running():
			if position.x != target_x:
				position.x = target_x

	func set_turn_timer(remaining_seconds: int, total_seconds: int, active: bool) -> void:
		_turn_timer_active = active
		_turn_timer_remaining = max(remaining_seconds, 0)
		_turn_timer_total = max(total_seconds, 1)
		if not bool(player_data.get("is_turn", false)):
			return
		action_label.text = _turn_text(bool(player_data.get("is_local", false)))

	func _apply_text_alignment() -> void:
		var alignment := HORIZONTAL_ALIGNMENT_RIGHT if is_left else HORIZONTAL_ALIGNMENT_LEFT
		name_label.horizontal_alignment = alignment
		chips_label.horizontal_alignment = alignment
		action_label.horizontal_alignment = alignment
		dots_hbox.alignment = BoxContainer.ALIGNMENT_END if is_left else BoxContainer.ALIGNMENT_BEGIN

	func _active_offset() -> float:
		return 12.0 if is_left else -10.0

	func _format_chips(value: int) -> String:
		var s := str(value)
		var result := ""
		var count := 0
		for i in range(s.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = "," + result
			result = s[i] + result
			count += 1
		return result

	func _action_text(action_label: String, amount: int) -> String:
		var label := action_label.to_upper()
		if label == "WIN" and amount > 0:
			return "WIN +%s" % _format_chips(amount)
		if amount > 0 and label not in ["CHECK", "FOLD"]:
			return "%s %s" % [label, _format_chips(amount)]
		return label

	func _turn_text(is_local: bool) -> String:
		var base := "YOUR TURN" if is_local else "THINKING..."
		if _turn_timer_active:
			return "%s %ds" % [base, _turn_timer_remaining]
		return base

	func _action_color(action_label: String) -> Color:
		match action_label.to_upper():
			"FOLD":
				return Color(0.55, 0.55, 0.60)
			"CHECK", "CALL", "SB", "BB":
				return Color(0.62, 0.88, 1.0)
			"BET", "RAISE":
				return Color(1.0, 0.46, 0.94)
			"ALL-IN":
				return Color(1.0, 0.18, 0.42)
			"WIN":
				return Color(1.0, 0.82, 0.25)
		return Color(0.58, 0.78, 1.0)
