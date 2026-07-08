extends SceneTree

func _init() -> void:
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	var events_handler := "set_state(LobbyState.EVENTS)"
	assert(home_source.find("\"events\":\n\t\t\t" + events_handler) != -1 or home_source.find(events_handler) != -1)
	assert(home_source.find("This event mode is planned for a future update.") != -1)
	assert(home_source.find("No event tables are created and no chips or gems are charged.") != -1)
	print("Events mode does not create table test passed.")
	quit()
