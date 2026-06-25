extends Control
class_name ActionBar

signal action_pressed(action: Dictionary)

var actions: Array[Dictionary] = []
var _buttons_root: HBoxContainer

func _ready() -> void:
	_buttons_root = HBoxContainer.new()
	_buttons_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_buttons_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons_root.add_theme_constant_override("separation", 10)
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
		button.text = String(action.get("label", action.get("id", ""))).to_upper()
		button.disabled = not bool(action.get("enabled", true))
		button.custom_minimum_size = Vector2(118, 46)
		button.pressed.connect(func() -> void:
			action_pressed.emit(action.duplicate(true))
		)
		_buttons_root.add_child(button)
