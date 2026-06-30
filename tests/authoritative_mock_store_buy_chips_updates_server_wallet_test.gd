extends RefCounted

func run() -> void:
	var protocol_source := FileAccess.get_file_as_string("res://scripts/network/poker_protocol.gd")
	assert(protocol_source.find("const MOCK_PURCHASE := \"mock_purchase\"") != -1)
	assert(protocol_source.find("static func mock_purchase(currency: String, amount: int") != -1)
	var client_source := FileAccess.get_file_as_string("res://scripts/network/poker_ws_client.gd")
	assert(client_source.find("signal mock_purchase_result_received") != -1)
	assert(client_source.find("func mock_purchase(currency: String, amount: int)") != -1)
	var home_source := FileAccess.get_file_as_string("res://scripts/screens/home_lobby_screen.gd")
	assert(home_source.find("_profile_ws_client.mock_purchase(currency, amount)") != -1)
	assert(home_source.find("+%s %s added to server wallet.") != -1)
