extends SceneTree


func _init() -> void:
	var server_source := FileAccess.get_file_as_string("res://server/src/room_manager.ts")
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(server_source.find("if (!wallet || wallet.chips < room.buyIn) throw new Error(\"insufficient_chips\")") != -1)
	assert(server_source.find("this.wallets.deductChips(client.id, room.buyIn") > server_source.find("insufficient_chips"))
	assert(db_smoke.find("failed sit_down should return sit_down_result ok=false insufficient_chips") != -1)
	print("Sit down failed does not debit wallet test passed.")
	quit()
