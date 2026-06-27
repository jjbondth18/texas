extends Control
class_name ActionBar

signal action_pressed(action: Dictionary)

var actions: Array[Dictionary] = []
var pot_amount: int = 0

var _fold_action: Dictionary
var _check_call_action: Dictionary
var _raise_action: Dictionary

# Public properties for Three-Compartment console references
@onready var chips_label: Label = $PlayerInfoPanel/ChipsLabel
@onready var profit_label: Label = $PlayerInfoPanel/ProfitLabel
@onready var winrate_label: Label = $PlayerInfoPanel/WinRateLabel

@onready var timer_label: Label = $HoleCardsPanel/TurnTimer
@onready var local_cards_root: Control = $HoleCardsPanel/LocalHoleCards

# Right segment controls
@onready var _fold_button: Button = $ActionPanel/MainButtons/FoldButton
@onready var _check_call_button: Button = $ActionPanel/MainButtons/CheckCallButton
@onready var _raise_confirm_button: Button = $ActionPanel/MainButtons/BetRaiseButton
@onready var _minus_button: Button = $ActionPanel/RaiseControlPanel/MinusButton
@onready var _plus_button: Button = $ActionPanel/RaiseControlPanel/PlusButton
@onready var _h_slider: HSlider = $ActionPanel/RaiseControlPanel/RaiseSlider
@onready var _pot_25_button: Button = $ActionPanel/RaiseControlPanel/PotMultiplierButton
@onready var _max_button: Button = $ActionPanel/RaiseControlPanel/MaxButton
@onready var _raise_value_label: Label = $ActionPanel/RaiseControlPanel/RaiseValueLabel

@onready var _avatar_rect: TextureRect = $PlayerInfoPanel/AvatarPanel/AvatarRect

func _ready() -> void:
	# 🛑 1. 左段：数据舱 (PlayerInfoPanel) Style Box Override
	var left_panel := $PlayerInfoPanel
	var lp_style := StyleBoxFlat.new()
	lp_style.bg_color = Color(0.10, 0.07, 0.18, 0.85) # Dark purple-black bg
	lp_style.set_corner_radius_all(8)
	lp_style.border_color = Color(0.35, 0.28, 0.55, 0.7) # Clear high-light border
	lp_style.set_border_width_all(1)
	left_panel.add_theme_stylebox_override("panel", lp_style)
	
	# Circular Big Avatar
	var avatar_panel := $PlayerInfoPanel/AvatarPanel
	var av_style := StyleBoxFlat.new()
	av_style.set_corner_radius_all(36)
	avatar_panel.add_theme_stylebox_override("panel", av_style)
	
	_avatar_rect.texture = load("res://assets/ChatGPT Image 2026年6月24日 22_13_25 (5).png") # Luna avatar
	
	chips_label.add_theme_font_size_override("font_size", 16)
	chips_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42)) # Gold
	
	var bold_font := SystemFont.new()
	bold_font.font_names = PackedStringArray(["sans-serif", "Segoe UI", "Arial"])
	bold_font.font_weight = 700
	chips_label.add_theme_font_override("font", bold_font)
	
	profit_label.add_theme_font_size_override("font_size", 14)
	
	winrate_label.add_theme_font_size_override("font_size", 14)
	winrate_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5)) # Neon Magenta
	
	# 🛑 2. 中段：卡牌与计时专用独立舱 (HoleCardsPanel) Style Box Override
	var center_panel := $HoleCardsPanel
	var cp_style := StyleBoxFlat.new()
	cp_style.bg_color = Color(0.10, 0.07, 0.18, 0.85) # Dark purple-black bg
	cp_style.set_corner_radius_all(8)
	cp_style.border_color = Color(0.35, 0.28, 0.55, 0.7) # Clear high-light border
	cp_style.set_border_width_all(1)
	center_panel.add_theme_stylebox_override("panel", cp_style)
	
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 13)
	timer_label.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
	
	# 🛑 3. 右段：加注与按钮控制台 (ActionPanel) Style Box Override
	var right_panel := $ActionPanel
	var rp_style := StyleBoxFlat.new()
	rp_style.bg_color = Color(0.10, 0.07, 0.18, 0.85) # Dark purple-black bg
	rp_style.set_corner_radius_all(8)
	rp_style.border_color = Color(0.35, 0.28, 0.55, 0.7) # Clear high-light border
	rp_style.set_border_width_all(1)
	right_panel.add_theme_stylebox_override("panel", rp_style)
	
	# Style buttons and slider
	_style_action_button(_fold_button, Color(0.45, 0.45, 0.52)) # Muted Gray-Violet
	_style_action_button(_check_call_button, Color(1.0, 0.0, 0.5)) # Neon Magenta
	_style_action_button(_raise_confirm_button, Color(0.0, 0.75, 1.0)) # Bright Neon Cyan
	
	_style_adjust_button(_minus_button)
	_style_adjust_button(_plus_button)
	_style_h_slider(_h_slider)
	
	_raise_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raise_value_label.add_theme_font_size_override("font_size", 16)
	_raise_value_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0)) # Cyan glow
	_raise_value_label.add_theme_font_override("font", bold_font)
	
	_style_quick_button(_pot_25_button)
	_style_quick_button(_max_button)
	
	# Event bindings
	_fold_button.pressed.connect(func(): action_pressed.emit(_fold_action.duplicate(true)))
	_check_call_button.pressed.connect(func(): action_pressed.emit(_check_call_action.duplicate(true)))
	_raise_confirm_button.pressed.connect(_on_raise_confirm_pressed)
	
	_h_slider.value_changed.connect(_on_slider_value_changed)
	
	_minus_button.pressed.connect(func():
		var step = int(max(10, (_h_slider.max_value - _h_slider.min_value) / 50))
		_h_slider.value = clamp(_h_slider.value - step, _h_slider.min_value, _h_slider.max_value)
	)
	_plus_button.pressed.connect(func():
		var step = int(max(10, (_h_slider.max_value - _h_slider.min_value) / 50))
		_h_slider.value = clamp(_h_slider.value + step, _h_slider.min_value, _h_slider.max_value)
	)
	
	_pot_25_button.pressed.connect(func():
		if pot_amount > 0:
			_h_slider.value = clamp(2.5 * pot_amount, _h_slider.min_value, _h_slider.max_value)
	)
	_max_button.pressed.connect(func():
		_h_slider.value = _h_slider.max_value
	)

func set_actions(new_actions: Array, current_pot: int = 0) -> void:
	actions = []
	for action in new_actions:
		actions.append(Dictionary(action).duplicate(true))
	pot_amount = current_pot
	
	_fold_action = {}
	_check_call_action = {}
	_raise_action = {}
	
	# Parse available actions
	for action in actions:
		var action_id := String(action.get("id", ""))
		if action_id == "fold":
			_fold_action = action
		elif action_id in ["check", "call"]:
			if _check_call_action.is_empty() or action_id == "call":
				_check_call_action = action
		elif action_id in ["bet", "raise"]:
			_raise_action = action
			
	# Update Fold Button
	if not _fold_action.is_empty():
		_fold_button.disabled = not bool(_fold_action.get("enabled", true))
		_fold_button.text = String(_fold_action.get("label", "FOLD")).to_upper()
	else:
		_fold_button.disabled = true
		_fold_button.text = "FOLD"
		
	# Update Check/Call Button
	if not _check_call_action.is_empty():
		_check_call_button.disabled = not bool(_check_call_action.get("enabled", true))
		var amt = int(_check_call_action.get("amount", 0))
		if amt > 0:
			_check_call_button.text = "CALL %d" % amt
		else:
			_check_call_button.text = "CHECK"
	else:
		_check_call_button.disabled = true
		_check_call_button.text = "CHECK"
		
	# Update Raise Slider and Confirm Button
	if not _raise_action.is_empty():
		var enabled = bool(_raise_action.get("enabled", true))
		_raise_confirm_button.disabled = not enabled
		_minus_button.disabled = not enabled
		_plus_button.disabled = not enabled
		_h_slider.editable = enabled
		_pot_25_button.disabled = not enabled
		_max_button.disabled = not enabled
		
		var min_amt = int(_raise_action.get("min_amount", 100))
		var max_amt = int(_raise_action.get("max_amount", 5000))
		
		_h_slider.min_value = min_amt
		_h_slider.max_value = max_amt
		_h_slider.value = min_amt
		
		var action_id = String(_raise_action.get("id", "raise")).to_upper()
		_raise_confirm_button.text = action_id
		_raise_value_label.text = _format_chips(min_amt)
	else:
		_raise_confirm_button.disabled = true
		_minus_button.disabled = true
		_plus_button.disabled = true
		_h_slider.editable = false
		_pot_25_button.disabled = true
		_max_button.disabled = true
		_raise_confirm_button.text = "RAISE"
		_raise_value_label.text = "0"

func _on_slider_value_changed(val: float) -> void:
	var rounded_val = int(val)
	if not _raise_action.is_empty():
		_raise_value_label.text = _format_chips(rounded_val)

func _on_raise_confirm_pressed() -> void:
	if not _raise_action.is_empty():
		var action_data = _raise_action.duplicate(true)
		action_data["amount"] = int(_h_slider.value)
		action_pressed.emit(action_data)

func _style_action_button(btn: Button, border_color: Color) -> void:
	var bg_color := Color(0.008, 0.010, 0.024, 0.45)
	
	var style_normal := HomeTheme.make_button_style(bg_color, border_color * 0.4, 20)
	style_normal.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.15)
	style_normal.shadow_size = 5
	
	var style_hover := HomeTheme.make_button_style(bg_color + Color(0.01, 0.01, 0.02, 0.2), border_color * 1.0, 20)
	style_hover.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.50)
	style_hover.shadow_size = 10
	
	var style_disabled := HomeTheme.make_button_style(Color(0.008, 0.006, 0.015, 0.20), Color(border_color.r, border_color.g, border_color.b, 0.20), 20)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.55, 0.35))
	btn.add_theme_font_size_override("font_size", 14)
	
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	btn.mouse_entered.connect(func() -> void:
		if not btn.disabled:
			var tween := create_tween()
			tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		if not btn.disabled:
			var tween := create_tween()
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

func _style_adjust_button(btn: Button) -> void:
	var bg_color := Color(0.12, 0.09, 0.22, 0.6)
	var border_color := Color(0.28, 0.22, 0.45, 0.6)
	
	var style_normal := HomeTheme.make_button_style(bg_color, border_color, 18)
	var style_hover := HomeTheme.make_button_style(bg_color + Color(0.05, 0.05, 0.05, 0.1), border_color * 1.5, 18)
	var style_disabled := HomeTheme.make_button_style(Color(0.05, 0.05, 0.07, 0.2), Color(0.2, 0.2, 0.25, 0.2), 18)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4, 0.3))
	btn.add_theme_font_size_override("font_size", 16)

func _style_quick_button(btn: Button) -> void:
	var bg_color := Color(0.16, 0.08, 0.24, 0.5)
	var border_color := Color(1.0, 0.0, 0.5, 0.4)
	
	var style_normal := HomeTheme.make_button_style(bg_color, border_color, 18)
	var style_hover := HomeTheme.make_button_style(bg_color + Color(0.05, 0.05, 0.05, 0.1), border_color * 1.5, 18)
	var style_disabled := HomeTheme.make_button_style(Color(0.05, 0.05, 0.07, 0.2), Color(0.2, 0.2, 0.25, 0.2), 18)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4, 0.3))
	btn.add_theme_font_size_override("font_size", 11)

func _style_h_slider(slider: HSlider) -> void:
	# Track
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.25, 0.2, 0.35, 0.6) # Clearly visible dark purple
	track_style.set_corner_radius_all(3)
	track_style.content_margin_top = 3
	track_style.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", track_style)
	
	# Active Grabber Area
	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color(0.0, 0.75, 1.0) # Bright neon cyan
	active_style.set_corner_radius_all(3)
	active_style.content_margin_top = 3
	active_style.content_margin_bottom = 3
	slider.add_theme_stylebox_override("grabber_area", active_style)
	slider.add_theme_stylebox_override("grabber_area_highlight", active_style)
	
	# Grabber Texture Circle
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(16):
		for x in range(16):
			var dist = Vector2(x - 7.5, y - 7.5).length()
			if dist <= 7.5:
				image.set_pixel(x, y, Color(1.0, 0.0, 0.5)) # Neon Magenta solid circle
			elif dist <= 8.0:
				image.set_pixel(x, y, Color(1.0, 0.5, 0.8, 0.5))
	
	var texture := ImageTexture.create_from_image(image)
	slider.add_theme_icon_override("grabber", texture)
	slider.add_theme_icon_override("grabber_highlight", texture)

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
