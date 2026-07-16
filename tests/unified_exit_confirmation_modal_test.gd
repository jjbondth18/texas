extends SceneTree


func _init() -> void:
	var modal_source := FileAccess.get_file_as_string("res://scripts/components/confirmation_modal.gd")
	_require(modal_source.find("class_name ConfirmationModal") != -1, "Shared confirmation modal must expose one reusable component.")
	_require(modal_source.find("ConfirmationDialog") == -1, "Shared exit modal must not use the native gray dialog.")
	_require(modal_source.find("PRESET_FULL_RECT") != -1 and modal_source.find("CenterContainer.new()") != -1, "Modal must use a full-screen mask and centered container.")
	_require(modal_source.find("Vector2(520, 320)") != -1, "Modal must remain compact.")
	_require(modal_source.find("KEY_ESCAPE") != -1 and modal_source.find("KEY_ENTER") != -1, "Modal must support Escape and Enter.")
	_require(modal_source.find("_confirm_button.disabled = value") != -1, "Pending requests must disable duplicate confirmation.")
	_require(modal_source.find("func set_error") != -1, "Settlement failures must render inline.")
	print("Unified exit confirmation modal test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
