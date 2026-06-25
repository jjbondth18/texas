extends PanelContainer
class_name TopBar

signal exit_requested

var _name_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _chips_label: Label
var _premium_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(0, 64)
	add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.004, 0.006, 0.018, 0.18), Color(0.2, 0.28, 0.52, 0.0), 0, 0))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 14)
	add_child(row)

	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)

	var profile := HBoxContainer.new()
	profile.add_theme_constant_override("separation", 10)
	row.add_child(profile)

	var avatar := Panel.new()
	avatar.custom_minimum_size = Vector2(44, 44)
	avatar.add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.08, 0.07, 0.13, 1), Color(0.82, 0.78, 1.0, 0.8), 22, 1))
	profile.add_child(avatar)

	var profile_text := VBoxContainer.new()
	profile_text.add_theme_constant_override("separation", 3)
	profile.add_child(profile_text)
	_name_label = Label.new()
	HomeTheme.make_font_settings(_name_label, 16)
	profile_text.add_child(_name_label)
	_level_label = Label.new()
	HomeTheme.make_font_settings(_level_label, 11, HomeTheme.MUTED)
	profile_text.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(170, 5)
	_xp_bar.show_percentage = false
	profile_text.add_child(_xp_bar)

	_chips_label = _currency_pill(row, "CHIPS", HomeTheme.GOLD)
	_premium_label = _currency_pill(row, "GEMS", HomeTheme.PINK)
	for text in ["+", "FR", "MSG", "SET"]:
		row.add_child(_top_icon(text))
	var exit_button := _top_icon("EXIT")
	exit_button.custom_minimum_size = Vector2(58, 40)
	exit_button.pressed.connect(func() -> void: exit_requested.emit())
	row.add_child(exit_button)

func configure(player: Dictionary) -> void:
	if not is_node_ready():
		await ready
	_name_label.text = player.get("name", player.get("player_name", ""))
	
	var xp_txt := String(player.get("xp_text", ""))
	var xp_current := 0
	var xp_max := 1
	if xp_txt != "":
		var xp_parts := xp_txt.split(" ")
		if xp_parts.size() >= 3:
			xp_current = xp_parts[0].to_int()
			xp_max = xp_parts[2].to_int()
	else:
		xp_current = int(player.get("xp_current", 0))
		xp_max = int(player.get("xp_max", 1))
		xp_txt = "%d / %d XP" % [xp_current, xp_max]
		
	_level_label.text = "LEVEL %s  |  %s" % [player.get("level", 1), xp_txt]
	_xp_bar.max_value = max(xp_max, 1)
	_xp_bar.value = xp_current
	
	var chips_val = player.get("chips", 0)
	_chips_label.text = "%s" % _format_number(chips_val)
	
	var premium_val = player.get("gems", player.get("premium_currency", 0))
	_premium_label.text = "%s" % _format_number(premium_val)

func _currency_pill(parent: Container, title: String, color: Color) -> Label:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(132, 40)
	pill.mouse_filter = Control.MOUSE_FILTER_PASS
	pill.add_theme_stylebox_override("panel", _currency_style(color, false))
	pill.mouse_entered.connect(func() -> void: pill.add_theme_stylebox_override("panel", _currency_style(color, true)))
	pill.mouse_exited.connect(func() -> void: pill.add_theme_stylebox_override("panel", _currency_style(color, false)))
	parent.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	var dot := ColorRect.new()
	dot.color = color
	dot.custom_minimum_size = Vector2(8, 8)
	row.add_child(dot)
	var text_box := VBoxContainer.new()
	row.add_child(text_box)
	var label := Label.new()
	label.text = title
	HomeTheme.make_font_settings(label, 9, HomeTheme.MUTED)
	text_box.add_child(label)
	var value := Label.new()
	HomeTheme.make_font_settings(value, 15, HomeTheme.TEXT)
	text_box.add_child(value)
	return value

func _currency_style(color: Color, hovered: bool) -> StyleBoxFlat:
	var bg := Color(0.02, 0.023, 0.052, 0.72 if not hovered else 0.86)
	var border := color.darkened(0.2) if not hovered else color
	var style := HomeTheme.make_panel_style(bg, border, 20, 1)
	style.shadow_color = Color(color.r, color.g, color.b, 0.18 if hovered else 0.04)
	style.shadow_size = 12 if hovered else 4
	return style

func _top_icon(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(40, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", HomeTheme.MUTED)
	button.add_theme_color_override("font_hover_color", HomeTheme.TEXT)
	button.add_theme_stylebox_override("normal", _icon_style(Color(0.018, 0.022, 0.052, 0.58), Color(0.36, 0.42, 0.7, 0.18)))
	button.add_theme_stylebox_override("hover", _icon_style(Color(0.035, 0.04, 0.085, 0.82), Color(0.78, 0.58, 1.0, 0.55)))
	return button

func _icon_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := HomeTheme.make_panel_style(bg, border, 20, 1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _format_number(value: int) -> String:
	var text := str(value)
	var output := ""
	while text.length() > 3:
		output = "," + text.substr(text.length() - 3, 3) + output
		text = text.substr(0, text.length() - 3)
	return text + output
