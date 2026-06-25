extends PanelContainer
class_name TableStatusPanel

signal exit_table_requested

var _text: RichTextLabel
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
	
	# VBox container for separating RichTextLabel and Exit Button
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_text)
	
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
	if _text == null:
		return
	var seats := Array(snapshot.get("seats", []))
	var active_players := []
	for seat_data in seats:
		var seat := Dictionary(seat_data)
		if String(seat.get("status", "")) != "empty":
			active_players.append(seat)
			
	# Sort leaderboard by chips descending
	active_players.sort_custom(func(a, b): return int(a.get("chips", 0)) > int(b.get("chips", 0)))
	
	var lines := []
	lines.append("[center][color=#ff0080][b]LEADERBOARD[/b][/color][/center]")
	var rank := 1
	for player in active_players:
		var name_str := String(player.get("player_name", ""))
		var chips := int(player.get("chips", 0))
		var is_local := bool(player.get("is_local", false))
		var color_tag := "[color=#00c8ff]" if is_local else "[color=#ffffff]"
		lines.append(" %d. %s%s[/color]: [color=#ffdd70]%d[/color]" % [rank, color_tag, name_str, chips])
		rank += 1
		
	lines.append("")
	lines.append("[center][color=#9b5cff][b]LIVE STATS[/b][/color][/center]")
	lines.append(" VPIP: [color=#00c8ff]24.5%[/color]  PFR: [color=#ff0080]18.2%[/color]")
	lines.append(" 3-Bet: [color=#00ff80]6.8%[/color]  AF: [color=#ffdd70]2.1[/color]")
	lines.append(" Win Rate: [color=#ff8000]54.2%[/color]")
	
	lines.append("")
	lines.append("[center][color=#00ff80][b]OPPONENT ACTIONS[/b][/color][/center]")
	for seat_data in seats:
		var seat := Dictionary(seat_data)
		var status_str := String(seat.get("status", ""))
		if status_str != "empty":
			var name_str := String(seat.get("player_name", ""))
			var is_turn := bool(seat.get("is_turn", false))
			var last_action := String(seat.get("last_action", ""))
			var is_local := bool(seat.get("is_local", false))
			
			var action_suffix := ""
			if last_action != "":
				action_suffix = " (%s)" % last_action.to_upper()
				
			var indicator := ""
			if is_turn:
				indicator = "[color=#ff0080]>[/color] "
			elif is_local:
				indicator = "[color=#00ffff]*[/color] "
			else:
				indicator = "  "
				
			var role := " (YOU)" if is_local else ""
			var line := "%s%s%s%s" % [indicator, name_str, role, action_suffix]
			if is_turn:
				line = "[b]%s[/b]" % line
			lines.append(line)
			
	_text.text = "\n".join(lines)
