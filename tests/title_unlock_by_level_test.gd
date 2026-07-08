extends SceneTree

const PlayerProfileScript := preload("res://scripts/data/player_profile.gd")

func _init() -> void:
	_require(PlayerProfileScript.title_for_level(1) == "Rookie", "Level 1 title should be Rookie.")
	_require(PlayerProfileScript.title_for_level(3) == "Casual Player", "Level 3 title should be Casual Player.")
	_require(PlayerProfileScript.title_for_level(5) == "Table Regular", "Level 5 title should be Table Regular.")
	_require(PlayerProfileScript.title_for_level(10) == "Sharp Caller", "Level 10 title should be Sharp Caller.")
	_require(PlayerProfileScript.title_for_level(15) == "River Hunter", "Level 15 title should be River Hunter.")
	_require(PlayerProfileScript.title_for_level(20) == "Card Shark", "Level 20 title should be Card Shark.")
	_require(PlayerProfileScript.title_for_level(30) == "High Roller", "Level 30 title should be High Roller.")
	_require(PlayerProfileScript.title_for_level(50) == "Poker Legend", "Level 50 title should be Poker Legend.")
	print("Title unlock by level test passed.")
	quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
