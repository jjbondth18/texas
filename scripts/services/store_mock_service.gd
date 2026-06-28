extends RefCounted
class_name StoreMockService

const ProfileServiceScript := preload("res://scripts/services/profile_service.gd")

const CHIP_PACKS := [10000, 50000, 100000]
const GEM_PACKS := [100, 500, 1200]

func mock_purchase_chips(amount: int) -> Dictionary:
	if not CHIP_PACKS.has(amount):
		push_warning("[StoreMockService] Unknown chip pack: %d" % amount)
		return ProfileServiceScript.new().get_current_profile()
	return ProfileServiceScript.new().mock_purchase_chips(amount)

func mock_purchase_gems(amount: int) -> Dictionary:
	if not GEM_PACKS.has(amount):
		push_warning("[StoreMockService] Unknown gem pack: %d" % amount)
		return ProfileServiceScript.new().get_current_profile()
	return ProfileServiceScript.new().mock_purchase_gems(amount)
