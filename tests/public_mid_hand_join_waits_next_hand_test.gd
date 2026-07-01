extends SceneTree

func _init() -> void:
	var table_state_source := FileAccess.get_file_as_string("res://server/src/table_state.ts")
	var protocol_source := FileAccess.get_file_as_string("res://server/src/protocol.ts")
	var status_panel_source := FileAccess.get_file_as_string("res://scripts/components/table_status_panel.gd")

	assert(protocol_source.find("\"waiting_next_hand\"") != -1)
	assert(table_state_source.find("const joinsNextHand = ![\"waiting\", \"hand_over\"].includes(this.phase)") != -1)
	assert(table_state_source.find("status: (joinsNextHand ? \"waiting_next_hand\" : \"sitting\")") != -1)
	assert(table_state_source.find("joins and waits for the next hand") != -1)
	assert(status_panel_source.find("WAITING NEXT HAND") != -1)
	quit()
