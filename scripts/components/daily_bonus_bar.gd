extends PanelContainer
class_name DailyBonusBar

signal claim_pressed

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")
const LocalizationManagerScript := preload("res://scripts/services/localization_manager.gd")

var _state: Dictionary = {}
var _row: HBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(0, 112)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", HomeTheme.make_panel_style(Color(0.006, 0.008, 0.016, 0.65), Color(0.2, 0.24, 0.38, 0.25), 8, 1))
	_build_static_shell()

func configure(data: Dictionary) -> void:
	_state = data.duplicate(true)
	if _row == null:
		return
	_rebuild_cells()

func _build_static_shell() -> void:
	_row = HBoxContainer.new()
	_row.name = "DailyBonusRow"
	_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_row.add_theme_constant_override("separation", 12)
	add_child(_row)
	_rebuild_cells()

func _rebuild_cells() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var copy_box := VBoxContainer.new()
	copy_box.name = "DailyBonusCopyBox"
	copy_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_box.custom_minimum_size = Vector2(250, 1)
	_row.add_child(copy_box)
	var title := Label.new()
	title.text = LocalizationManagerScript.tr_key("daily.title")
	HomeTheme.make_font_settings(title, 18, HomeTheme.TEXT)
	copy_box.add_child(title)
	var copy := Label.new()
	copy.text = LocalizationManagerScript.tr_key("daily.copy")
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HomeTheme.make_font_settings(copy, 12, HomeTheme.MUTED)
	copy_box.add_child(copy)
	var progress := Label.new()
	progress.text = LocalizationManagerScript.trf("daily.progress", {"claimed": int(_state.get("claimed_days_in_cycle", 0))})
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HomeTheme.make_font_settings(progress, 13, HomeTheme.CYAN)
	copy_box.add_child(progress)
	var action := Label.new()
	if bool(_state.get("claimed_today", false)):
		action.text = LocalizationManagerScript.trf("daily.next_tomorrow", {"day": int(_state.get("next_reward_day", 1))})
	else:
		action.text = LocalizationManagerScript.trf("daily.today_claim", {"day": int(_state.get("current_day", 1))})
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(action, 12, HomeTheme.TEXT)
	copy_box.add_child(action)
	var days: Array = Array(_state.get("days", []))
	if days.is_empty():
		days = Array(PlayerProfileScript.daily_bonus_display_state(PlayerProfileScript.default_profile()).get("days", []))
	for bonus in days:
		_row.add_child(_bonus_cell(Dictionary(bonus)))

func _bonus_cell(bonus: Dictionary) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(112, 84)
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	var active: bool = bool(bonus.get("active", false))
	var claimed: bool = bool(bonus.get("claimed", false))
	var claimed_today: bool = bool(bonus.get("claimed_today_card", false))
	var next: bool = bool(bonus.get("next", false))
	var locked: bool = bool(bonus.get("locked", bonus.get("future", false)))
	var highlighted: bool = bool(bonus.get("highlight", active or claimed_today))
	var soft_highlighted: bool = bool(bonus.get("soft_highlight", next))
	cell.add_theme_stylebox_override("panel", _cell_style(highlighted, soft_highlighted, false))
	if claimed and not claimed_today:
		cell.modulate.a = 0.64
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	cell.add_child(box)
	var day := Label.new()
	day.text = LocalizationManagerScript.trf("daily.day", {"day": int(bonus.get("day", 1))})
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeTheme.make_font_settings(day, 11, HomeTheme.PINK if highlighted else HomeTheme.MUTED)
	box.add_child(day)
	var status_text := _localized_status_text(str(bonus.get("status_text", "LOCKED" if locked else "-")))
	if active:
		var claim_button := Button.new()
		claim_button.text = status_text
		claim_button.custom_minimum_size = Vector2(82, 24)
		claim_button.focus_mode = Control.FOCUS_NONE
		claim_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		claim_button.add_theme_stylebox_override("normal", HomeTheme.make_button_style(Color(0.020, 0.035, 0.060, 0.86), HomeTheme.PINK, 12))
		claim_button.add_theme_stylebox_override("hover", HomeTheme.make_button_style(Color(0.045, 0.050, 0.105, 0.96), HomeTheme.CYAN, 12))
		claim_button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.98, 1.0))
		claim_button.pressed.connect(func() -> void:
			claim_pressed.emit()
		)
		box.add_child(claim_button)
	else:
		var mark := Label.new()
		mark.text = status_text
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var status_color := HomeTheme.MUTED
		if claimed_today:
			status_color = HomeTheme.PINK
		elif next:
			status_color = HomeTheme.CYAN
		elif claimed:
			status_color = HomeTheme.MUTED
		HomeTheme.make_font_settings(mark, 11 if status_text.length() > 9 else 13, status_color)
		box.add_child(mark)
	var rewards := Label.new()
	rewards.text = _reward_text(bonus)
	rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HomeTheme.make_font_settings(rewards, 11, HomeTheme.TEXT)
	box.add_child(rewards)
	cell.mouse_entered.connect(func() -> void: cell.add_theme_stylebox_override("panel", _cell_style(highlighted, soft_highlighted, true)))
	cell.mouse_exited.connect(func() -> void: cell.add_theme_stylebox_override("panel", _cell_style(highlighted, soft_highlighted, false)))
	return cell

func _reward_text(bonus: Dictionary) -> String:
	var parts: Array[String] = []
	var chips: int = int(bonus.get("chips", 0))
	var xp: int = int(bonus.get("xp", 0))
	var gems: int = int(bonus.get("gems", 0))
	if chips > 0:
		parts.append(LocalizationManagerScript.trf("daily.chips", {"amount": _format_number(chips)}))
	if xp > 0:
		parts.append(LocalizationManagerScript.trf("daily.xp", {"amount": xp}))
	if gems > 0:
		parts.append(LocalizationManagerScript.trf("daily.gems", {"amount": gems}))
	return "\n".join(parts)

func _localized_status_text(status_text: String) -> String:
	match status_text:
		"CLAIM":
			return LocalizationManagerScript.tr_key("daily.claim")
		"CLAIMED":
			return LocalizationManagerScript.tr_key("daily.claimed")
		"CLAIMED TODAY":
			return LocalizationManagerScript.tr_key("daily.claimed_today")
		"NEXT":
			return LocalizationManagerScript.tr_key("daily.next")
		"LOCKED":
			return LocalizationManagerScript.tr_key("daily.locked")
	return status_text

func _format_number(value: int) -> String:
	var raw := str(abs(value))
	var out := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = raw.substr(index, 1) + out
		count += 1
	return ("-" if value < 0 else "") + out

func _cell_style(highlighted: bool, soft_highlighted: bool, hovered: bool) -> StyleBoxFlat:
	var border := Color(0.2, 0.22, 0.35, 0.25)
	if highlighted:
		border = HomeTheme.PINK
	elif soft_highlighted:
		border = Color(HomeTheme.CYAN.r, HomeTheme.CYAN.g, HomeTheme.CYAN.b, 0.55)
	elif hovered:
		border = Color(0.2, 0.22, 0.35, 0.45)
	var bg := Color(0.025, 0.015, 0.04, 0.8) if highlighted else Color(0.008, 0.01, 0.025, 0.6)
	if hovered:
		bg = bg.lightened(0.08)
	var style := HomeTheme.make_panel_style(bg, border, 7, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(border.r, border.g, border.b, 0.20 if highlighted or hovered else 0.0)
	style.shadow_size = 12 if highlighted or hovered else 0
	return style
