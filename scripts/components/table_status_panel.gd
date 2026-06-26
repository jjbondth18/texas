extends PanelContainer
class_name TableStatusPanel

signal exit_table_requested

var _rows_container: VBoxContainer
var _exit_button: Button
var _pills := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Transparent panel background
	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty_style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
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
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.85))
	status_margin.add_child(status_label)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.add_theme_constant_override("separation", 12) # Fixed separation 12
	scroll.add_child(_rows_container)
	
	_exit_button = Button.new()
	_exit_button.text = "EXIT TABLE"
	_exit_button.custom_minimum_size = Vector2(0, 42)
	_exit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Premium neon styling for exit button
	var btn_normal := HomeTheme.make_button_style(Color(0.22, 0.08, 0.18, 0.60), Color(1.0, 0.0, 0.5, 0.80), 18)
	var btn_hover := HomeTheme.make_button_style(Color(0.32, 0.12, 0.26, 0.80), Color(1.0, 0.0, 0.5, 1.0), 18)
	_exit_button.add_theme_stylebox_override("normal", btn_normal)
	_exit_button.add_theme_stylebox_override("hover", btn_hover)
	_exit_button.add_theme_stylebox_override("pressed", btn_hover)
	_exit_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_exit_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	_exit_button.add_theme_font_size_override("font_size", 14)
	
	_exit_button.pressed.connect(func() -> void:
		exit_table_requested.emit()
	)
	vbox.add_child(_exit_button)

func set_status(snapshot: Dictionary) -> void:
	if _rows_container == null:
		return
		
	var seats := Array(snapshot.get("seats", []))
	var active_players := []
	var active_seats := []
	
	for seat_data in seats:
		var seat := Dictionary(seat_data)
		var status_str := String(seat.get("status", ""))
		var chips := int(seat.get("chips", 0))
		if status_str != "empty" and chips > 0:
			active_players.append(seat)
			active_seats.append(int(seat.get("seat_index", 0)))
			
	# Sort leaderboard by seat_index ascending (strictly 1 to 9)
	active_players.sort_custom(func(a, b): return int(a.get("seat_index", 0)) < int(b.get("seat_index", 0)))
	
	# Remove pills for seats that are no longer active/present
	for seat_idx in _pills.keys():
		if seat_idx not in active_seats:
			_pills[seat_idx].queue_free()
			_pills.erase(seat_idx)
			
	# Instantiate or update player row pills
	for player in active_players:
		var seat_idx := int(player.get("seat_index", 0))
		if _pills.has(seat_idx):
			_pills[seat_idx].update_data(player)
		else:
			var pill := PlayerRowPill.new(player)
			_pills[seat_idx] = pill
			_rows_container.add_child(pill)
			
	# Enforce correct sorting order in VBoxContainer
	for i in range(active_players.size()):
		var player = active_players[i]
		var seat_idx := int(player.get("seat_index", 0))
		var pill = _pills[seat_idx]
		_rows_container.move_child(pill, i)

# Inner class representing a high-fidelity sliding player row pill in the list
class PlayerRowPill extends PanelContainer:
	var player_data: Dictionary
	var style_box: StyleBoxFlat
	var action_label: Label
	var avatar_rect: TextureRect
	var avatar_panel: Panel
	var name_label: Label
	var chips_label: Label
	
	# Turn dots
	var dots_hbox: HBoxContainer
	var dot1: Panel
	var dot2: Panel
	var dot3: Panel
	
	var _is_turn := false
	var _is_fold := false
	var _tween: Tween
	
	func _init(data: Dictionary) -> void:
		player_data = data
		custom_minimum_size = Vector2(280, 85)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pivot_offset = Vector2(140, 42.5) # Center pivot for 280x85 card
		
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
		add_child(hbox)
		
		# Circular Avatar Container
		avatar_panel = Panel.new()
		avatar_panel.custom_minimum_size = Vector2(48, 48)
		avatar_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		avatar_panel.clip_children = Control.CLIP_CHILDREN_AND_DRAW
		
		var av_style := StyleBoxFlat.new()
		av_style.set_corner_radius_all(24)
		avatar_panel.add_theme_stylebox_override("panel", av_style)
		hbox.add_child(avatar_panel)
		
		avatar_rect = TextureRect.new()
		avatar_rect.custom_minimum_size = Vector2(48, 48)
		avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar_panel.add_child(avatar_rect)
		
		# Text Container
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)
		
		name_label = Label.new()
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(name_label)
		
		# HBox for flashing dots marquee underneath name
		dots_hbox = HBoxContainer.new()
		dots_hbox.add_theme_constant_override("separation", 4)
		dots_hbox.visible = false
		vbox.add_child(dots_hbox)
		
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
		chips_label.add_theme_font_size_override("font_size", 14)
		chips_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox.add_child(chips_label)
		
		action_label = Label.new()
		action_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(action_label)
		
		# Initial config
		update_data(data, true)
		
	func update_data(data: Dictionary, force_snap: bool = false) -> void:
		player_data = data
		var name_str := String(player_data.get("player_name", ""))
		var chips := int(player_data.get("chips", 0))
		var is_local := bool(player_data.get("is_local", false))
		var is_turn := bool(player_data.get("is_turn", false))
		var last_action := String(player_data.get("last_action", ""))
		var is_fold := String(player_data.get("status", "")) == "fold"
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
			
		name_label.text = name_str
		if is_local:
			name_label.text += " (YOU)"
			
		chips_label.text = _format_chips(chips)
		
		# Determine target visual styling
		var target_x: float = 0.0
		var target_scale := Vector2(1.0, 1.0)
		var target_bg: Color
		
		if is_fold:
			_is_fold = true
			modulate = Color(1, 1, 1, 0.3)
			avatar_rect.modulate = Color(0.4, 0.4, 0.4, 1.0)
			action_label.text = "FOLD"
			action_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			action_label.visible = true
			target_bg = Color(0.08, 0.08, 0.08, 0.3)
		else:
			_is_fold = false
			modulate = Color.WHITE
			avatar_rect.modulate = Color.WHITE
			
			if is_local:
				target_bg = Color(0.16, 0.12, 0.25, 0.7)
			else:
				target_bg = Color(0.12, 0.1, 0.18, 0.6)
				
			if is_turn:
				action_label.visible = false
				target_x = -30.0
				target_scale = Vector2(1.15, 1.15)
				target_bg = Color(0.24, 0.12, 0.36, 0.85) # High saturation bright violet
			else:
				action_label.visible = true
				if last_action != "":
					action_label.text = last_action.to_upper()
					action_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))
				else:
					action_label.text = "ACTIVE"
					action_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
					
		# Animate transition of position, scale, and style box background
		if is_turn != _is_turn or is_fold != _is_fold or force_snap:
			_is_turn = is_turn
			
			if force_snap:
				position.x = target_x
				scale = target_scale
				style_box.bg_color = target_bg
			else:
				var duration := 0.2 if is_turn else 0.15
				if _tween:
					_tween.kill()
				_tween = create_tween().set_parallel(true)
				_tween.tween_property(self, "position:x", target_x, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_tween.tween_property(style_box, "bg_color", target_bg, 0.1 if is_turn else duration)
				
		# Update dots visibility
		dots_hbox.visible = is_turn
		
		# Configure borders & styling
		if is_local:
			style_box.border_color = Color(1.0, 0.0, 0.5, 0.95)
			style_box.set_border_width_all(2)
		else:
			style_box.set_border_width_all(0)
			style_box.border_color = Color(0, 0, 0, 0)
			
	func _process(_delta: float) -> void:
		if _is_fold:
			return
			
		var is_local := bool(player_data.get("is_local", false))
		var is_turn := bool(player_data.get("is_turn", false))
		
		# Local Player Static Neon Border (No high frequency pulses)
		if is_local:
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
		
		# Maintain position X and scale alignment when not tweening
		var target_x: float = -30.0 if _is_turn else 0.0
		var target_scale := Vector2(1.15, 1.15) if _is_turn else Vector2(1.0, 1.0)
		if _tween == null or not _tween.is_valid() or not _tween.is_running():
			if position.x != target_x:
				position.x = target_x
			if scale != target_scale:
				scale = target_scale

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
