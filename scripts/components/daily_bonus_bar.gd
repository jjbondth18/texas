extends PanelContainer
class_name DailyBonusBar

func _ready() -> void:
	custom_minimum_size = Vector2(0, 96)
	add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.01, 0.012, 0.03, 0.48), Color(0.48, 0.4, 0.86, 0.24), 8, 1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var copy_box := VBoxContainer.new()
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
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	cell.add_child(box)
	var day := Label.new()
	day.text = bonus["day"]
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(day, 11, HomeTheme.TEXT if bonus.get("active", false) else HomeTheme.MUTED)
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
	cell.mouse_entered.connect(func() -> void: cell.add_theme_stylebox_override("panel", _cell_style(bonus.get("active", false), true)))
	cell.mouse_exited.connect(func() -> void: cell.add_theme_stylebox_override("panel", _cell_style(bonus.get("active", false), false)))
	return cell

func _cell_style(active: bool, hovered: bool) -> StyleBoxFlat:
	var border := HomeTheme.PINK if active else (HomeTheme.CYAN if hovered else Color(0.42, 0.44, 0.7, 0.24))
	var bg := Color(0.035, 0.022, 0.07, 0.72) if active else Color(0.016, 0.02, 0.048, 0.58)
	if hovered:
		bg = bg.lightened(0.08)
	var style := HomeTheme.make_panel_style(bg, border, 7, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(border.r, border.g, border.b, 0.18 if active or hovered else 0.0)
	style.shadow_size = 12 if active or hovered else 0
	return style
