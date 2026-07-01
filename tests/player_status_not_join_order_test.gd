extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")
	var docs := FileAccess.get_file_as_string("res://docs/poker_table_ui_contract.md")
	_assert(source.find("TABLE_SEAT_JOIN_ORDER_9P") == -1, "PlayerStatus implementation must not depend on join-order constant.")
	_assert(docs.find("left status list renders 2, 5, 6, 8") != -1, "UI contract must document status order 2,5,6,8 for occupied 5,8,2,6.")
	_assert(source.find("if next_order == _seat_order:\n\t\treturn") != -1, "Turn changes must not reorder existing rows.")
	_assert(source.find("_tween.tween_property(self, \"position:x\", target_x, duration)") != -1, "Active state should remain a horizontal offset, not row movement.")
	print("Player status not join order test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
