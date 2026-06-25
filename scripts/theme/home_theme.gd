extends RefCounted
class_name HomeTheme

const BG := Color(0.004, 0.006, 0.014, 1.0)
const BG_2 := Color(0.012, 0.017, 0.04, 1.0)
const PANEL := Color(0.018, 0.024, 0.055, 0.72)
const PANEL_DARK := Color(0.006, 0.009, 0.022, 0.68)
const CARD := Color(0.018, 0.022, 0.052, 0.82)
const CARD_HOVER := Color(0.033, 0.038, 0.082, 0.92)
const STROKE := Color(0.52, 0.62, 0.92, 0.30)
const CYAN := Color(0.52, 0.78, 1.0, 1.0)
const BLUE := Color(0.27, 0.36, 0.95, 1.0)
const PINK := Color(1.0, 0.28, 0.78, 1.0)
const PURPLE := Color(0.62, 0.36, 1.0, 1.0)
const GOLD := Color(1.0, 0.76, 0.36, 1.0)
const TEXT := Color(0.92, 0.94, 1.0, 1.0)
const MUTED := Color(0.55, 0.58, 0.72, 1.0)
const DIM := Color(0.32, 0.35, 0.48, 1.0)

static func make_panel_style(bg: Color = PANEL, border: Color = STROKE, radius: int = 8, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func make_font_settings(label: Label, size: int, color: Color = TEXT) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

static func make_button_style(bg: Color, border: Color, radius: int = 8) -> StyleBoxFlat:
	var style := make_panel_style(bg, border, radius, 1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
