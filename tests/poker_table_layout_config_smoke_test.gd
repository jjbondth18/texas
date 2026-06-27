extends SceneTree

const Config := preload("res://scripts/dev/poker_table_layout_config.gd")
const RuntimeLayoutEditor := preload("res://scripts/dev/poker_table_runtime_layout_editor.gd")

func _init() -> void:
	var rect := Rect2(Vector2(1600, 280), Vector2(180, 90))
	var data := Config.rect_to_dict(rect)
	var restored := Config.dict_to_rect(data)
	_assert(restored.position == rect.position, "rect position conversion failed")
	_assert(restored.size == rect.size, "rect size conversion failed")

	var items := {"seat_1": data}
	var text := Config.serialize(items)
	var parsed := Config.deserialize(text)
	_assert(Dictionary(parsed.get("items", {})).has("seat_1"), "serialized item missing")

	var fallback := Config.deserialize("not json")
	_assert(Dictionary(fallback).has("items"), "missing config fallback failed")

	var missing := Config.load_user_config()
	_assert(Dictionary(missing).has("items"), "missing user config should not crash")

	var editor := RuntimeLayoutEditor.new()
	editor.register_targets({"unknown_target": null})
	_assert(editor.targets.is_empty(), "unknown target should be ignored")
	editor.free()

	print("Poker table layout config smoke test passed.")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
