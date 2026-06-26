extends Control
class_name ActionBar

signal action_pressed(action: Dictionary)

var actions: Array[Dictionary] = []
var pot_amount: int = 0

var _fold_action: Dictionary
var _check_call_action: Dictionary
var _raise_action: Dictionary

var _fold_button: Button
var _check_call_button: Button
var _raise_confirm_button: Button
var _minus_button: Button
var _plus_button: Button
var _h_slider: HSlider
var _pot_25_button: Button
var _max_button: Button

func _ready() -> void:
	# Build the action bar layout
	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 24)
	add_child(main_hbox)
	
	# Left Compartment: Basic Actions (FOLD, CHECK/CALL)
	var basic_hbox := HBoxContainer.new()
	basic_hbox.add_theme_constant_override("separation", 14)
	basic_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(basic_hbox)
	
	_fold_button = Button.new()
	_fold_button.text = "FOLD"
	_fold_button.custom_minimum_size = Vector2(130, 64)
	_fold_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_fold_button.focus_mode = Control.FOCUS_NONE
	basic_hbox.add_child(_fold_button)
	
	_check_call_button = Button.new()
	_check_call_button.text = "CHECK"
	_check_call_button.custom_minimum_size = Vector2(150, 64)
	_check_call_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_check_call_button.focus_mode = Control.FOCUS_NONE
	basic_hbox.add_child(_check_call_button)
	
	# Style basic buttons with premium neon
	_style_action_button(_fold_button, Color(0.45, 0.45, 0.52)) # Muted Gray-Violet
	_style_action_button(_check_call_button, Color(1.0, 0.0, 0.5)) # Neon Magenta
	
	# Middle Compartment: Raise Slider Area
	var slider_vbox := VBoxContainer.new()
	slider_vbox.add_theme_constant_override("separation", 10)
	slider_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(slider_vbox)
	
	_raise_confirm_button = Button.new()
	_raise_confirm_button.text = "RAISE"
	_raise_confirm_button.custom_minimum_size = Vector2(240, 52)
	_raise_confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_raise_confirm_button.focus_mode = Control.FOCUS_NONE
	_style_action_button(_raise_confirm_button, Color(0.0, 0.75, 1.0)) # Bright Neon Cyan
	slider_vbox.add_child(_raise_confirm_button)
	
	var slider_hbox := HBoxContainer.new()
	slider_hbox.add_theme_constant_override("separation", 10)
	slider_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_vbox.add_child(slider_hbox)
	
	_minus_button = Button.new()
	_minus_button.text = "-"
	_minus_button.custom_minimum_size = Vector2(36, 36)
	_minus_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_minus_button.focus_mode = Control.FOCUS_NONE
	_style_adjust_button(_minus_button)
	slider_hbox.add_child(_minus_button)
	
	_h_slider = HSlider.new()
	_h_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_h_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_h_slider.focus_mode = Control.FOCUS_NONE
	_style_h_slider(_h_slider)
	slider_hbox.add_child(_h_slider)
	
	_plus_button = Button.new()
	_plus_button.text = "+"
	_plus_button.custom_minimum_size = Vector2(36, 36)
	_plus_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_plus_button.focus_mode = Control.FOCUS_NONE
	_style_adjust_button(_plus_button)
	slider_hbox.add_child(_plus_button)
	
	# Right Compartment: Quick Raise Multipliers
	var quick_vbox := VBoxContainer.new()
	quick_vbox.add_theme_constant_override("separation", 8)
	quick_vbox.custom_minimum_size = Vector2(110, 0)
	quick_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(quick_vbox)
	
	_pot_25_button = Button.new()
	_pot_25_button.text = "2.5x POT"
	_pot_25_button.custom_minimum_size = Vector2(110, 36)
	_pot_25_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pot_25_button.focus_mode = Control.FOCUS_NONE
	_style_quick_button(_pot_25_button)
	quick_vbox.add_child(_pot_25_button)
	
	_max_button = Button.new()
	_max_button.text = "MAX"
	_max_button.custom_minimum_size = Vector2(110, 36)
	_max_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_max_button.focus_mode = Control.FOCUS_NONE
	_style_quick_button(_max_button)
	quick_vbox.add_child(_max_button)
	
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
		_raise_confirm_button.text = "%s %d" % [action_id, min_amt]
	else:
		_raise_confirm_button.disabled = true
		_minus_button.disabled = true
		_plus_button.disabled = true
		_h_slider.editable = false
		_pot_25_button.disabled = true
		_max_button.disabled = true
		_raise_confirm_button.text = "RAISE"

func _on_slider_value_changed(val: float) -> void:
	var rounded_val = int(val)
	if not _raise_action.is_empty():
		var action_id = String(_raise_action.get("id", "raise")).to_upper()
		_raise_confirm_button.text = "%s %d" % [action_id, rounded_val]

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
	track_style.bg_color = Color(0.08, 0.06, 0.12, 0.9)
	track_style.set_corner_radius_all(4)
	track_style.content_margin_top = 8
	track_style.content_margin_bottom = 8
	slider.add_theme_stylebox_override("slider", track_style)
	
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
