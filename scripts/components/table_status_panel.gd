extends PanelContainer
class_name TableStatusPanel

signal exit_table_requested

var _rows_container: VBoxContainer
var _exit_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 暗玻璃背景 StyleBoxFlat
	var style := HomeTheme.make_panel_style(
		Color(0.008, 0.006, 0.015, 0.76),
		Color(1.0, 0.0, 0.5, 0.55), # Neon Magenta border
		12,
		1
	)
	add_theme_stylebox_override("panel", style)
	
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
	
	# Header Label / Ranking Badge
	var ranking_header := Button.new()
	ranking_header.text = "📊 RANKING"
	ranking_header.custom_minimum_size = Vector2(0, 36)
	ranking_header.disabled = true
	var hdr_style := StyleBoxFlat.new()
	hdr_style.set_corner_radius_all(18)
	hdr_style.bg_color = Color(0.06, 0.05, 0.12, 0.6)
	hdr_style.border_color = Color(0.35, 0.35, 0.45, 0.4)
	hdr_style.set_border_width_all(1)
	ranking_header.add_theme_stylebox_override("disabled", hdr_style)
	ranking_header.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.95))
	vbox.add_child(ranking_header)
	
	var status_label := Label.new()
	status_label.text = "PLAYER STATUS"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.85))
	vbox.add_child(status_label)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.add_theme_constant_override("separation", 10)
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
		
	# Clear previous rows physically to avoid leaks or overlaps
	for child in _rows_container.get_children():
		child.queue_free()
		
	var seats := Array(snapshot.get("seats", []))
	var active_players := []
	for seat_data in seats:
		var seat := Dictionary(seat_data)
		var status_str := String(seat.get("status", ""))
		var chips := int(seat.get("chips", 0))
		if status_str != "empty" and chips > 0:
			active_players.append(seat)
			
	# Sort leaderboard by chips descending
	active_players.sort_custom(func(a, b): return int(a.get("chips", 0)) > int(b.get("chips", 0)))
	
	# Instantiate player row pills
	for player in active_players:
		var pill := PlayerRowPill.new(player)
		_rows_container.add_child(pill)

# Inner class representing a high-fidelity player row pill in the list
class PlayerRowPill extends PanelContainer:
	var player_data: Dictionary
	var style_box: StyleBoxFlat
	var action_label: Label
	var avatar_rect: TextureRect
	var avatar_panel: Panel
	var name_label: Label
	var chips_label: Label
	
	func _init(data: Dictionary) -> void:
		player_data = data
		custom_minimum_size = Vector2(0, 74)
		
		style_box = StyleBoxFlat.new()
		style_box.corner_detail = 8
		style_box.set_corner_radius_all(12)
		style_box.anti_aliasing = true
		add_theme_stylebox_override("panel", style_box)
		
		# Set up margins
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		add_child(margin)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		margin.add_child(hbox)
		
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
		vbox.add_theme_constant_override("separation", 1)
		hbox.add_child(vbox)
		
		name_label = Label.new()
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(name_label)
		
		chips_label = Label.new()
		chips_label.add_theme_font_size_override("font_size", 14)
		chips_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox.add_child(chips_label)
		
		action_label = Label.new()
		action_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(action_label)
		
		_update_ui()
		
	func _update_ui() -> void:
		var name_str := String(player_data.get("player_name", ""))
		var chips := int(player_data.get("chips", 0))
		var is_local := bool(player_data.get("is_local", false))
		var is_turn := bool(player_data.get("is_turn", false))
		var last_action := String(player_data.get("last_action", ""))
		var is_fold := String(player_data.get("status", "")) == "fold"
		var player_id := String(player_data.get("player_id", ""))
		
		# Load avatar
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
			
		# Formatting chips with commas
		chips_label.text = _format_chips(chips)
		
		# Set folded style
		if is_fold:
			modulate = Color(1, 1, 1, 0.35)
			# Gray out avatar and text
			avatar_rect.modulate = Color(0.4, 0.4, 0.4, 1.0)
			action_label.text = "FOLD"
			action_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			style_box.bg_color = Color(0.04, 0.04, 0.06, 0.2)
			style_box.border_color = Color(0, 0, 0, 0)
			style_box.set_border_width_all(0)
		else:
			modulate = Color.WHITE
			avatar_rect.modulate = Color.WHITE
			style_box.bg_color = Color(0.06, 0.05, 0.12, 0.45)
			
			if is_turn:
				action_label.text = "YOUR TURN"
				action_label.add_theme_color_override("font_color", Color(0.65, 0.95, 0.0))
			elif last_action != "":
				action_label.text = last_action.to_upper()
				action_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5)) # pink action
			else:
				action_label.text = "ACTIVE"
				action_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0)) # cyan status
				
	func _process(_delta: float) -> void:
		var is_turn := bool(player_data.get("is_turn", false))
		var is_fold := String(player_data.get("status", "")) == "fold"
		if is_fold:
			return
			
		if is_turn:
			# Breathing border effect
			var time := Time.get_ticks_msec() / 1000.0
			var wave := 0.5 + 0.5 * sin(time * 6.0) # 0 to 1
			style_box.border_color = Color(0.65 + 0.13 * wave, 0.95 + 0.05 * wave, 0.0, 0.4 + 0.6 * wave)
			style_box.set_border_width_all(2)
			
			# Flashing Action Label
			var label_wave := 0.4 + 0.6 * sin(time * 12.0)
			action_label.modulate.a = label_wave
		else:
			style_box.set_border_width_all(1)
			style_box.border_color = Color(0.35, 0.22, 0.55, 0.25) # subtle purple border
			action_label.modulate.a = 1.0

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
