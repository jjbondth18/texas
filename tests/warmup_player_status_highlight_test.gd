extends RefCounted

func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	assert(source.find("var is_turn := bool(player_data.get(\"is_turn\", false))") != -1)
	assert(source.find("action_label.text = \"YOUR TURN\" if is_local else \"THINKING...\"") != -1)
	assert(source.find("var target_x: float = _active_offset() if is_turn else 0.0") != -1)
	assert(source.find("_tween.tween_property(self, \"position:x\", target_x, duration)") != -1)
	assert(source.find("dots_hbox.visible = true") != -1)
	assert(source.find("dots_hbox.modulate.a = 1.0 if is_turn else 0.0") != -1)
	assert(source.find("action_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS") != -1)
