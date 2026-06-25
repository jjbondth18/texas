extends Node
class_name MotionManager

static func tween_hover(control: Control, hovered: bool, duration: float = 0.15) -> Tween:
	if not control.has_meta("motion_origin"):
		control.set_meta("motion_origin", control.position)
	var origin := control.get_meta("motion_origin") as Vector2
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE * (1.025 if hovered else 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "position", origin + Vector2(0, -6 if hovered else 0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tween

static func pulse_canvas_item(item: CanvasItem, duration: float = 4.0, low_alpha: float = 0.72, high_alpha: float = 1.0) -> Tween:
	var tween := item.create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property(item, "modulate:a", high_alpha, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if item is Control:
		tween.tween_property(item, "scale", Vector2.ONE * 1.012, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(item, "modulate:a", low_alpha, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if item is Control:
		tween.parallel().tween_property(item, "scale", Vector2.ONE, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween

static func drift(control: Control, offset: Vector2, duration: float) -> Tween:
	var origin := control.position
	var tween := control.create_tween()
	tween.set_loops()
	tween.tween_property(control, "position", origin + offset, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "position", origin - offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "position", origin, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween
