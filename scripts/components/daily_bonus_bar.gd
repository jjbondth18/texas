extends PanelContainer
class_name DailyBonusBar

func _ready() -> void:
	custom_minimum_size = Vector2(0, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.65), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	
	var row := HBoxContainer.new()
	row.name = "DailyBonusRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	
	var copy_box := VBoxContainer.new()
	copy_box.name = "DailyBonusCopyBox"
	copy_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_box.custom_minimum_size = Vector2(220, 1)
	row.add_child(copy_box)
	
	var title := Label.new()
	title.text = "DAILY BONUS"
	HomeTheme.make_font_settings(title, 18, HomeTheme.TEXT)
	copy_box.add_child(title)
	
	var copy := Label.new()
	copy.text = "Come back daily for bigger rewards."
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HomeTheme.make_font_settings(copy, 12, HomeTheme.MUTED)
	copy_box.add_child(copy)
	
	for bonus in MockHomeData.DAILY_BONUS:
		row.add_child(_bonus_cell(bonus))

func _bonus_cell(bonus: Dictionary) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(96, 68)
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.add_theme_stylebox_override("panel", _cell_style(bonus.get("active", false), false))
	
	# Fade claimed cells to 0.45 opacity for premium design contrast
	if bonus.get("claimed", false):
		cell.modulate.a = 0.45
		
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	cell.add_child(box)
	
	var day := Label.new()
	day.text = bonus["day"]
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(day, 11, HomeTheme.PINK if bonus.get("active", false) else HomeTheme.MUTED)
	box.add_child(day)
	
	var mark := Label.new()
	mark.text = "OK" if bonus.get("claimed", false) else ("*" if bonus.get("active", false) else "-")
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(mark, 16, HomeTheme.PINK if bonus.get("active", false) else HomeTheme.CYAN)
	box.add_child(mark)
	
	var amount := Label.new()
	amount.text = bonus["amount"]
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(amount, 12, HomeTheme.TEXT)
	box.add_child(amount)
	
	# Add a neat horizontal Magenta highlight indicator mark under the text for the active day
	if bonus.get("active", false):
		var active_indicator := ColorRect.new()
		active_indicator.custom_minimum_size = Vector2(16, 2)
		active_indicator.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		active_indicator.color = HomeTheme.PINK
		active_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(active_indicator)
		
	cell.mouse_entered.connect(func() -> void: cell.add_theme_stylebox_override("panel", _cell_style(bonus.get("active", false), true)))
	cell.mouse_exited.connect(func() -> void: cell.add_theme_stylebox_override("panel", _cell_style(bonus.get("active", false), false)))
	return cell

func _cell_style(active: bool, hovered: bool) -> StyleBoxFlat:
	var border := HomeTheme.PINK if active else (HomeTheme.CYAN if hovered else Color(0.2, 0.22, 0.35, 0.25))
	var bg := Color(0.025, 0.015, 0.04, 0.8) if active else Color(0.008, 0.01, 0.025, 0.6)
	if hovered:
		bg = bg.lightened(0.08)
	var style := HomeTheme.make_panel_style(bg, border, 7, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(border.r, border.g, border.b, 0.20 if active or hovered else 0.0)
	style.shadow_size = 12 if active or hovered else 0
	return style
