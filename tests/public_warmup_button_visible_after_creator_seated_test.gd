extends SceneTree

func _init() -> void:
	var table_source: String = FileAccess.get_file_as_string("res://scripts/screens/poker_table_screen.gd")
	var waiting_button_body: String = _function_body(table_source, "func _on_public_waiting_button_pressed")
	var refresh_body: String = _function_body(table_source, "func _refresh_public_waiting_controls")

	_require(refresh_body.find("_public_waiting_button.text = \"START AI WARM-UP\" if should_show else ready_text") != -1, "Waiting panel button should stay START AI WARM-UP when creator is alone.")
	_require(waiting_button_body.find("_should_show_public_warmup_entry()") != -1, "Waiting panel must prefer warm-up over toggling ready.")
	_require(waiting_button_body.find("_start_public_ai_warmup_practice()") != -1, "Warm-up button must still enter local practice.")
	print("Public warm-up button visible after creator seated test passed.")
	quit(0)


func _function_body(source: String, signature: String) -> String:
	var start: int = source.find(signature)
	if start < 0:
		return ""
	var next_func: int = source.find("\nfunc ", start + signature.length())
	if next_func < 0:
		return source.substr(start)
	return source.substr(start, next_func - start)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
