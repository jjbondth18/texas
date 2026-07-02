extends SceneTree


func _init() -> void:
	var client_source: String = FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	_require(client_source.find("[ClientTableList] received count=") != -1, "Client must log received table list count.")
	_require(client_source.find("[ClientTableList] room %s:") != -1, "Client must log table list room diagnostics.")
	_require(client_source.find("[ClientQuick] selected buy_in=") != -1, "Client must log Quick selected config.")
	_require(client_source.find("[ClientQuick] candidate rooms count=") != -1, "Client must log Quick candidate summary.")
	print("Client table list diagnostics test passed.")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
