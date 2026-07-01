extends SceneTree


func _init() -> void:
	var docs := FileAccess.get_file_as_string("res://docs/ai_practice_wallet_policy.md")
	var db_smoke := FileAccess.get_file_as_string("res://server/src/db_smoke_test.ts")
	assert(docs.find("must not change the authoritative account wallet") != -1)
	assert(db_smoke.find("start_ai_warmup should not change account wallet chips") != -1)
	assert(db_smoke.find("public cash out after local warm-up should refund official table stack only") != -1)
	print("Local warm-up exit wallet policy test passed.")
	quit()
