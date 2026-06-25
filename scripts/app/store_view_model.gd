extends RefCounted
class_name StoreViewModel

var tabs: Array[Dictionary] = [
	{"id": "chips", "label": "Chips", "route": "store_chips"},
	{"id": "replay_pro", "label": "Replay Pro", "route": "store_replay_pro"},
	{"id": "cosmetics", "label": "Cosmetics", "route": "store_cosmetics"},
	{"id": "membership", "label": "Membership", "route": "store_membership"},
]

func to_dict() -> Dictionary:
	return {"tabs": tabs.duplicate(true)}
