extends Control
class_name ActionBar

signal action_pressed(action: Dictionary)

var actions: Array[Dictionary] = []
var _buttons_root: HBoxContainer

func _ready() -> void:
	_buttons_root = HBoxContainer.new()
	_buttons_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_buttons_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons_root.add_theme_constant_override("separation", 14)
	add_child(_buttons_root)

func set_actions(new_actions: Array) -> void:
	actions = []
	for action in new_actions:
		actions.append(Dictionary(action).duplicate(true))
	if _buttons_root == null:
		return
	for child in _buttons_root.get_children():
		child.queue_free()
	for action in actions:
		var button := Button.new()
		var action_id := String(action.get("id", ""))
		button.text = String(action.get("label", action_id)).to_upper()
		button.disabled = not bool(action.get("enabled", true))
		button.custom_minimum_size = Vector2(140, 48)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.focus_mode = Control.FOCUS_NONE
		
		var bg_color := Color(0.008, 0.010, 0.024, 0.45)
		var border_color := Color(1.0, 0.0, 0.5, 0.30) # Default 0.3 pink neon border
		var shadow_color_normal := Color(1.0, 0.0, 0.5, 0.15)
		var shadow_size_normal := 5
		var shadow_color_hover := Color(1.0, 0.0, 0.5, 0.50)
		var shadow_size_hover := 12
		
		if not button.disabled:
			if action_id == "fold":
				border_color = Color(1.0, 0.0, 0.5, 0.30)
				shadow_color_normal = Color(1.0, 0.0, 0.5, 0.10)
				shadow_size_normal = 4
				shadow_color_hover = Color(1.0, 0.0, 0.5, 0.40)
				shadow_size_hover = 10
			elif action_id in ["check", "call", "all_in"]:
				border_color = Color(1.0, 0.0, 0.5, 0.85)
				shadow_color_normal = Color(1.0, 0.0, 0.5, 0.25)
				shadow_size_normal = 6
				shadow_color_hover = Color(1.0, 0.0, 0.5, 0.65)
				shadow_size_hover = 14
			elif action_id in ["bet", "raise"]:
				border_color = Color(0.0, 0.75, 1.0, 0.80)
				shadow_color_normal = Color(0.0, 0.75, 1.0, 0.20)
				shadow_size_normal = 6
				shadow_color_hover = Color(0.0, 0.75, 1.0, 0.60)
				shadow_size_hover = 14
				
		var style_normal := HomeTheme.make_button_style(bg_color, border_color, 24)
		if not button.disabled:
			style_normal.shadow_color = shadow_color_normal
			style_normal.shadow_size = shadow_size_normal
			
		var border_hover := border_color
		if not button.disabled:
			border_hover.a = 1.0
		var style_hover := HomeTheme.make_button_style(bg_color + Color(0.01, 0.01, 0.02, 0.2), border_hover, 24)
		if not button.disabled:
			style_hover.shadow_color = shadow_color_hover
			style_hover.shadow_size = shadow_size_hover
		
		var style_disabled := HomeTheme.make_button_style(Color(0.008, 0.006, 0.015, 0.30), Color(1.0, 0.0, 0.5, 0.30), 24)
		
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_hover)
		button.add_theme_stylebox_override("disabled", style_disabled)
		
		button.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.55, 0.35))
		button.add_theme_font_size_override("font_size", 14)
		
		button.pivot_offset = Vector2(70, 24)
		
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				var tween := create_tween()
				tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		)
		button.mouse_exited.connect(func() -> void:
			if not button.disabled:
				var tween := create_tween()
				tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		)
		
		button.pressed.connect(func() -> void:
			action_pressed.emit(action.duplicate(true))
		)
		_buttons_root.add_child(button)
